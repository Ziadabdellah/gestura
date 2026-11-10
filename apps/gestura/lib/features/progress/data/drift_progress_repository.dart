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
}

extension on LessonProgressRow {
  LessonProgress toDomain() => LessonProgress(
    lessonId: LessonId(lessonId),
    bestScore: bestScore,
    completedAt: completedAt,
    updatedAt: updatedAt,
  );
}
