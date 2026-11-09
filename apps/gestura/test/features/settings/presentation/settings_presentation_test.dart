import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/presentation/settings_presentation.dart';
import 'package:gestura/l10n/l10n.dart';

void main() {
  final english = lookupAppLocalizations(const Locale('en'));
  final arabic = lookupAppLocalizations(const Locale('ar'));

  group('AppLanguagePresentation', () {
    test('maps every language to its locale and the system one to none', () {
      expect(AppLanguage.system.locale, isNull);
      expect(AppLanguage.arabic.locale, const Locale('ar'));
      expect(AppLanguage.german.locale, const Locale('de'));
    });

    test('names every language in itself, whatever the interface is', () {
      expect(AppLanguage.arabic.label(english), 'العربية');
      expect(AppLanguage.russian.label(english), 'Русский');
      expect(AppLanguage.english.label(arabic), 'English');
    });

    test('names the system choice in the interface language', () {
      expect(AppLanguage.system.label(english), 'Device language');
      expect(AppLanguage.system.label(arabic), 'لغة الجهاز');
    });
  });

  group('AppThemePreferencePresentation', () {
    test('maps every preference to a theme mode', () {
      expect(AppThemePreference.values.map((theme) => theme.themeMode), [
        ThemeMode.system,
        ThemeMode.light,
        ThemeMode.dark,
      ]);
    });

    test('labels every preference in the interface language', () {
      expect(AppThemePreference.values.map((theme) => theme.label(english)), [
        'System',
        'Light',
        'Dark',
      ]);
    });

    test('gives every preference its own icon', () {
      expect(
        AppThemePreference.values.map((theme) => theme.icon).toSet(),
        hasLength(AppThemePreference.values.length),
      );
    });
  });
}
