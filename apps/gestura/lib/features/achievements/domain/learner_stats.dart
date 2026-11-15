import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:meta/meta.dart';

@immutable
final class LearnerStats {
  const new({
    this.lessons = 0,
    this.signs = 0,
    this.mastered = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.minutes = 0,
    this.reviews = 0,
  });

  factory of({
    required int lessons,
    required List<ReviewCard> cards,
    required List<DailyActivity> days,
    required DateTime today,
  }) => LearnerStats(
    lessons: lessons,
    signs: cards.length,
    mastered: cards
        .where((card) => card.state.intervalDays >= masteredAfterDays)
        .length,
    streak: streakOf(days, today),
    bestStreak: bestStreakOf(days),
    minutes:
        days.fold<int>(0, (sum, day) => sum + day.seconds) ~/
        Duration.secondsPerMinute,
    reviews: days.fold<int>(0, (sum, day) => sum + day.reviews),
  );

  static const int masteredAfterDays = 21;

  final int lessons;
  final int signs;
  final int mastered;
  final int streak;
  final int bestStreak;
  final int minutes;
  final int reviews;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearnerStats &&
          other.lessons == lessons &&
          other.signs == signs &&
          other.mastered == mastered &&
          other.streak == streak &&
          other.bestStreak == bestStreak &&
          other.minutes == minutes &&
          other.reviews == reviews;

  @override
  int get hashCode => Object.hash(
    lessons,
    signs,
    mastered,
    streak,
    bestStreak,
    minutes,
    reviews,
  );
}

int bestStreakOf(Iterable<DailyActivity> days) {
  final active = [
    for (final day in days)
      if (day.isActive) DateTime.utc(day.day.year, day.day.month, day.day.day),
  ]..sort();
  var best = 0;
  var run = 0;
  DateTime? previous;
  for (final day in active) {
    run = previous != null && day.difference(previous).inDays == 1
        ? run + 1
        : 1;
    if (run > best) best = run;
    previous = day;
  }
  return best;
}

enum Achievement {
  firstLesson(target: 1),
  tenSigns(target: 10),
  fiftySigns(target: 50),
  firstMastered(target: 1),
  threeDays(target: 3),
  sevenDays(target: 7),
  thirtyDays(target: 30),
  hundredReviews(target: 100),
  hourOfPractice(target: 60);

  new({required this.target});

  final int target;

  int valueIn(LearnerStats stats) => switch (this) {
    firstLesson => stats.lessons,
    tenSigns || fiftySigns => stats.signs,
    firstMastered => stats.mastered,
    threeDays || sevenDays || thirtyDays => stats.bestStreak,
    hundredReviews => stats.reviews,
    hourOfPractice => stats.minutes,
  };

  int progressIn(LearnerStats stats) =>
      valueIn(stats) > target ? target : valueIn(stats);

  bool earnedIn(LearnerStats stats) => valueIn(stats) >= target;
}
