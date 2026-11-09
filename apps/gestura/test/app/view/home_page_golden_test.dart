import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:gestura/app/gestura_app.dart';
import 'package:gestura/config/app_config.dart';

const Size _phone = Size(360, 640);

void main() {
  unawaited(
    goldenTest(
      'Home page in English and Arabic, light and dark',
      fileName: 'home_page',
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          for (final locale in const [Locale('en'), Locale('ar')])
            for (final mode in const [ThemeMode.light, ThemeMode.dark])
              GoldenTestScenario(
                name: '${locale.languageCode} ${mode.name}',
                child: SizedBox.fromSize(
                  size: _phone,
                  child: MediaQuery(
                    data: const MediaQueryData(size: _phone),
                    child: GesturaApp(
                      config: const AppConfig(flavor: Flavor.prod),
                      locale: locale,
                      themeMode: mode,
                    ),
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}
