import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/gestura_app.dart';
import 'package:gestura/config/app_config.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp({
    Flavor flavor = Flavor.prod,
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.light,
    Size surfaceSize = const Size(360, 780),
    double textScale = 1,
  }) async {
    view
      ..physicalSize = surfaceSize * 3
      ..devicePixelRatio = 3;
    platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(view.reset);
    addTearDown(platformDispatcher.clearTextScaleFactorTestValue);

    await pumpWidget(
      GesturaApp(
        config: AppConfig(flavor: flavor),
        locale: locale,
        themeMode: themeMode,
      ),
    );
    await pump();
  }
}
