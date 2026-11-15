import 'dart:async';

import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura_core/gestura_core.dart';

class FakeActivityRepository implements ActivityRepository {
  new([Iterable<DailyActivity> initial = const []]) : days = [...initial];

  final List<DailyActivity> days;
  final List<String> calls = [];
  final StreamController<void> _changes = StreamController.broadcast();

  @override
  Stream<Result<List<DailyActivity>>> watchAll() => Stream.multi((controller) {
    controller.add(Ok(List.of(days)));
    final subscription = _changes.stream.listen(
      (_) => controller.add(Ok(List.of(days))),
    );
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<Result<List<DailyActivity>>> readAll() async => Ok(List.of(days));

  @override
  Future<Result<void>> merge(Iterable<DailyActivity> incoming) async {
    for (final day in incoming) {
      days
        ..removeWhere((known) => dayKey(known.day) == dayKey(day.day))
        ..add(day);
    }
    _changes.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> recordLesson(Duration time) async {
    calls.add('lesson:${time.inSeconds}');
    _changes.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> recordReview(Duration time) async {
    calls.add('review:${time.inSeconds}');
    _changes.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> clear() async {
    days.clear();
    _changes.add(null);
    return const Ok(null);
  }
}
