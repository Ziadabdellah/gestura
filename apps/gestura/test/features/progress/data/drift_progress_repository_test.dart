import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/database/app_database.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/progress/data/drift_progress_repository.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura_core/gestura_core.dart';

const LessonId _first = LessonId('demo-a1-1');
const LessonId _second = LessonId('demo-a1-2');

final DateTime _monday = DateTime.utc(2026, 11, 9, 8);
final DateTime _tuesday = DateTime.utc(2026, 11, 10, 18, 30);

void main() {
  late AppDatabase database;
  late DriftProgressRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftProgressRepository(database);
  });

  tearDown(() => database.close());

  Future<Result<void>> recordAt(DateTime time, LessonId lesson, int score) =>
      withClock(
        Clock.fixed(time),
        () => repository.recordCompletion(lesson, score: score),
      );

  Future<ProgressByLesson> current() async =>
      (await repository.watchAll().first).valueOrNull!;

  test('starts with no progress', () async {
    expect(await current(), isEmpty);
  });

  test('records a finished lesson with its score and time', () async {
    final result = await recordAt(_monday, _first, 80);

    expect(result, const Ok<void>(null));
    expect(await current(), {
      _first: LessonProgress(
        lessonId: _first,
        bestScore: 80,
        completedAt: _monday,
        updatedAt: _monday,
      ),
    });
  });

  test('keeps the best score and the first completion time', () async {
    await recordAt(_monday, _first, 80);
    await recordAt(_tuesday, _first, 60);
    final afterLower = (await current())[_first];
    await recordAt(_tuesday, _first, 95);
    final afterHigher = (await current())[_first];

    expect(afterLower?.bestScore, 80);
    expect(afterLower?.completedAt, _monday);
    expect(afterLower?.updatedAt, _tuesday);
    expect(afterHigher?.bestScore, 95);
  });

  test('stores times in UTC', () async {
    await recordAt(DateTime(2026, 11, 10, 12), _first, 70);

    final progress = (await current())[_first]!;

    expect(progress.completedAt.isUtc, isTrue);
    expect(progress.completedAt, DateTime(2026, 11, 10, 12).toUtc());
  });

  test('tells listeners about every change', () async {
    final updates = repository
        .watchAll()
        .map((result) => result.valueOrNull!.keys.toSet())
        .take(3)
        .toList();

    await pumpEventQueue();
    await recordAt(_monday, _first, 70);
    await pumpEventQueue();
    await recordAt(_monday, _second, 70);

    expect(await updates, [
      <LessonId>{},
      {_first},
      {_first, _second},
    ]);
  });

  test('refuses a score outside 0 to 100 and stores nothing', () async {
    final tooHigh = await recordAt(_monday, _first, 101);
    final tooLow = await recordAt(_monday, _first, -1);

    expect(tooHigh.failureOrNull, isA<UnexpectedFailure>());
    expect(
      (tooLow.failureOrNull! as UnexpectedFailure).error,
      isA<RangeError>(),
    );
    expect(await current(), isEmpty);
  });

  test('reports a write that fails', () async {
    await database.customStatement('DROP TABLE progress');

    final result = await recordAt(_monday, _first, 70);

    expect(result.failureOrNull, isA<UnexpectedFailure>());
  });

  test('merges progress from the cloud, keeping the best of both', () async {
    await recordAt(_tuesday, _first, 70);

    final result = await repository.merge([
      LessonProgress(
        lessonId: _first,
        bestScore: 90,
        completedAt: _monday,
        updatedAt: _monday,
      ),
      LessonProgress(
        lessonId: _second,
        bestScore: 40,
        completedAt: _monday,
        updatedAt: _tuesday,
      ),
    ]);
    await repository.merge([
      LessonProgress(
        lessonId: _first,
        bestScore: 10,
        completedAt: _tuesday,
        updatedAt: _tuesday.add(const Duration(days: 1)),
      ),
    ]);

    expect(result, const Ok<void>(null));
    expect(await current(), {
      _first: LessonProgress(
        lessonId: _first,
        bestScore: 90,
        completedAt: _monday,
        updatedAt: _tuesday.add(const Duration(days: 1)),
      ),
      _second: LessonProgress(
        lessonId: _second,
        bestScore: 40,
        completedAt: _monday,
        updatedAt: _tuesday,
      ),
    });
  });

  test('writes nothing when the cloud has nothing new', () async {
    await recordAt(_monday, _first, 70);
    final events = <Result<ProgressByLesson>>[];
    final subscription = repository.watchAll().listen(events.add);
    await pumpEventQueue();

    await repository.merge((await current()).values);
    await pumpEventQueue();
    await subscription.cancel();

    expect(events, hasLength(1));
  });

  test('reports a merge that fails', () async {
    await database.customStatement('DROP TABLE progress');

    final result = await repository.merge([
      LessonProgress(
        lessonId: _first,
        bestScore: 90,
        completedAt: _monday,
        updatedAt: _monday,
      ),
    ]);

    expect(result.failureOrNull, isA<UnexpectedFailure>());
  });

  test('forgets every lesson when the account is deleted', () async {
    await recordAt(_monday, _first, 70);
    await recordAt(_tuesday, _second, 90);

    expect(await repository.clear(), const Ok<void>(null));
    expect(await current(), isEmpty);
  });

  test('reads every lesson at once', () async {
    await recordAt(_monday, _first, 70);

    expect((await repository.readAll()).valueOrNull, await current());
  });

  test('reports a read that fails', () async {
    await database.customStatement('DROP TABLE progress');

    expect(
      (await repository.readAll()).failureOrNull,
      isA<UnexpectedFailure>(),
    );
  });

  test('reports a clear that fails', () async {
    await database.customStatement('DROP TABLE progress');

    expect((await repository.clear()).failureOrNull, isA<UnexpectedFailure>());
  });

  test('reports a broken table to listeners instead of throwing', () async {
    final results = repository.watchAll().take(2).toList();
    await pumpEventQueue();

    await database.customStatement('DROP TABLE progress');
    database.markTablesUpdated({database.progress});

    final [first, second] = await results;
    expect(first, isA<Ok<ProgressByLesson>>());
    expect(second.failureOrNull, isA<UnexpectedFailure>());
  });

  test('compares progress by value', () {
    LessonProgress progress(int score) => LessonProgress(
      lessonId: _first,
      bestScore: score,
      completedAt: _monday,
      updatedAt: _monday,
    );

    expect(progress(80), progress(80));
    expect(progress(80).hashCode, progress(80).hashCode);
    expect(progress(80), isNot(progress(81)));
  });
}
