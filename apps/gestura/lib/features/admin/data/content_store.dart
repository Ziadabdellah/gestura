import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestura/features/admin/domain/content_doc.dart';
import 'package:gestura/features/admin/domain/content_kind.dart';
import 'package:injectable/injectable.dart';

abstract interface class ContentStore {
  Stream<List<ContentDoc>> watch(ContentKind kind);

  Future<bool> exists(ContentKind kind, String id);

  Future<ContentDoc?> read(ContentKind kind, String id);

  Future<void> save(ContentKind kind, String id, Map<String, Object?> data);

  Future<void> delete(ContentKind kind, String id);
}

@LazySingleton(as: ContentStore)
final class FirestoreContentStore implements ContentStore {
  const new(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, Object?>> _collection(ContentKind kind) =>
      _firestore.collection(kind.collection);

  @override
  Stream<List<ContentDoc>> watch(ContentKind kind) => _collection(kind)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs) ContentDoc(doc.id, doc.data()),
        ],
      );

  @override
  Future<bool> exists(ContentKind kind, String id) async =>
      (await _collection(kind).doc(id).get()).exists;

  @override
  Future<ContentDoc?> read(ContentKind kind, String id) async {
    final doc = await _collection(kind).doc(id).get();
    final data = doc.data();
    return data == null ? null : ContentDoc(doc.id, data);
  }

  @override
  Future<void> save(ContentKind kind, String id, Map<String, Object?> data) =>
      _collection(kind)
          .doc(id)
          .set({...data, 'updatedAt': FieldValue.serverTimestamp()});

  @override
  Future<void> delete(ContentKind kind, String id) =>
      _collection(kind).doc(id).delete();
}
