import 'package:flutter/material.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/l10n/l10n.dart';

extension AppLanguagePresentation on AppLanguage {
  Locale? get locale => switch (code) {
    final String code => Locale(code),
    null => null,
  };

  String label(AppLocalizations l10n) => switch (locale) {
    final Locale locale => lookupAppLocalizations(locale).languageName,
    null => l10n.languageSystem,
  };
}

extension AppThemePreferencePresentation on AppThemePreference {
  ThemeMode get themeMode => switch (this) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  String label(AppLocalizations l10n) => switch (this) {
    AppThemePreference.system => l10n.themeSystem,
    AppThemePreference.light => l10n.themeLight,
    AppThemePreference.dark => l10n.themeDark,
  };

  IconData get icon => switch (this) {
    AppThemePreference.system => Icons.brightness_auto_rounded,
    AppThemePreference.light => Icons.light_mode_rounded,
    AppThemePreference.dark => Icons.dark_mode_rounded,
  };
}
