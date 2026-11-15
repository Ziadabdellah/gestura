import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/achievements/domain/learner_stats.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura_core/gestura_core.dart';

final DateTime _now = DateTime(2026, 11, 15, 9);

ReviewCard _card(String id, int interval) => ReviewCard(
  signId: SignId(id),
  state: CardState(
    repetitions: 2,
    intervalDays: interval,
    ease: 2.5,
    dueAt: _now,
  ),
  updatedAt: _now,
);

DailyActivity _day(int day, {int reviews = 1, int seconds = 600}) =>
    DailyActivity(
      day: DateTime(2026, 11, day),
      reviews: reviews,
      seconds: seconds,
    );

void main() {
  test('counts lessons, signs, mastery, streaks, minutes and reviews', () {
    final stats = LearnerStats.of(
      lessons: 2,
      cards: [_card('a', 1), _card('b', 21), _card('c', 40)],
      days: [
        _day(1),
        _day(2),
        _day(3),
        _day(4),
        _day(10, reviews: 0, seconds: 0),
        _day(14),
        _day(15, reviews: 5),
      ],
      today: _now,
    );

    expect(
      stats,
      const LearnerStats(
        lessons: 2,
        signs: 3,
        mastered: 2,
        streak: 2,
        bestStreak: 4,
        minutes: 60,
        reviews: 10,
      ),
    );
    expect(stats.hashCode, stats.hashCode);
    expect(stats, isNot(const LearnerStats()));
    expect(bestStreakOf(const []), 0);
  });

  test('achievements fill up to their target and are earned there', () {
    const stats = LearnerStats(
      lessons: 3,
      signs: 12,
      bestStreak: 7,
      minutes: 30,
      reviews: 100,
    );

    expect(Achievement.firstLesson.earnedIn(stats), isTrue);
    expect(Achievement.firstLesson.progressIn(stats), 1);
    expect(Achievement.tenSigns.earnedIn(stats), isTrue);
    expect(Achievement.fiftySigns.progressIn(stats), 12);
    expect(Achievement.firstMastered.earnedIn(stats), isFalse);
    expect(Achievement.sevenDays.earnedIn(stats), isTrue);
    expect(Achievement.thirtyDays.progressIn(stats), 7);
    expect(Achievement.threeDays.earnedIn(stats), isTrue);
    expect(Achievement.hundredReviews.earnedIn(stats), isTrue);
    expect(Achievement.hourOfPractice.progressIn(stats), 30);
  });
}
