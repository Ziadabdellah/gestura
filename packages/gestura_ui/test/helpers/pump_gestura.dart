import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

import 'gestura_test_scope.dart';

extension PumpGestura on WidgetTester {
  Future<void> pumpGestura(
    Widget child, {
    Locale locale = const Locale('en'),
    Brightness brightness = Brightness.light,
    double textScale = 1,
    bool disableAnimations = false,
    Size surfaceSize = const Size(360, 640),
  }) async {
    view
      ..physicalSize = surfaceSize * 3
      ..devicePixelRatio = 3;
    addTearDown(view.reset);
    final scale = GesturaScale.fromSize(surfaceSize);

    await pumpWidget(
      MaterialApp(
        theme: GesturaTheme.light(scale: scale),
        darkTheme: GesturaTheme.dark(scale: scale),
        themeMode: switch (brightness) {
          Brightness.light => ThemeMode.light,
          Brightness.dark => ThemeMode.dark,
        },
        locale: locale,
        supportedLocales: supportedTestLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: app!,
        ),
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(GesturaSpacing.md),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> expectAccessibleTapTargets() async {
    await expectLater(this, meetsGuideline(androidTapTargetGuideline));
    await expectLater(this, meetsGuideline(labeledTapTargetGuideline));
  }

  Future<void> expectAccessible() async {
    await expectAccessibleTapTargets();
    await expectLater(this, meetsGuideline(textContrastGuideline));
  }
}
