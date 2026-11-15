import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/database/app_database.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/saved/data/drift_saved_signs_repository.dart';

void main() {
  late AppDatabase database;
  late DriftSavedSignsRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftSavedSignsRepository(database);
  });

  tearDown(() => database.close());

  Future<void> at(int minute, Future<void> Function() body) =>
      withClock(Clock.fixed(DateTime.utc(2026, 11, 15, 9, minute)), body);

  test('saves signs once, newest first, and removes them', () async {
    await at(1, () => repository.setSaved(const SignId('hello'), saved: true));
    await at(2, () => repository.setSaved(const SignId('yes'), saved: true));
    await at(3, () => repository.setSaved(const SignId('hello'), saved: true));

    expect((await repository.watchSaved().first).valueOrNull, [
      const SignId('yes'),
      const SignId('hello'),
    ]);
    expect((await repository.isSaved(const SignId('yes'))).valueOrNull, isTrue);

    await repository.setSaved(const SignId('yes'), saved: false);

    expect((await repository.isSaved(const SignId('yes'))).valueOrNull, false);
    expect((await repository.watchSaved().first).valueOrNull, [
      const SignId('hello'),
    ]);
  });

  test('clears every saved sign', () async {
    await repository.setSaved(const SignId('hello'), saved: true);

    await repository.clear();

    expect((await repository.watchSaved().first).valueOrNull, isEmpty);
  });

  test('reports a broken table instead of throwing', () async {
    final events = repository.watchSaved().take(2).toList();
    await pumpEventQueue();
    await database.customStatement('DROP TABLE collection_items');
    database.markTablesUpdated({database.collectionItems});

    expect((await events).last.failureOrNull, isNotNull);
    for (final result in [
      await repository.isSaved(const SignId('hello')),
      await repository.setSaved(const SignId('hello'), saved: true),
    ]) {
      expect(result.failureOrNull, isNotNull);
    }
    await database.customStatement('DROP TABLE collections');
    expect((await repository.clear()).failureOrNull, isNotNull);
  });
}
