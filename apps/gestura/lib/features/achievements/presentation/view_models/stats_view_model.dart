import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/achievements/domain/learner_stats.dart';
import 'package:gestura/features/achievements/presentation/view_models/stats_state.dart';
import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
import 'package:gestura_core/gestura_core.dart';

class StatsViewModel extends Cubit<StatsState> {
  new(this._progress, this._reviews, this._activity)
    : super(const StatsLoading());

  final ProgressRepository _progress;
  final ReviewRepository _reviews;
  final ActivityRepository _activity;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  int? _lessons;
  List<ReviewCard>? _cards;
  List<DailyActivity>? _days;

  void start() {
    _stop();
    if (state is! StatsLoading) emit(const StatsLoading());
    _lessons = null;
    _cards = null;
    _days = null;
    _subscriptions.addAll([
      _progress.watchAll().listen(
        (result) => _take(result, (value) => _lessons = value.length),
      ),
      _reviews.watchAll().listen(
        (result) => _take(result, (value) => _cards = value),
      ),
      _activity.watchAll().listen(
        (result) => _take(result, (value) => _days = value),
      ),
    ]);
  }

  void _take<T>(Result<T> result, void Function(T value) keep) {
    switch (result) {
      case Ok(:final value):
        keep(value);
        if ((_lessons, _cards, _days) case (
          final int lessons,
          final List<ReviewCard> cards,
          final List<DailyActivity> days,
        )) {
          emit(
            StatsReady(
              LearnerStats.of(
                lessons: lessons,
                cards: cards,
                days: days,
                today: clock.now(),
              ),
            ),
          );
        }
      case Err(:final failure):
        emit(StatsFailed(failure));
    }
  }

  void _stop() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  @override
  Future<void> close() {
    _stop();
    return super.close();
  }
}
