import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';

import '../../helpers/fake_reminders.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('schedules the reminder again in the app language', (
    tester,
  ) async {
    final reminders = FakeReminders();
    await tester.pumpApp(
      settings: englishLight.copyWith(reminderMinutes: () => 600),
      reminders: reminders,
    );

    expect(reminders.calls, ['daily:600:Time to sign']);

    await tester.pumpApp(
      settings: englishLight.copyWith(
        language: AppLanguage.arabic,
        reminderMinutes: () => 600,
      ),
      reminders: reminders,
    );

    expect(reminders.calls.last, 'daily:600:حان وقت الإشارة');
  });

  testWidgets('touches nothing while reminders stay off', (tester) async {
    final reminders = FakeReminders();
    await tester.pumpApp(reminders: reminders);

    expect(reminders.calls, isEmpty);
  });
}
