import 'dart:developer' as developer;

import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: Telemetry, env: ['dev', 'staging'])
final class LocalTelemetry implements Telemetry {
  const new();

  static const String logName = 'gestura.telemetry';

  @override
  Future<void> applyConsent({
    required bool analytics,
    required bool crashReports,
  }) async {}

  @override
  Future<void> record(TelemetryEvent event) async =>
      developer.log('${event.name} ${event.parameters}', name: logName);
}
