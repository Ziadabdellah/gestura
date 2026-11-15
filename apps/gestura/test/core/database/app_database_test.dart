import 'dart:convert';
import 'dart:io';

import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/database/app_database.dart';
import 'package:gestura/core/database/database_failure.dart';
import 'package:gestura_core/gestura_core.dart';

void main() {
  group('AppDatabase', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    test('is at schema version 2 with the lesson progress table', () async {
      final columns = await database
          .customSelect("SELECT name FROM pragma_table_info('progress')")
          .map((row) => row.read<String>('name'))
          .get();

      expect(database.schemaVersion, 2);
      expect(columns, [
        'lesson_id',
        'best_score',
        'completed_at',
        'updated_at',
      ]);
    });

    test('matches the saved schema snapshot of its version', () async {
      final snapshot = jsonDecode(
        File(
          'drift_schemas/gestura/drift_schema_v${database.schemaVersion}.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final expected = {
        for (final entity in snapshot['fixed_sql'] as List<dynamic>)
          (entity as Map<String, dynamic>)['name']:
              ((entity['sql'] as List<dynamic>).single
                      as Map<String, dynamic>)['sql']
                  .toString()
                  .replaceFirst('IF NOT EXISTS ', '')
                  .replaceFirst(RegExp(r';$'), ''),
      };

      final actual = {
        for (final row
            in await database
                .customSelect(
                  "SELECT name, sql FROM sqlite_master WHERE type = 'table' "
                  "AND name NOT LIKE 'sqlite_%'",
                )
                .get())
          row.read<String>('name'): row.read<String>('sql'),
      };

      expect(actual, expected);
    });

    test('upgrades a version 1 database and keeps its progress', () async {
      final upgraded = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) => raw
            ..execute(
              'CREATE TABLE progress (lesson_id TEXT NOT NULL PRIMARY KEY, '
              'best_score INTEGER NOT NULL '
              'CHECK (best_score BETWEEN 0 AND 100), '
              'completed_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
            )
            ..execute(
              "INSERT INTO progress VALUES ('demo-a1-1', 80, "
              "'2026-11-10T09:00:00.000Z', '2026-11-10T09:00:00.000Z')",
            )
            ..execute('PRAGMA user_version = 1'),
        ),
      );
      addTearDown(upgraded.close);

      final tables = await upgraded
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name",
          )
          .map((row) => row.read<String>('name'))
          .get();
      final kept = await upgraded.select(upgraded.progress).getSingle();

      expect(tables, [
        'collection_items',
        'collections',
        'daily_activity',
        'progress',
        'review_cards',
      ]);
      expect(kept.bestScore, 80);
    });

    test('removes the signs of a deleted collection', () async {
      final now = DateTime.utc(2026, 11, 15);
      await database
          .into(database.collections)
          .insert(
            CollectionsCompanion.insert(
              id: 'favourites',
              name: 'Favourites',
              createdAt: now,
            ),
          );
      await database
          .into(database.collectionItems)
          .insert(
            CollectionItemsCompanion.insert(
              collectionId: 'favourites',
              signId: 'hello',
              addedAt: now,
            ),
          );

      await database.delete(database.collections).go();

      expect(await database.select(database.collectionItems).get(), isEmpty);
    });

    test('refuses a best score outside 0 to 100', () async {
      Future<void> insert(int score) =>
          database.customStatement('INSERT INTO progress VALUES (?, ?, ?, ?)', [
            'lesson',
            score,
            '2026-11-10T09:00:00.000Z',
            '2026-11-10T09:00:00.000Z',
          ]);

      await expectLater(insert(101), throwsA(isA<SqliteException>()));
      await expectLater(insert(-1), throwsA(isA<SqliteException>()));
      await expectLater(insert(100), completes);
    });

    test('stores dates as ISO 8601 text', () async {
      await database
          .into(database.progress)
          .insert(
            ProgressCompanion.insert(
              lessonId: 'lesson',
              bestScore: 80,
              completedAt: DateTime.utc(2026, 11, 10, 9),
              updatedAt: DateTime.utc(2026, 11, 10, 9),
            ),
          );

      final stored = await database
          .customSelect('SELECT completed_at FROM progress')
          .map((row) => row.read<String>('completed_at'))
          .getSingle();

      expect(stored, '2026-11-10T09:00:00.000Z');
    });
  });

  group('databaseFailure', () {
    test('reports a full disk as storage full', () {
      expect(
        databaseFailure(
          SqliteException(extendedResultCode: sqliteFull, message: 'full'),
        ),
        const StorageFullFailure(),
      );
    });

    test('reports any other error as unexpected', () {
      final error = SqliteException(extendedResultCode: 19, message: 'check');

      expect(databaseFailure(error), UnexpectedFailure(error));
      expect(databaseFailure(StateError('x')), isA<UnexpectedFailure>());
    });

    test('looks inside errors from the background isolate', () async {
      final directory = await Directory.systemTemp.createTemp('gestura_db');
      addTearDown(() => directory.delete(recursive: true));
      final database = AppDatabase(
        NativeDatabase.createInBackground(File('${directory.path}/test.db')),
      );
      addTearDown(database.close);

      final error = await database
          .customStatement('SELECT * FROM missing_table')
          .then<Object?>((_) => null, onError: (Object error) => error);

      expect(error, isA<DriftRemoteException>());
      expect(
        databaseFailure(error!),
        isA<UnexpectedFailure>().having(
          (failure) => failure.error,
          'error',
          isA<SqliteException>(),
        ),
      );
    });
  });
}
