import 'package:meta/meta.dart';

@immutable
final class DailyActivity {
  const new({
    required this.day,
    this.lessons = 0,
    this.reviews = 0,
    this.seconds = 0,
  });

  final DateTime day;
  final int lessons;
  final int reviews;
  final int seconds;

  int get minutes => (seconds / Duration.secondsPerMinute).floor();

  bool get isActive => lessons > 0 || reviews > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyActivity &&
          other.day == day &&
          other.lessons == lessons &&
          other.reviews == reviews &&
          other.seconds == seconds;

  @override
  int get hashCode => Object.hash(day, lessons, reviews, seconds);
}

String dayKey(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-'
    '${local.month.toString().padLeft(2, '0')}-'
    '${local.day.toString().padLeft(2, '0')}';

DateTime dayOf(String key) => DateTime.parse(key);

int streakOf(Iterable<DailyActivity> days, DateTime today) {
  final active = {
    for (final day in days)
      if (day.isActive) dayKey(day.day),
  };
  var cursor = DateTime(today.year, today.month, today.day);
  if (!active.contains(dayKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (active.contains(dayKey(cursor))) {
    streak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return streak;
}
