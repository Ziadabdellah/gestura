import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/reminders/data/local_reminders.dart';
import 'package:gestura/features/reminders/domain/reminders.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin;

class _MockAndroid extends Mock
    implements AndroidFlutterLocalNotificationsPlugin;

class _MockIos extends Mock implements IOSFlutterLocalNotificationsPlugin;

const ReminderText _text = (
  title: 'Time to sign',
  body: 'Keep going',
  channel: 'Daily reminder',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _MockPlugin plugin;

  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(tz.TZDateTime.utc(2026));
  });

  setUp(() {
    plugin = _MockPlugin();
    when(() => plugin.initialize(settings: any(named: 'settings')))
        .thenAnswer((_) async => true);
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('nextReminder', () {
    test('rings later today or tomorrow at the same time', () {
      final morning = DateTime(2026, 11, 15, 8);
      expect(nextReminder(morning, 19 * 60), DateTime(2026, 11, 15, 19));
      expect(nextReminder(morning, 8 * 60), DateTime(2026, 11, 16, 8));
      expect(
        nextReminder(DateTime(2026, 12, 31, 23), 30),
        DateTime(2027, 1, 1, 0, 30),
      );
    });
  });

  test('schedules one daily reminder at the chosen time', () async {
    final reminders = LocalReminders(
      plugin,
      timezone: () async => 'Africa/Cairo',
    );

    await reminders.scheduleDaily(19 * 60 + 30, _text);
    await reminders.cancel();

    verify(() => plugin.initialize(settings: any(named: 'settings'))).called(1);
    final scheduled =
        verify(
              () => plugin.zonedSchedule(
                id: LocalReminders.dailyId,
                scheduledDate: captureAny(named: 'scheduledDate'),
                notificationDetails: any(named: 'notificationDetails'),
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                title: 'Time to sign',
                body: 'Keep going',
                matchDateTimeComponents: DateTimeComponents.time,
              ),
            ).captured.single
            as tz.TZDateTime;
    expect(scheduled.location.name, 'Africa/Cairo');
    expect((scheduled.hour, scheduled.minute), (19, 30));
    verify(() => plugin.cancel(id: LocalReminders.dailyId)).called(1);
  });

  test('reads the device time zone', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          (call) async => 'Europe/Berlin',
        );

    expect(await localTimezone(), 'Europe/Berlin');
  });

  test('falls back to UTC for an unknown time zone', () async {
    final reminders = LocalReminders(plugin, timezone: () async => 'Mars/Base');

    await reminders.cancel();

    expect(tz.local, tz.UTC);
  });

  test('asks Android for permission', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final android = _MockAndroid();
    when(android.requestNotificationsPermission).thenAnswer((_) async => true);
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(android);

    expect(
      await LocalReminders(
        plugin,
        timezone: () async => 'UTC',
      ).requestPermission(),
      isTrue,
    );
  });

  test('asks iOS for permission and treats no answer as no', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final ios = _MockIos();
    when(() => ios.requestPermissions(alert: true, sound: true))
        .thenAnswer((_) async => null);
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(ios);

    expect(
      await LocalReminders(
        plugin,
        timezone: () async => 'UTC',
      ).requestPermission(),
      isFalse,
    );
  });

  test('cannot remind on other platforms', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    expect(
      await LocalReminders(
        plugin,
        timezone: () async => 'UTC',
      ).requestPermission(),
      isFalse,
    );
  });
}
