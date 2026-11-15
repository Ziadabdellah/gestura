import 'package:gestura/core/telemetry/telemetry.dart';

class FakeTelemetry implements Telemetry {
  final List<TelemetryEvent> events = [];
  final List<({bool analytics, bool crashReports})> consents = [];

  @override
  Future<void> applyConsent({
    required bool analytics,
    required bool crashReports,
  }) async => consents.add((analytics: analytics, crashReports: crashReports));

  @override
  Future<void> record(TelemetryEvent event) async => events.add(event);
}
