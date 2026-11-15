import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:gestura/features/reminders/domain/reminders.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/data/latest_all.dart' as zones;
import 'package:timezone/timezone.dart' as tz;

Future<String> localTimezone() async =>
    (await FlutterTimezone.getLocalTimezone()).identifier;

@LazySingleton(as: Reminders)
final class LocalReminders implements Reminders {
  new(this._plugin, {@ignoreParam this.timezone = localTimezone});

  static const int dailyId = 1;
  static const String channelId = 'daily_reminder';
  static const String icon = 'ic_notification';

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<String> Function() timezone;
  Future<void>? _ready;

  Future<void> _prepare() => _ready ??= () async {
    zones.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await timezone()));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(icon),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  @override
  Future<bool> requestPermission() async {
    await _prepare();
    final granted = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission(),
      TargetPlatform.iOS =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true),
      _ => false,
    };
    return granted ?? false;
  }

  @override
  Future<void> scheduleDaily(int minutes, ReminderText text) async {
    await _prepare();
    final now = tz.TZDateTime.now(tz.local);
    final next = nextReminder(now, minutes);
    await _plugin.zonedSchedule(
      id: dailyId,
      scheduledDate: tz.TZDateTime(
        tz.local,
        next.year,
        next.month,
        next.day,
        next.hour,
        next.minute,
      ),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(channelId, text.channel),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: text.title,
      body: text.body,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel() async {
    await _prepare();
    await _plugin.cancel(id: dailyId);
  }
}
