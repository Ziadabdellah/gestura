import 'package:meta/meta.dart';

@immutable
sealed class TelemetryEvent {
  const new();

  String get name;

  Map<String, Object> get parameters;
}

final class OnboardingCompleted extends TelemetryEvent {
  const new({required this.dailyGoalMinutes, required this.leftHanded});

  final int dailyGoalMinutes;
  final bool leftHanded;

  @override
  String get name => 'onboarding_complete';

  @override
  Map<String, Object> get parameters => {
    'daily_goal_minutes': dailyGoalMinutes,
    'left_handed': leftHanded ? 1 : 0,
  };
}

enum AccountMethod { guest, email, google }

final class SignedUp extends TelemetryEvent {
  const new(this.method);

  final AccountMethod method;

  @override
  String get name => 'sign_up';

  @override
  Map<String, Object> get parameters => {'method': method.name};
}

final class SignedIn extends TelemetryEvent {
  const new();

  @override
  String get name => 'login';

  @override
  Map<String, Object> get parameters => const {'method': 'email'};
}

final class LessonCompleted extends TelemetryEvent {
  const new({required this.lessonId, required this.score});

  final String lessonId;
  final int score;

  @override
  String get name => 'lesson_complete';

  @override
  Map<String, Object> get parameters => {'lesson_id': lessonId, 'score': score};
}

abstract interface class Telemetry {
  Future<void> applyConsent({
    required bool analytics,
    required bool crashReports,
  });

  Future<void> record(TelemetryEvent event);
}
