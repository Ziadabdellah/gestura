import 'package:gestura/core/cloud/user_documents.dart';
import 'package:gestura/core/firebase/firestore_failure.dart';
import 'package:gestura_core/gestura_core.dart';

abstract interface class CloudSet<T> {
  Future<Result<List<T>>> fetchAll(String userId);

  Future<Result<void>> saveAll(String userId, Iterable<T> items);

  Future<Result<void>> deleteAll(String userId);
}

abstract interface class DocumentCodec<T> {
  String idOf(T item);

  StoredDocument encode(T item);

  T? decode(StoredDocument document);
}

final class FirestoreCloudSet<T> implements CloudSet<T> {
  const new(this._documents, this.collection, this._codec);

  static const int batchLimit = 400;

  final UserDocuments _documents;
  final String collection;
  final DocumentCodec<T> _codec;

  @override
  Future<Result<List<T>>> fetchAll(String userId) => Result.guard(
    () async => [
      for (final document in await _documents.read(userId, collection))
        ?_codec.decode(document),
    ],
    onError: (error, _) => firestoreFailure(error),
  );

  @override
  Future<Result<void>> saveAll(String userId, Iterable<T> items) =>
      Result.guard(() async {
        final documents = items.map(_codec.encode).toList();
        for (var start = 0; start < documents.length; start += batchLimit) {
          await _documents.write(
            userId,
            collection,
            documents.skip(start).take(batchLimit).toList(),
          );
        }
      }, onError: (error, _) => firestoreFailure(error));

  @override
  Future<Result<void>> deleteAll(String userId) => Result.guard(() async {
    final ids = [
      for (final document in await _documents.read(userId, collection))
        document.id,
    ];
    for (var start = 0; start < ids.length; start += batchLimit) {
      await _documents.delete(
        userId,
        collection,
        ids.skip(start).take(batchLimit).toList(),
      );
    }
  }, onError: (error, _) => firestoreFailure(error));
}

final class DeviceOnlySet<T> implements CloudSet<T> {
  const new();

  @override
  Future<Result<List<T>>> fetchAll(String userId) async => Ok(List<T>.empty());

  @override
  Future<Result<void>> saveAll(String userId, Iterable<T> items) async =>
      const Ok(null);

  @override
  Future<Result<void>> deleteAll(String userId) async => const Ok(null);
}
