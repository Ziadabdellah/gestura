import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/progress/domain/remote_progress_store.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: RemoteProgressStore, env: ['dev', 'staging'])
final class LocalOnlyProgress implements RemoteProgressStore {
  const new();

  @override
  Future<Result<List<LessonProgress>>> fetchAll(String userId) async =>
      const Ok([]);

  @override
  Future<Result<void>> saveAll(
    String userId,
    Iterable<LessonProgress> progress,
  ) async => const Ok(null);

  @override
  Future<Result<void>> deleteAll(String userId) async => const Ok(null);
}
