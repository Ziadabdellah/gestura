typedef ReminderText = ({String title, String body, String channel});

abstract interface class Reminders {
  Future<bool> requestPermission();

  Future<void> scheduleDaily(int minutes, ReminderText text);

  Future<void> cancel();
}

DateTime nextReminder(DateTime now, int minutes) {
  final today = DateTime(
    now.year,
    now.month,
    now.day,
    minutes ~/ Duration.minutesPerHour,
    minutes % Duration.minutesPerHour,
  );
  return today.isAfter(now)
      ? today
      : DateTime(
          today.year,
          today.month,
          today.day + 1,
          today.hour,
          today.minute,
        );
}
