import 'package:gestura/features/reminders/domain/reminders.dart';

class FakeReminders implements Reminders {
  new({this.granted = true});

  bool granted;
  final List<String> calls = [];

  @override
  Future<bool> requestPermission() async {
    calls.add('permission');
    return granted;
  }

  @override
  Future<void> scheduleDaily(int minutes, ReminderText text) async =>
      calls.add('daily:$minutes:${text.title}');

  @override
  Future<void> cancel() async => calls.add('cancel');
}
