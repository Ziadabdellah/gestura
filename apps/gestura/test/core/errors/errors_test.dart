import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/errors/error_handlers.dart';
import 'package:gestura/core/errors/error_reporter.dart';
import 'package:gestura/core/errors/logging_error_reporter.dart';

class _RecordingReporter implements ErrorReporter {
  final List<({Object error, bool fatal})> errors = [];
  final List<FlutterErrorDetails> flutterErrors = [];

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async => errors.add((error: error, fatal: fatal));

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async =>
      flutterErrors.add(details);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('installErrorHandlers', () {
    late FlutterExceptionHandler? originalFlutterHandler;
    late ErrorCallback? originalPlatformHandler;

    setUp(() {
      originalFlutterHandler = FlutterError.onError;
      originalPlatformHandler = PlatformDispatcher.instance.onError;
    });

    tearDown(() {
      FlutterError.onError = originalFlutterHandler;
      PlatformDispatcher.instance.onError = originalPlatformHandler;
    });

    test('sends framework errors to the reporter', () async {
      final reporter = _RecordingReporter();
      installErrorHandlers(reporter);
      final details = FlutterErrorDetails(exception: StateError('layout'));

      FlutterError.onError!(details);
      await Future<void>.delayed(Duration.zero);

      expect(reporter.flutterErrors.single, same(details));
    });

    test('sends uncaught async errors to the reporter as fatal', () async {
      final reporter = _RecordingReporter();
      final error = StateError('async');
      installErrorHandlers(reporter);

      final handled = PlatformDispatcher.instance.onError!(
        error,
        StackTrace.current,
      );
      await Future<void>.delayed(Duration.zero);

      expect(handled, isTrue);
      expect(reporter.errors.single, (error: error, fatal: true));
    });
  });

  group('LoggingErrorReporter', () {
    const reporter = LoggingErrorReporter();

    test('logs errors without throwing', () async {
      await expectLater(
        reporter.recordError(StateError('x'), StackTrace.current),
        completes,
      );
      await expectLater(
        reporter.recordError(StateError('x'), StackTrace.current, fatal: true),
        completes,
      );
    });

    test('presents framework errors the usual way', () async {
      final presented = <FlutterErrorDetails>[];
      final original = FlutterError.presentError;
      FlutterError.presentError = presented.add;
      addTearDown(() => FlutterError.presentError = original);
      final details = FlutterErrorDetails(exception: StateError('paint'));

      await reporter.recordFlutterError(details);

      expect(presented.single, same(details));
    });
  });
}
