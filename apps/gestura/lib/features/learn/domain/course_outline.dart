import 'package:equatable/equatable.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';

sealed class LessonStatus extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class LessonLocked extends LessonStatus {
  const new();
}

final class LessonAvailable extends LessonStatus {
  const new();
}

final class LessonCompleted extends LessonStatus {
  const new(this.bestScore);

  final int bestScore;

  @override
  List<Object?> get props => [bestScore];
}

final class LessonOutline extends Equatable {
  const new({required this.lesson, required this.number, required this.status});

  final Lesson lesson;
  final int number;
  final LessonStatus status;

  @override
  List<Object?> get props => [lesson, number, status];
}

final class UnitOutline extends Equatable {
  const new({required this.unit, required this.lessons});

  final CourseUnit unit;
  final List<LessonOutline> lessons;

  int get completed =>
      lessons.where((lesson) => lesson.status is LessonCompleted).length;

  bool get isComplete => lessons.isNotEmpty && completed == lessons.length;

  bool get hasNextLesson =>
      lessons.any((lesson) => lesson.status is LessonAvailable);

  @override
  List<Object?> get props => [unit.index, lessons];
}

final class CourseOutline extends Equatable {
  const new(this.units);

  factory of(Course course, ProgressByLesson progress) {
    var previousCompleted = true;

    LessonOutline outline(Lesson lesson, int number) {
      final status = switch ((progress[lesson.id], previousCompleted)) {
        (LessonProgress(:final bestScore), _) => LessonCompleted(bestScore),
        (null, true) => const LessonAvailable(),
        (null, false) => const LessonLocked(),
      };
      previousCompleted = status is LessonCompleted;
      return LessonOutline(lesson: lesson, number: number, status: status);
    }

    return CourseOutline([
      for (final unit in course.units)
        UnitOutline(
          unit: unit,
          lessons: [
            for (final (index, lesson) in course.lessonsIn(unit.index).indexed)
              outline(lesson, index + 1),
          ],
        ),
    ]);
  }

  final List<UnitOutline> units;

  LessonOutline? get nextLesson => [
    for (final unit in units)
      for (final lesson in unit.lessons)
        if (lesson.status is LessonAvailable) lesson,
  ].firstOrNull;

  int get completed => units.fold(0, (sum, unit) => sum + unit.completed);

  int get total => units.fold(0, (sum, unit) => sum + unit.lessons.length);

  @override
  List<Object?> get props => [units];
}
