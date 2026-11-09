import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/core/errors/app_bloc_observer.dart';
import 'package:gestura/core/errors/error_reporter.dart';

void installErrorHandlers(ErrorReporter reporter) {
  FlutterError.onError = (details) =>
      unawaited(reporter.recordFlutterError(details));
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(reporter.recordError(error, stackTrace, fatal: true));
    return true;
  };
  Bloc.observer = AppBlocObserver(reporter);
}
