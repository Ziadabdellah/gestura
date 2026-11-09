import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/gestura_app.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/core/storage/preference_keys.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/settings/data/shared_preferences_settings_repository.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferencesSettingsRepository> _freshRepository() async =>
    SharedPreferencesSettingsRepository(
      await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
          allowList: PreferenceKeys.all,
        ),
      ),
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await (await _freshRepository()).save(AppSettings.defaults);
    await getIt.reset();
  });

  testWidgets('settings survive a fresh read from the device storage', (
    tester,
  ) async {
    const saved = AppSettings(
      language: AppLanguage.arabic,
      theme: AppThemePreference.dark,
      reduceMotion: true,
    );

    final result = await (await _freshRepository()).save(saved);
    final afterRestart = await _freshRepository();

    expect(result, const Ok<void>(null));
    expect(afterRestart.load(), saved);
  });

  testWidgets('the app opens in the saved language and theme', (tester) async {
    await (await _freshRepository()).save(
      const AppSettings(
        language: AppLanguage.arabic,
        theme: AppThemePreference.dark,
      ),
    );
    await configureDependencies(const AppConfig(flavor: Flavor.dev));

    await tester.pumpWidget(
      const ProviderScope(
        child: GesturaApp(config: AppConfig(flavor: Flavor.dev)),
      ),
    );
    await tester.pumpAndSettle();

    final tagline = find.text('لغة الإشارة بين يديك.');

    expect(tagline, findsOneWidget);
    expect(Theme.of(tester.element(tagline)).brightness, Brightness.dark);
  });

  testWidgets('a language picked in settings is stored on the device', (
    tester,
  ) async {
    await (await _freshRepository()).save(
      const AppSettings(language: AppLanguage.english),
    );
    await configureDependencies(const AppConfig(flavor: Flavor.dev));

    await tester.pumpWidget(
      const ProviderScope(
        child: GesturaApp(
          config: AppConfig(flavor: Flavor.dev),
          initialLocation: '/settings',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Deutsch'), 100);
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(find.text('Einstellungen'), findsOneWidget);
    expect((await _freshRepository()).load().language, AppLanguage.german);
  });
}
