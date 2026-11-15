import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/database/app_database.dart' hide DailyActivity;
import 'package:gestura/features/activity/data/drift_activity_repository.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';

void main() {
  group('streakOf', () {
    final today = DateTime(2026, 11, 15, 20);
    DailyActivity active(int day) =>
        DailyActivity(day: DateTime(2026, 11, day), lessons: 1);

    test('counts the days in a row up to today', () {
      expect(streakOf([active(13), active(14), active(15)], today), 3);
    });

    test("keeps yesterday's streak alive until today ends", () {
      expect(streakOf([active(13), active(14)], today), 2);
    });

    test('breaks on a missed day and ignores empty days', () {
      expect(
        streakOf([
          active(12),
          active(14),
          DailyActivity(day: DateTime(2026, 11, 15)),
        ], today),
        1,
      );
      expect(streakOf(const [], today), 0);
    });
  });

  test('names days and reads them back', () {
    expect(dayKey(DateTime(2026, 3, 7, 23)), '2026-03-07');
    expect(dayOf('2026-03-07'), DateTime(2026, 3, 7));
  });

  test('a day knows its minutes and compares by value', () {
    final day = DailyActivity(day: DateTime(2026), reviews: 1, seconds: 125);
    expect(day.minutes, 2);
    expect(day.isActive, isTrue);
    expect(day, DailyActivity(day: DateTime(2026), reviews: 1, seconds: 125));
    expect(
      day.hashCode,
      DailyActivity(day: DateTime(2026), reviews: 1, seconds: 125).hashCode,
    );
  });

  group('DriftActivityRepository', () {
    late AppDatabase database;
    late DriftActivityRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftActivityRepository(database);
    });

    tearDown(() => database.close());

    test('adds lessons and reviews up per local day', () async {
      final events = repository.watchAll().take(3).toList();
      await pumpEventQueue();
      await withClock(Clock.fixed(DateTime(2026, 11, 15, 9)), () async {
        await repository.recordLesson(const Duration(minutes: 3));
        await repository.recordReview(const Duration(seconds: 30));
      });

      expect((await events).last.valueOrNull, [
        DailyActivity(
          day: DateTime(2026, 11, 15),
          lessons: 1,
          reviews: 1,
          seconds: 210,
        ),
      ]);
      await repository.clear();
    });

    test('merges another device by keeping the larger counts', () async {
      final day = DateTime(2026, 11, 14);
      await repository.merge([
        DailyActivity(day: day, lessons: 2, reviews: 1, seconds: 100),
      ]);
      await repository.merge([
        DailyActivity(day: day, lessons: 1, reviews: 4, seconds: 50),
        DailyActivity(day: day, lessons: 1, reviews: 1, seconds: 10),
      ]);

      expect((await repository.readAll()).valueOrNull, [
        DailyActivity(day: day, lessons: 2, reviews: 4, seconds: 100),
      ]);
    });

    test('reports a broken table instead of throwing', () async {
      final events = repository.watchAll().take(2).toList();
      await pumpEventQueue();
      await database.customStatement('DROP TABLE daily_activity');
      database.markTablesUpdated({database.dailyActivity});

      expect((await events).last.failureOrNull, isNotNull);
      expect(
        (await repository.recordLesson(Duration.zero)).failureOrNull,
        isNotNull,
      );
      expect((await repository.clear()).failureOrNull, isNotNull);
      expect((await repository.readAll()).failureOrNull, isNotNull);
      expect((await repository.merge([])).failureOrNull, isNull);
      expect(
        (await repository.merge([DailyActivity(day: DateTime(2026, 11, 14))]))
            .failureOrNull,
        isNotNull,
      );
    });
  });
}
