import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/progress/domain/remote_progress_store.dart';
import 'package:gestura_core/gestura_core.dart';

class FakeRemoteProgressStore implements RemoteProgressStore {
  final Map<String, Map<LessonId, LessonProgress>> users = {};
  final List<String> calls = [];
  Failure? fetchFailure;
  Failure? saveFailure;
  Failure? deleteFailure;

  @override
  Future<Result<List<LessonProgress>>> fetchAll(String userId) async {
    calls.add('fetch:$userId');
    if (fetchFailure case final Failure failure) return Err(failure);
    return Ok([...?users[userId]?.values]);
  }

  @override
  Future<Result<void>> saveAll(
    String userId,
    Iterable<LessonProgress> progress,
  ) async {
    calls.add('save:$userId:${progress.length}');
    if (saveFailure case final Failure failure) return Err(failure);
    final stored = users.putIfAbsent(userId, () => {});
    for (final item in progress) {
      stored[item.lessonId] = item;
    }
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteAll(String userId) async {
    calls.add('delete:$userId');
    if (deleteFailure case final Failure failure) return Err(failure);
    users.remove(userId);
    return const Ok(null);
  }
}
