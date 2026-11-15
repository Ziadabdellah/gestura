import 'dart:async';

import 'package:clock/clock.dart';
import 'package:gestura/core/database/app_database.dart' hide DailyActivity;
import 'package:gestura/core/database/database_failure.dart';
import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ActivityRepository)
final class DriftActivityRepository implements ActivityRepository {
  new(this._database);

  final AppDatabase _database;

  @override
  Stream<Result<List<DailyActivity>>> watchAll() => _database
      .select(_database.dailyActivity)
      .watch()
      .map<Result<List<DailyActivity>>>(
        (rows) => Ok([
          for (final row in rows)
            DailyActivity(
              day: dayOf(row.day),
              lessons: row.lessons,
              reviews: row.reviews,
              seconds: row.seconds,
            ),
        ]),
      )
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stackTrace, sink) =>
              sink.add(Err(databaseFailure(error))),
        ),
      );

  @override
  Future<Result<List<DailyActivity>>> readAll() => Result.guard(
    () async => [
      for (final row in await _database.select(_database.dailyActivity).get())
        DailyActivity(
          day: dayOf(row.day),
          lessons: row.lessons,
          reviews: row.reviews,
          seconds: row.seconds,
        ),
    ],
    onError: (error, stackTrace) => databaseFailure(error),
  );

  @override
  Future<Result<void>> merge(Iterable<DailyActivity> incoming) =>
      Result.guard(() async {
        for (final day in incoming) {
          await _database.customStatement(
            'INSERT INTO daily_activity (day, lessons, reviews, seconds) '
            'VALUES (?, ?, ?, ?) ON CONFLICT (day) DO UPDATE SET '
            'lessons = max(lessons, excluded.lessons), '
            'reviews = max(reviews, excluded.reviews), '
            'seconds = max(seconds, excluded.seconds) '
            'WHERE lessons < excluded.lessons OR reviews < excluded.reviews '
            'OR seconds < excluded.seconds',
            [dayKey(day.day), day.lessons, day.reviews, day.seconds],
          );
        }
        _database.markTablesUpdated({_database.dailyActivity});
      }, onError: (error, stackTrace) => databaseFailure(error));

  @override
  Future<Result<void>> recordLesson(Duration time) =>
      _add(lessons: 1, seconds: time.inSeconds);

  @override
  Future<Result<void>> recordReview(Duration time) =>
      _add(reviews: 1, seconds: time.inSeconds);

  Future<Result<void>> _add({
    required int seconds,
    int lessons = 0,
    int reviews = 0,
  }) => Result.guard(() async {
    final day = dayKey(clock.now());
    await _database.customStatement(
      'INSERT INTO daily_activity (day, lessons, reviews, seconds) '
      'VALUES (?, ?, ?, ?) ON CONFLICT (day) DO UPDATE SET '
      'lessons = lessons + excluded.lessons, '
      'reviews = reviews + excluded.reviews, '
      'seconds = seconds + excluded.seconds',
      [day, lessons, reviews, seconds],
    );
    _database.markTablesUpdated({_database.dailyActivity});
  }, onError: (error, stackTrace) => databaseFailure(error));

  @override
  Future<Result<void>> clear() => Result.guard(() async {
    await _database.delete(_database.dailyActivity).go();
  }, onError: (error, stackTrace) => databaseFailure(error));
}
