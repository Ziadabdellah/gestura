import 'package:gestura/core/cloud/cloud_set.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/learner/learner_cloud.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura_core/gestura_core.dart';

class FakeCloudSet<T> implements CloudSet<T> {
  new(this.name, this.idOf, this.calls);

  final String name;
  final String Function(T item) idOf;
  final List<String> calls;
  final Map<String, Map<String, T>> users = {};
  Failure? fetchFailure;
  Failure? saveFailure;
  Failure? deleteFailure;

  @override
  Future<Result<List<T>>> fetchAll(String userId) async {
    calls.add('$name.fetch:$userId');
    if (fetchFailure case final Failure failure) return Err(failure);
    return Ok([...?users[userId]?.values]);
  }

  @override
  Future<Result<void>> saveAll(String userId, Iterable<T> items) async {
    calls.add('$name.save:$userId:${items.length}');
    if (saveFailure case final Failure failure) return Err(failure);
    final stored = users.putIfAbsent(userId, () => {});
    for (final item in items) {
      stored[idOf(item)] = item;
    }
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteAll(String userId) async {
    calls.add('$name.delete:$userId');
    if (deleteFailure case final Failure failure) return Err(failure);
    users.remove(userId);
    return const Ok(null);
  }
}

class FakeLearnerCloud {
  final List<String> calls = [];
  late final FakeCloudSet<LessonProgress> progress = FakeCloudSet(
    'progress',
    (item) => item.lessonId.value,
    calls,
  );
  late final FakeCloudSet<ReviewCard> cards = FakeCloudSet(
    'cards',
    (item) => item.signId.value,
    calls,
  );
  late final FakeCloudSet<DailyActivity> activity = FakeCloudSet(
    'activity',
    (item) => dayKey(item.day),
    calls,
  );

  late final LearnerCloud cloud = LearnerCloud(
    progress: progress,
    cards: cards,
    activity: activity,
  );
}
