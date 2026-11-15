import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:gestura/core/database/app_database.dart';
import 'package:gestura/core/database/database_failure.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ProgressRepository)
final class DriftProgressRepository implements ProgressRepository {
  new(this._database);

  final AppDatabase _database;

  @override
  Stream<Result<ProgressByLesson>> watchAll() => _database
      .select(_database.progress)
      .watch()
      .map<Result<ProgressByLesson>>(
        (rows) => Ok({
          for (final row in rows) LessonId(row.lessonId): row.toDomain(),
        }),
      )
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stackTrace, sink) =>
              sink.add(Err(databaseFailure(error))),
        ),
      );

  @override
  Future<Result<ProgressByLesson>> readAll() => Result.guard(
    () async => {
      for (final row in await _database.select(_database.progress).get())
        LessonId(row.lessonId): row.toDomain(),
    },
    onError: (error, stackTrace) => databaseFailure(error),
  );

  @override
  Future<Result<void>> recordCompletion(
    LessonId lesson, {
    required int score,
  }) => Result.guard(() async {
    RangeError.checkValueInInterval(
      score,
      LessonProgress.minScore,
      LessonProgress.maxScore,
      'score',
    );
    final now = clock.now().toUtc();
    await _database.transaction(() async {
      final existing = await (_database.select(
        _database.progress,
      )..where((row) => row.lessonId.equals(lesson.value))).getSingleOrNull();
      await _database
          .into(_database.progress)
          .insertOnConflictUpdate(
            ProgressCompanion.insert(
              lessonId: lesson.value,
              bestScore: math.max(score, existing?.bestScore ?? score),
              completedAt: existing?.completedAt ?? now,
              updatedAt: now,
            ),
          );
    });
  }, onError: (error, stackTrace) => databaseFailure(error));

  @override
  Future<Result<void>> merge(
    Iterable<LessonProgress> incoming,
  ) => Result.guard(() async {
    await _database.transaction(() async {
      for (final item in incoming) {
        final existing =
            await (_database.select(_database.progress)
                  ..where((row) => row.lessonId.equals(item.lessonId.value)))
                .getSingleOrNull();
        final bestScore = math.max(
          item.bestScore,
          existing?.bestScore ?? item.bestScore,
        );
        final completedAt = _earliest(item.completedAt, existing?.completedAt);
        final updatedAt = _latest(item.updatedAt, existing?.updatedAt);
        if (existing != null &&
            existing.bestScore == bestScore &&
            existing.completedAt == completedAt &&
            existing.updatedAt == updatedAt) {
          continue;
        }
        await _database
            .into(_database.progress)
            .insertOnConflictUpdate(
              ProgressCompanion.insert(
                lessonId: item.lessonId.value,
                bestScore: bestScore,
                completedAt: completedAt,
                updatedAt: updatedAt,
              ),
            );
      }
    });
  }, onError: (error, stackTrace) => databaseFailure(error));

  static DateTime _earliest(DateTime a, DateTime? b) =>
      b != null && b.isBefore(a) ? b : a;

  static DateTime _latest(DateTime a, DateTime? b) =>
      b != null && b.isAfter(a) ? b : a;

  @override
  Future<Result<void>> clear() => Result.guard(() async {
    await _database.delete(_database.progress).go();
  }, onError: (error, stackTrace) => databaseFailure(error));
}

extension on LessonProgressRow {
  LessonProgress toDomain() => LessonProgress(
    lessonId: LessonId(lessonId),
    bestScore: bestScore,
    completedAt: completedAt,
    updatedAt: updatedAt,
  );
}
