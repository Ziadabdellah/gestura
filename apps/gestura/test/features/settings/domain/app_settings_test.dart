import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';

void main() {
  group('AppLanguage', () {
    test('covers the system language and the six interface languages', () {
      expect(AppLanguage.values.map((language) => language.code), [
        null,
        'en',
        'ar',
        'ru',
        'es',
        'fr',
        'de',
      ]);
    });

    test('reads a language from its code', () {
      for (final language in AppLanguage.values) {
        expect(AppLanguage.fromCode(language.code), language);
      }
    });

    test('falls back to the system language for an unknown code', () {
      expect(AppLanguage.fromCode('xx'), AppLanguage.system);
      expect(AppLanguage.fromCode(null), AppLanguage.system);
    });
  });

  group('AppThemePreference', () {
    test('reads a theme from its name', () {
      for (final theme in AppThemePreference.values) {
        expect(AppThemePreference.fromName(theme.name), theme);
      }
    });

    test('falls back to the system theme for an unknown name', () {
      expect(AppThemePreference.fromName('neon'), AppThemePreference.system);
      expect(AppThemePreference.fromName(null), AppThemePreference.system);
    });
  });

  group('AppSettings', () {
    test('defaults to the device language and theme with motion on', () {
      expect(AppSettings.defaults.language, AppLanguage.system);
      expect(AppSettings.defaults.theme, AppThemePreference.system);
      expect(AppSettings.defaults.reduceMotion, isFalse);
    });

    test('copyWith replaces only the given fields', () {
      const base = AppSettings.defaults;

      expect(base.copyWith(), base);
      expect(
        base.copyWith(language: AppLanguage.arabic).language,
        AppLanguage.arabic,
      );
      expect(
        base.copyWith(theme: AppThemePreference.dark),
        const AppSettings(theme: AppThemePreference.dark),
      );
      expect(base.copyWith(reduceMotion: true).reduceMotion, isTrue);
    });

    test('compares by value', () {
      final reduceMotion = bool.parse('true');

      expect(
        AppSettings(reduceMotion: reduceMotion),
        const AppSettings(reduceMotion: true),
      );
      expect(
        AppSettings(reduceMotion: reduceMotion).hashCode,
        const AppSettings(reduceMotion: true).hashCode,
      );
      expect(
        const AppSettings(language: AppLanguage.german),
        isNot(AppSettings.defaults),
      );
    });

    test('describes itself for debugging', () {
      expect(
        AppSettings.defaults.toString(),
        'AppSettings(language: system, theme: system, reduceMotion: false)',
      );
    });
  });
}
