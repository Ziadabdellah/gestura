import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/database/app_database.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/review/data/drift_review_repository.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura_core/gestura_core.dart';

final DateTime _now = DateTime.utc(2026, 11, 15, 9);

void main() {
  late AppDatabase database;
  late DriftReviewRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftReviewRepository(database);
  });

  tearDown(() => database.close());

  Future<T> at<T>(Future<T> Function() body) =>
      withClock(Clock.fixed(_now), body);

  test('adds new signs once, due right away', () async {
    await at(() => repository.addSigns({const SignId('hello')}));
    final reviewed = review(CardState.initial(_now), ReviewGrade.good, _now);
    await at(
      () => repository.save(
        ReviewCard(
          updatedAt: _now,
          signId: const SignId('hello'),
          state: reviewed,
        ),
      ),
    );
    await at(
      () => repository.addSigns({const SignId('hello'), const SignId('yes')}),
    );

    final cards = (await repository.readAll()).valueOrNull!;

    expect(cards, hasLength(2));
    expect(
      cards.firstWhere((card) => card.signId == const SignId('hello')).state,
      reviewed,
    );
    expect(
      cards.firstWhere((card) => card.signId == const SignId('yes')).state,
      CardState.initial(_now),
    );
  });

  test(
    'tells listeners about changes and forgets everything on clear',
    () async {
      final events = repository.watchAll().take(2).toList();
      await pumpEventQueue();
      await at(() => repository.addSigns({const SignId('hello')}));

      expect((await events).last.valueOrNull, hasLength(1));
      expect(await repository.clear(), const Ok<void>(null));
      expect((await repository.readAll()).valueOrNull, isEmpty);
    },
  );

  test('reports a broken table instead of throwing', () async {
    final events = repository.watchAll().take(2).toList();
    await pumpEventQueue();
    await database.customStatement('DROP TABLE review_cards');
    database.markTablesUpdated({database.reviewCards});

    expect((await events).last.failureOrNull, isA<UnexpectedFailure>());
    for (final result in [
      await repository.readAll(),
      await repository.addSigns({const SignId('hello')}),
      await repository.save(
        ReviewCard(
          updatedAt: _now,
          signId: const SignId('a'),
          state: CardState.initial(_now),
        ),
      ),
      await repository.merge([
        ReviewCard(
          updatedAt: _now,
          signId: const SignId('a'),
          state: CardState.initial(_now),
        ),
      ]),
      await repository.clear(),
    ]) {
      expect(result.failureOrNull, isA<UnexpectedFailure>());
    }
  });

  test('merges another device by keeping the newest card', () async {
    final older = _now.subtract(const Duration(days: 1));
    final reviewed = review(CardState.initial(_now), ReviewGrade.good, _now);
    await repository.save(
      ReviewCard(updatedAt: _now, signId: const SignId('a'), state: reviewed),
    );

    await repository.merge([
      ReviewCard(
        updatedAt: older,
        signId: const SignId('a'),
        state: CardState.initial(older),
      ),
      ReviewCard(
        updatedAt: older,
        signId: const SignId('b'),
        state: CardState.initial(older),
      ),
    ]);
    final later = _now.add(const Duration(hours: 1));
    await repository.merge([
      ReviewCard(updatedAt: later, signId: const SignId('b'), state: reviewed),
    ]);

    final cards = {
      for (final card in (await repository.readAll()).valueOrNull!)
        card.signId.value: card,
    };
    expect(cards['a']?.state, reviewed);
    expect(cards['a']?.updatedAt, _now);
    expect(cards['b']?.state, reviewed);
    expect(cards['b']?.updatedAt, later);
  });

  test('cards compare by value', () {
    final card = ReviewCard(
      updatedAt: _now,
      signId: const SignId('a'),
      state: CardState.initial(_now),
    );
    expect(
      card,
      ReviewCard(
        updatedAt: _now,
        signId: const SignId('a'),
        state: CardState.initial(_now),
      ),
    );
    expect(
      card.hashCode,
      ReviewCard(
        updatedAt: _now,
        signId: const SignId('a'),
        state: CardState.initial(_now),
      ).hashCode,
    );
  });
}
