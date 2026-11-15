import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

typedef StoredDocument = ({String id, Map<String, Object?> data});

abstract interface class ProgressDocuments {
  Future<List<StoredDocument>> read(String userId);

  Future<void> write(String userId, List<StoredDocument> documents);

  Future<void> delete(String userId, List<String> ids);
}

@LazySingleton(as: ProgressDocuments)
final class FirestoreProgressDocuments implements ProgressDocuments {
  const new(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _progress(String userId) =>
      _firestore.collection('users').doc(userId).collection('progress');

  @override
  Future<List<StoredDocument>> read(String userId) async {
    final snapshot = await _progress(userId).get();
    return [
      for (final document in snapshot.docs)
        (id: document.id, data: document.data()),
    ];
  }

  @override
  Future<void> write(String userId, List<StoredDocument> documents) async {
    final collection = _progress(userId);
    final batch = _firestore.batch();
    for (final document in documents) {
      batch.set(collection.doc(document.id), document.data);
    }
    await batch.commit();
  }

  @override
  Future<void> delete(String userId, List<String> ids) async {
    final collection = _progress(userId);
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(collection.doc(id));
    }
    await batch.commit();
  }
}
