import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestura/core/firebase/firestore_failure.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/progress/data/progress_documents.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/progress/domain/remote_progress_store.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:injectable/injectable.dart';

LessonProgress? progressOf(StoredDocument document) => switch (document.data) {
  {
    'bestScore': final int score,
    'completedAt': final Timestamp completed,
    'updatedAt': final Timestamp updated,
  }
      when score >= LessonProgress.minScore &&
          score <= LessonProgress.maxScore =>
    LessonProgress(
      lessonId: LessonId(document.id),
      bestScore: score,
      completedAt: completed.toDate().toUtc(),
      updatedAt: updated.toDate().toUtc(),
    ),
  _ => null,
};

StoredDocument documentOf(LessonProgress progress) => (
  id: progress.lessonId.value,
  data: {
    'bestScore': progress.bestScore,
    'completedAt': Timestamp.fromDate(progress.completedAt),
    'updatedAt': FieldValue.serverTimestamp(),
  },
);

@LazySingleton(as: RemoteProgressStore)
final class FirestoreRemoteProgress implements RemoteProgressStore {
  const new(this._documents);

  static const int batchLimit = 400;

  final ProgressDocuments _documents;

  @override
  Future<Result<List<LessonProgress>>> fetchAll(String userId) => Result.guard(
    () async => [
      for (final document in await _documents.read(userId))
        ?progressOf(document),
    ],
    onError: (error, _) => firestoreFailure(error),
  );

  @override
  Future<Result<void>> saveAll(
    String userId,
    Iterable<LessonProgress> progress,
  ) => Result.guard(() async {
    final documents = progress.map(documentOf).toList();
    for (var start = 0; start < documents.length; start += batchLimit) {
      await _documents.write(
        userId,
        documents.skip(start).take(batchLimit).toList(),
      );
    }
  }, onError: (error, _) => firestoreFailure(error));

  @override
  Future<Result<void>> deleteAll(String userId) => Result.guard(() async {
    final ids = [
      for (final document in await _documents.read(userId)) document.id,
    ];
    for (var start = 0; start < ids.length; start += batchLimit) {
      await _documents.delete(
        userId,
        ids.skip(start).take(batchLimit).toList(),
      );
    }
  }, onError: (error, _) => firestoreFailure(error));
}
