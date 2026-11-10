import 'dart:async';
import 'dart:math' as math;

import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura_core/gestura_core.dart';

final DateTime fakeNow = DateTime.utc(2026, 11, 10, 9);

LessonProgress completed(String lessonId, {int score = 90}) => LessonProgress(
  lessonId: LessonId(lessonId),
  bestScore: score,
  completedAt: fakeNow,
  updatedAt: fakeNow,
);

class FakeProgressRepository implements ProgressRepository {
  new([Iterable<LessonProgress> initial = const []])
    : stored = {for (final progress in initial) progress.lessonId: progress};

  final ProgressByLesson stored;
  Failure? watchFailure;
  Failure? saveFailure;
  final StreamController<void> _changes = StreamController.broadcast();

  Result<ProgressByLesson> _snapshot() => switch (watchFailure) {
    final Failure failure => Err(failure),
    null => Ok(Map.unmodifiable(stored)),
  };

  @override
  Stream<Result<ProgressByLesson>> watchAll() => Stream.multi((controller) {
    controller.add(_snapshot());
    final subscription = _changes.stream.listen(
      (_) => controller.add(_snapshot()),
    );
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<Result<void>> recordCompletion(
    LessonId lesson, {
    required int score,
  }) async {
    if (saveFailure case final Failure failure) return Err(failure);
    final existing = stored[lesson];
    stored[lesson] = LessonProgress(
      lessonId: lesson,
      bestScore: math.max(score, existing?.bestScore ?? score),
      completedAt: existing?.completedAt ?? fakeNow,
      updatedAt: fakeNow,
    );
    _changes.add(null);
    return const Ok(null);
  }
}
