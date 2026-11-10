import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura_core/gestura_core.dart';

typedef ProgressByLesson = Map<LessonId, LessonProgress>;

abstract interface class ProgressRepository {
  Stream<Result<ProgressByLesson>> watchAll();

  Future<Result<void>> recordCompletion(LessonId lesson, {required int score});
}
