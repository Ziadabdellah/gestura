import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/learn/domain/course_outline.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
import 'package:gestura/features/today/presentation/view_models/today_state.dart';
import 'package:gestura_core/gestura_core.dart';

Sign? signOfTheDay(List<Sign> signs, DateTime day) {
  if (signs.isEmpty) return null;
  final sorted = [...signs]..sort((a, b) => a.id.value.compareTo(b.id.value));
  final days = DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(2026)).inDays;
  return sorted[days % sorted.length];
}

class TodayViewModel extends Cubit<TodayState> {
  new(this._content, this._progress, this._reviews, this._activity)
    : super(const TodayLoading());

  final ContentRepository _content;
  final ProgressRepository _progress;
  final ReviewRepository _reviews;
  final ActivityRepository _activity;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Course? _course;
  Sign? _sign;
  ProgressByLesson? _done;
  List<ReviewCard>? _cards;
  List<DailyActivity>? _days;

  Future<void> load() async {
    if (state is! TodayLoading) emit(const TodayLoading());
    _stop();
    final (courses, signs) = await (
      _content.courses(),
      _content.searchSigns(''),
    ).wait;
    if (isClosed) return;
    switch ((courses, signs)) {
      case (Ok(value: [final course, ...]), Ok(value: final signs)):
        _course = course;
        _sign = signOfTheDay(signs, clock.now());
        _subscriptions.addAll([
          _progress.watchAll().listen(
            (result) => _take(result, (v) => _done = v),
          ),
          _reviews.watchAll().listen(
            (result) => _take(result, (v) => _cards = v),
          ),
          _activity.watchAll().listen(
            (result) => _take(result, (v) => _days = v),
          ),
        ]);
      case (Ok(), Ok()):
        emit(const TodayFailed(NoContentFailure()));
      case (Err(:final failure), _) || (_, Err(:final failure)):
        emit(TodayFailed(failure));
    }
  }

  void _take<T>(Result<T> result, void Function(T value) keep) {
    switch (result) {
      case Ok(:final value):
        keep(value);
        _emitReady();
      case Err(:final failure):
        emit(TodayFailed(failure));
    }
  }

  void _emitReady() {
    final (course, done, cards, days) = (_course, _done, _cards, _days);
    if (course == null || done == null || cards == null || days == null) {
      return;
    }
    final now = clock.now();
    final today = dayKey(now);
    emit(
      TodayReady(
        course: course,
        outline: CourseOutline.of(course, done),
        dueReviews: cards.where((card) => card.state.isDue(now)).length,
        minutesToday: days
            .where((day) => dayKey(day.day) == today)
            .fold(0, (sum, day) => sum + day.minutes),
        streak: streakOf(days, now),
        signOfTheDay: _sign,
      ),
    );
  }

  void _stop() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _done = null;
    _cards = null;
    _days = null;
  }

  @override
  Future<void> close() {
    _stop();
    return super.close();
  }
}
