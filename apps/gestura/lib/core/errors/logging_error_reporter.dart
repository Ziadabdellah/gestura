import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:gestura/core/errors/error_reporter.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ErrorReporter)
final class LoggingErrorReporter implements ErrorReporter {
  const new();

  static const String logName = 'gestura';
  static const int fatalLevel = 1200;
  static const int errorLevel = 1000;

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {
    developer.log(
      fatal ? 'Fatal error' : 'Error',
      name: logName,
      level: fatal ? fatalLevel : errorLevel,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    FlutterError.presentError(details);
  }
}
