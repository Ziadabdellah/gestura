import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/core/errors/error_reporter.dart';

final class AppBlocObserver extends BlocObserver {
  const new(this._reporter);

  final ErrorReporter _reporter;

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    unawaited(_reporter.recordError(error, stackTrace));
    super.onError(bloc, error, stackTrace);
  }
}
