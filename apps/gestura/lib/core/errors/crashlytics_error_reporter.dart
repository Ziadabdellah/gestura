import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:gestura/core/errors/error_reporter.dart';
import 'package:gestura/core/errors/logging_error_reporter.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ErrorReporter, env: ['prod'])
final class CrashlyticsErrorReporter implements ErrorReporter {
  const new(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;
  static const ErrorReporter _console = LoggingErrorReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {
    await _console.recordError(error, stackTrace, fatal: fatal);
    if (!_crashlytics.isCrashlyticsCollectionEnabled) return;
    await _crashlytics.recordError(
      error,
      stackTrace,
      fatal: fatal,
      printDetails: false,
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (!_crashlytics.isCrashlyticsCollectionEnabled) {
      await _console.recordFlutterError(details);
      return;
    }
    await _crashlytics.recordFlutterFatalError(details);
  }
}
