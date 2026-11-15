import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/telemetry/firebase_telemetry.dart';
import 'package:gestura/core/telemetry/local_telemetry.dart';
import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalytics extends Mock implements FirebaseAnalytics;

class _MockCrashlytics extends Mock implements FirebaseCrashlytics;

void main() {
  group('TelemetryEvent', () {
    test('names every event and keeps personal data out', () {
      const events = <TelemetryEvent>[
        OnboardingCompleted(dailyGoalMinutes: 10, leftHanded: true),
        OnboardingCompleted(dailyGoalMinutes: 5, leftHanded: false),
        SignedUp(AccountMethod.guest),
        SignedUp(AccountMethod.email),
        SignedIn(),
        LessonCompleted(lessonId: 'demo-a1-1', score: 80),
      ];

      expect(
        [for (final event in events) event.name],
        [
          'onboarding_complete',
          'onboarding_complete',
          'sign_up',
          'sign_up',
          'login',
          'lesson_complete',
        ],
      );
      expect(
        [for (final event in events) event.parameters],
        [
          {'daily_goal_minutes': 10, 'left_handed': 1},
          {'daily_goal_minutes': 5, 'left_handed': 0},
          {'method': 'guest'},
          {'method': 'email'},
          {'method': 'email'},
          {'lesson_id': 'demo-a1-1', 'score': 80},
        ],
      );
    });
  });

  group('LocalTelemetry', () {
    test('only writes events to the console', () async {
      const telemetry = LocalTelemetry();

      await telemetry.applyConsent(analytics: true, crashReports: true);
      await telemetry.record(const SignedIn());
    });
  });

  group('FirebaseTelemetry', () {
    late _MockAnalytics analytics;
    late _MockCrashlytics crashlytics;
    late FirebaseTelemetry telemetry;

    setUp(() {
      analytics = _MockAnalytics();
      crashlytics = _MockCrashlytics();
      telemetry = FirebaseTelemetry(analytics, crashlytics);
      when(() => analytics.setAnalyticsCollectionEnabled(any()))
          .thenAnswer((_) async {});
      when(analytics.resetAnalyticsData).thenAnswer((_) async {});
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});
      when(() => crashlytics.setCrashlyticsCollectionEnabled(any()))
          .thenAnswer((_) async {});
      when(crashlytics.deleteUnsentReports).thenAnswer((_) async {});
    });

    test('sends nothing before the learner agrees', () async {
      await telemetry.record(const SignedIn());

      verifyNever(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      );
    });

    test('turns collection on with consent and records events', () async {
      await telemetry.applyConsent(analytics: true, crashReports: true);
      await telemetry.record(
        const LessonCompleted(lessonId: 'demo-a1-1', score: 90),
      );

      verify(() => analytics.setAnalyticsCollectionEnabled(true)).called(1);
      verify(() => crashlytics.setCrashlyticsCollectionEnabled(true)).called(1);
      verifyNever(analytics.resetAnalyticsData);
      verifyNever(crashlytics.deleteUnsentReports);
      verify(
        () => analytics.logEvent(
          name: 'lesson_complete',
          parameters: {'lesson_id': 'demo-a1-1', 'score': 90},
        ),
      ).called(1);
    });

    test('turns collection off and deletes what was waiting', () async {
      await telemetry.applyConsent(analytics: true, crashReports: true);
      await telemetry.applyConsent(analytics: false, crashReports: false);
      await telemetry.record(const SignedIn());

      verify(() => analytics.setAnalyticsCollectionEnabled(false)).called(1);
      verify(analytics.resetAnalyticsData).called(1);
      verify(() => crashlytics.setCrashlyticsCollectionEnabled(false))
          .called(1);
      verify(crashlytics.deleteUnsentReports).called(1);
      verifyNever(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      );
    });

    test('never lets a failed event break the app', () async {
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenThrow(StateError('offline'));
      await telemetry.applyConsent(analytics: true, crashReports: false);

      await telemetry.record(const SignedIn());
    });
  });
}
