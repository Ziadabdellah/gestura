import 'dart:async';

import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
import 'package:gestura_core/gestura_core.dart';

final DateTime reviewNow = DateTime.utc(2026, 11, 15, 9);

class FakeReviewRepository implements ReviewRepository {
  new([Iterable<ReviewCard> initial = const []])
    : stored = {for (final card in initial) card.signId: card};

  final Map<SignId, ReviewCard> stored;
  Failure? failure;
  final StreamController<void> _changes = StreamController.broadcast();

  Result<List<ReviewCard>> _snapshot() => switch (failure) {
    final Failure failure => Err(failure),
    null => Ok(stored.values.toList()),
  };

  @override
  Stream<Result<List<ReviewCard>>> watchAll() => Stream.multi((controller) {
    controller.add(_snapshot());
    final subscription = _changes.stream.listen(
      (_) => controller.add(_snapshot()),
    );
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<Result<List<ReviewCard>>> readAll() async => _snapshot();

  @override
  Future<Result<void>> addSigns(Set<SignId> signs) async {
    if (failure case final Failure failure) return Err(failure);
    for (final sign in signs) {
      stored.putIfAbsent(
        sign,
        () => ReviewCard(
          updatedAt: reviewNow,
          signId: sign,
          state: CardState.initial(reviewNow),
        ),
      );
    }
    _changes.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> save(ReviewCard card) async {
    if (failure case final Failure failure) return Err(failure);
    stored[card.signId] = card;
    _changes.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> merge(Iterable<ReviewCard> incoming) async {
    if (failure case final Failure failure) return Err(failure);
    for (final card in incoming) {
      final existing = stored[card.signId];
      if (existing == null || card.updatedAt.isAfter(existing.updatedAt)) {
        stored[card.signId] = card;
      }
    }
    _changes.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> clear() async {
    stored.clear();
    _changes.add(null);
    return const Ok(null);
  }
}
