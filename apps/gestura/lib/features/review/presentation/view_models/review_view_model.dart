import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
import 'package:gestura/features/review/presentation/view_models/review_state.dart';
import 'package:gestura_core/gestura_core.dart';

class ReviewViewModel extends Cubit<ReviewState> {
  new(
    this._reviews,
    this._content,
    this._activity, {
    this.playback = const Playback(),
  }) : super(const ReviewLoading());

  static const int sessionSize = 20;

  final ReviewRepository _reviews;
  final ContentRepository _content;
  final ActivityRepository _activity;
  final Playback playback;
  DateTime _shownAt = clock.now();

  Future<void> load() async {
    if (state is! ReviewLoading) emit(const ReviewLoading());
    final now = clock.now().toUtc();
    final List<ReviewCard> dueCards;
    switch (await _reviews.readAll()) {
      case Ok(:final value):
        dueCards =
            ([
                  for (final card in value)
                    if (card.state.isDue(now)) card,
                ]..sort((a, b) => a.state.dueAt.compareTo(b.state.dueAt)))
                .take(sessionSize)
                .toList();
      case Err(:final failure):
        if (!isClosed) emit(ReviewFailed(failure));
        return;
    }
    if (dueCards.isEmpty) {
      if (!isClosed) emit(const ReviewNothingDue());
      return;
    }
    final signs = await _content.signs({
      for (final card in dueCards) card.signId,
    });
    if (isClosed) return;
    switch (signs) {
      case Ok(:final value):
        final byId = {for (final sign in value) sign.id: sign};
        final known = [
          for (final card in dueCards)
            if (byId.containsKey(card.signId)) card,
        ];
        _shownAt = clock.now();
        emit(
          known.isEmpty
              ? const ReviewNothingDue()
              : ReviewInProgress(
                  cards: known,
                  signs: byId,
                  now: now,
                  playback: playback,
                ),
        );
      case Err(:final failure):
        emit(ReviewFailed(failure));
    }
  }

  void reveal() {
    if (state case final ReviewInProgress active when !active.revealed) {
      emit(active.copyWith(revealed: true));
    }
  }

  Future<void> grade(ReviewGrade grade) async {
    if (state case final ReviewInProgress active when active.revealed) {
      final next = review(active.card.state, grade, active.now);
      final spent = clock.now().difference(_shownAt);
      unawaited(
        _reviews.save(
          ReviewCard(
            signId: active.card.signId,
            state: next,
            updatedAt: clock.now().toUtc(),
          ),
        ),
      );
      unawaited(_activity.recordReview(spent));
      final remembered =
          active.remembered + (grade == ReviewGrade.again ? 0 : 1);
      _shownAt = clock.now();
      emit(
        active.index + 1 < active.cards.length
            ? active.copyWith(
                index: active.index + 1,
                revealed: false,
                remembered: remembered,
              )
            : ReviewFinished(
                reviewed: active.cards.length,
                remembered: remembered,
              ),
      );
    }
  }

  void setSpeed(PlaybackSpeed speed) =>
      _playback((value) => value.copyWith(speed: speed));

  void setLooping({required bool looping}) =>
      _playback((value) => value.copyWith(looping: looping));

  void setMirrored({required bool mirrored}) =>
      _playback((value) => value.copyWith(mirrored: mirrored));

  void _playback(Playback Function(Playback value) change) {
    if (state case final ReviewInProgress active) {
      emit(active.copyWith(playback: change(active.playback)));
    }
  }
}
