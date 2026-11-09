import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';

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
