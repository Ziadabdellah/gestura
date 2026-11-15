import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

typedef StoredDocument = ({String id, Map<String, Object?> data});

abstract interface class UserDocuments {
  Future<List<StoredDocument>> read(String userId, String collection);

  Future<void> write(
    String userId,
    String collection,
    List<StoredDocument> documents,
  );

  Future<void> delete(String userId, String collection, List<String> ids);
}

@LazySingleton(as: UserDocuments)
final class FirestoreUserDocuments implements UserDocuments {
  const new(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _of(
    String userId,
    String collection,
  ) => _firestore.collection('users').doc(userId).collection(collection);

  @override
  Future<List<StoredDocument>> read(String userId, String collection) async {
    final snapshot = await _of(userId, collection).get();
    return [
      for (final document in snapshot.docs)
        (id: document.id, data: document.data()),
    ];
  }

  @override
  Future<void> write(
    String userId,
    String collection,
    List<StoredDocument> documents,
  ) async {
    final target = _of(userId, collection);
    final batch = _firestore.batch();
    for (final document in documents) {
      batch.set(target.doc(document.id), document.data);
    }
    await batch.commit();
  }

  @override
  Future<void> delete(
    String userId,
    String collection,
    List<String> ids,
  ) async {
    final target = _of(userId, collection);
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(target.doc(id));
    }
    await batch.commit();
  }
}
