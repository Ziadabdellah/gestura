import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestura/app/gestura_app.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/core/errors/error_handlers.dart';
import 'package:gestura/core/errors/error_reporter.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/firebase/firebase_options.dart';
import 'package:gestura_ui/gestura_ui.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptionsFor(config.flavor));
  await configureDependencies(config);
  installErrorHandlers(getIt<ErrorReporter>());
  GesturaFontLicenses.register();
  runApp(ProviderScope(child: GesturaApp(config: config)));
}
