import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:gestura/core/database/app_database.dart';
import 'package:gestura/core/database/database_failure.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/saved/domain/saved_signs_repository.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: SavedSignsRepository)
final class DriftSavedSignsRepository implements SavedSignsRepository {
  new(this._database);

  static const String collectionId = 'saved';

  final AppDatabase _database;

  SimpleSelectStatement<CollectionItems, CollectionItemRow> _items() =>
      _database.select(_database.collectionItems)
        ..where((row) => row.collectionId.equals(collectionId))
        ..orderBy([(row) => OrderingTerm.desc(row.addedAt)]);

  @override
  Stream<Result<List<SignId>>> watchSaved() => _items()
      .watch()
      .map<Result<List<SignId>>>(
        (rows) => Ok([for (final row in rows) SignId(row.signId)]),
      )
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stackTrace, sink) =>
              sink.add(Err(databaseFailure(error))),
        ),
      );

  @override
  Future<Result<bool>> isSaved(SignId sign) => Result.guard(
    () async =>
        await (_database.select(_database.collectionItems)..where(
              (row) =>
                  row.collectionId.equals(collectionId) &
                  row.signId.equals(sign.value),
            ))
            .getSingleOrNull() !=
        null,
    onError: (error, stackTrace) => databaseFailure(error),
  );

  @override
  Future<Result<void>> setSaved(SignId sign, {required bool saved}) =>
      Result.guard(() async {
        final now = clock.now().toUtc();
        await _database.transaction(() async {
          if (!saved) {
            await (_database.delete(_database.collectionItems)..where(
                  (row) =>
                      row.collectionId.equals(collectionId) &
                      row.signId.equals(sign.value),
                ))
                .go();
            return;
          }
          await _database
              .into(_database.collections)
              .insert(
                CollectionsCompanion.insert(
                  id: collectionId,
                  name: 'Saved',
                  createdAt: now,
                ),
                mode: InsertMode.insertOrIgnore,
              );
          await _database
              .into(_database.collectionItems)
              .insert(
                CollectionItemsCompanion.insert(
                  collectionId: collectionId,
                  signId: sign.value,
                  addedAt: now,
                ),
                mode: InsertMode.insertOrIgnore,
              );
        });
      }, onError: (error, stackTrace) => databaseFailure(error));

  @override
  Future<Result<void>> clear() => Result.guard(() async {
    await (_database.delete(
      _database.collections,
    )..where((row) => row.id.equals(collectionId))).go();
  }, onError: (error, stackTrace) => databaseFailure(error));
}
