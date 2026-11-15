import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura_core/gestura_core.dart';

abstract interface class RemoteProgressStore {
  Future<Result<List<LessonProgress>>> fetchAll(String userId);

  Future<Result<void>> saveAll(
    String userId,
    Iterable<LessonProgress> progress,
  );

  Future<Result<void>> deleteAll(String userId);
}
