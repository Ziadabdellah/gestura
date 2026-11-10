import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/presentation/settings_presentation.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

import 'fake_settings_repository.dart';
import 'pump_app.dart';

const List<AppSettings> goldenSettings = [
  AppSettings(language: AppLanguage.english, theme: AppThemePreference.light),
  AppSettings(language: AppLanguage.english, theme: AppThemePreference.dark),
  AppSettings(language: AppLanguage.arabic, theme: AppThemePreference.light),
  AppSettings(language: AppLanguage.arabic, theme: AppThemePreference.dark),
];

GoldenTestScenario appScenario({
  required AppSettings settings,
  required String location,
  Size size = const Size(360, 920),
}) => GoldenTestScenario(
  name: '${settings.language.code} ${settings.theme.name}',
  child: SizedBox.fromSize(
    size: size,
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: appUnderTest(
        repository: FakeSettingsRepository(settings),
        initialLocation: location,
      ),
    ),
  ),
);

Future<void> loadThenPrecacheImages(WidgetTester tester) async {
  await tester.pump();
  await precacheImages(tester);
}

Widget viewUnderTest({required AppSettings settings, required Widget child}) =>
    GesturaAdaptiveBuilder(
      builder: (context, scale) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: GesturaTheme.light(scale: scale),
        darkTheme: GesturaTheme.dark(scale: scale),
        themeMode: settings.theme.themeMode,
        locale: settings.language.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

GoldenTestScenario viewScenario({
  required String name,
  required AppSettings settings,
  required Widget child,
  Size size = const Size(360, 780),
}) => GoldenTestScenario(
  name: name,
  child: SizedBox.fromSize(
    size: size,
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: viewUnderTest(settings: settings, child: child),
    ),
  ),
);
