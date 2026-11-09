import 'package:flutter/widgets.dart';
import 'package:gestura/app/gestura_app.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura_ui/gestura_ui.dart';

void bootstrap(AppConfig config) {
  WidgetsFlutterBinding.ensureInitialized();
  GesturaFontLicenses.register();
  runApp(GesturaApp(config: config));
}
