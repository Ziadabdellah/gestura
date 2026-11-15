import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: Telemetry, env: ['prod'])
final class FirebaseTelemetry implements Telemetry {
  new(this._analytics, this._crashlytics);

  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;
  bool _analyticsEnabled = false;

  @override
  Future<void> applyConsent({
    required bool analytics,
    required bool crashReports,
  }) async {
    _analyticsEnabled = analytics;
    await _analytics.setAnalyticsCollectionEnabled(analytics);
    if (!analytics) await _analytics.resetAnalyticsData();
    await _crashlytics.setCrashlyticsCollectionEnabled(crashReports);
    if (!crashReports) await _crashlytics.deleteUnsentReports();
  }

  @override
  Future<void> record(TelemetryEvent event) async {
    if (!_analyticsEnabled) return;
    try {
      await _analytics.logEvent(name: event.name, parameters: event.parameters);
    } on Object {
      return;
    }
  }
}
