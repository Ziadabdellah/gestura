import 'package:flutter/foundation.dart';

abstract interface class ErrorReporter {
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  });

  Future<void> recordFlutterError(FlutterErrorDetails details);
}
