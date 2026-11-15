import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura_core/gestura_core.dart';

abstract interface class ActivityRepository {
  Stream<Result<List<DailyActivity>>> watchAll();

  Future<Result<void>> recordLesson(Duration time);

  Future<Result<void>> recordReview(Duration time);

  Future<Result<List<DailyActivity>>> readAll();

  Future<Result<void>> merge(Iterable<DailyActivity> incoming);

  Future<Result<void>> clear();
}
