import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/errors/crashlytics_error_reporter.dart';
import 'package:mocktail/mocktail.dart';

class _MockCrashlytics extends Mock implements FirebaseCrashlytics;

void main() {
  late _MockCrashlytics crashlytics;
  late CrashlyticsErrorReporter reporter;
  final details = FlutterErrorDetails(exception: StateError('layout'));
  final stack = StackTrace.current;

  setUpAll(() => registerFallbackValue(details));

  setUp(() {
    crashlytics = _MockCrashlytics();
    reporter = CrashlyticsErrorReporter(crashlytics);
    when(
      () => crashlytics.recordError(
        any<Object>(),
        any(),
        fatal: any(named: 'fatal'),
        printDetails: any(named: 'printDetails'),
      ),
    ).thenAnswer((_) async {});
    when(() => crashlytics.recordFlutterFatalError(any()))
        .thenAnswer((_) async {});
  });

  test('sends errors to Crashlytics once the learner agreed', () async {
    when(() => crashlytics.isCrashlyticsCollectionEnabled).thenReturn(true);
    final error = StateError('broken');

    await reporter.recordError(error, stack, fatal: true);
    await reporter.recordFlutterError(details);

    verify(
      () => crashlytics.recordError(
        error,
        stack,
        fatal: true,
        printDetails: false,
      ),
    ).called(1);
    verify(() => crashlytics.recordFlutterFatalError(details)).called(1);
  });

  test('keeps errors on the device without consent', () async {
    when(() => crashlytics.isCrashlyticsCollectionEnabled).thenReturn(false);
    final presented = <FlutterErrorDetails>[];
    final original = FlutterError.presentError;
    FlutterError.presentError = presented.add;
    addTearDown(() => FlutterError.presentError = original);

    await reporter.recordError(StateError('broken'), stack);
    await reporter.recordFlutterError(details);

    expect(presented, [details]);
    verifyNever(
      () => crashlytics.recordError(
        any<Object>(),
        any(),
        fatal: any(named: 'fatal'),
        printDetails: any(named: 'printDetails'),
      ),
    );
    verifyNever(() => crashlytics.recordFlutterFatalError(any()));
  });
}
