import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:gestura/core/database/app_database.dart';
import 'package:gestura/core/database/database_failure.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ReviewRepository)
final class DriftReviewRepository implements ReviewRepository {
  new(this._database);

  final AppDatabase _database;

  @override
  Stream<Result<List<ReviewCard>>> watchAll() => _database
      .select(_database.reviewCards)
      .watch()
      .map<Result<List<ReviewCard>>>(
        (rows) => Ok([for (final row in rows) row.toDomain()]),
      )
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stackTrace, sink) =>
              sink.add(Err(databaseFailure(error))),
        ),
      );

  @override
  Future<Result<List<ReviewCard>>> readAll() => Result.guard(
    () async => [
      for (final row in await _database.select(_database.reviewCards).get())
        row.toDomain(),
    ],
    onError: (error, stackTrace) => databaseFailure(error),
  );

  @override
  Future<Result<void>> addSigns(Set<SignId> signs) => Result.guard(() async {
    final now = clock.now().toUtc();
    final start = CardState.initial(now);
    await _database.batch((batch) {
      batch.insertAll(_database.reviewCards, [
        for (final sign in signs)
          ReviewCardsCompanion.insert(
            signId: sign.value,
            repetitions: start.repetitions,
            intervalDays: start.intervalDays,
            ease: start.ease,
            dueAt: start.dueAt,
            updatedAt: now,
          ),
      ], mode: InsertMode.insertOrIgnore);
    });
  }, onError: (error, stackTrace) => databaseFailure(error));

  @override
  Future<Result<void>> save(ReviewCard card) => Result.guard(() async {
    await _database
        .into(_database.reviewCards)
        .insertOnConflictUpdate(
          ReviewCardsCompanion.insert(
            signId: card.signId.value,
            repetitions: card.state.repetitions,
            intervalDays: card.state.intervalDays,
            ease: card.state.ease,
            dueAt: card.state.dueAt.toUtc(),
            lapses: Value(card.state.lapses),
            updatedAt: card.updatedAt.toUtc(),
          ),
        );
  }, onError: (error, stackTrace) => databaseFailure(error));

  @override
  Future<Result<void>> merge(Iterable<ReviewCard> incoming) => Result.guard(
    () async {
      await _database.transaction(() async {
        for (final card in incoming) {
          final existing =
              await (_database.select(_database.reviewCards)
                    ..where((row) => row.signId.equals(card.signId.value)))
                  .getSingleOrNull();
          if (existing != null && !card.updatedAt.isAfter(existing.updatedAt)) {
            continue;
          }
          await _database
              .into(_database.reviewCards)
              .insertOnConflictUpdate(
                ReviewCardsCompanion.insert(
                  signId: card.signId.value,
                  repetitions: card.state.repetitions,
                  intervalDays: card.state.intervalDays,
                  ease: card.state.ease,
                  dueAt: card.state.dueAt.toUtc(),
                  lapses: Value(card.state.lapses),
                  updatedAt: card.updatedAt.toUtc(),
                ),
              );
        }
      });
    },
    onError: (error, stackTrace) => databaseFailure(error),
  );

  @override
  Future<Result<void>> clear() => Result.guard(() async {
    await _database.delete(_database.reviewCards).go();
  }, onError: (error, stackTrace) => databaseFailure(error));
}

extension on ReviewCardRow {
  ReviewCard toDomain() => ReviewCard(
    signId: SignId(signId),
    state: CardState(
      repetitions: repetitions,
      intervalDays: intervalDays,
      ease: ease,
      dueAt: dueAt,
      lapses: lapses,
    ),
    updatedAt: updatedAt,
  );
}
