import 'package:meta/meta.dart';

enum AppLanguage {
  system(null),
  english('en'),
  arabic('ar'),
  russian('ru'),
  spanish('es'),
  french('fr'),
  german('de');

  new(this.code);

  factory fromCode(String? code) => values.firstWhere(
    (language) => language.code == code,
    orElse: () => AppLanguage.system,
  );

  final String? code;
}

enum AppThemePreference {
  system,
  light,
  dark;

  factory fromName(String? name) => values.firstWhere(
    (theme) => theme.name == name,
    orElse: () => AppThemePreference.system,
  );
}

@immutable
final class AppSettings {
  const new({
    this.language = AppLanguage.system,
    this.theme = AppThemePreference.system,
    this.reduceMotion = false,
  });

  static const AppSettings defaults = AppSettings();

  final AppLanguage language;
  final AppThemePreference theme;
  final bool reduceMotion;

  AppSettings copyWith({
    AppLanguage? language,
    AppThemePreference? theme,
    bool? reduceMotion,
  }) => AppSettings(
    language: language ?? this.language,
    theme: theme ?? this.theme,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          other.language == language &&
          other.theme == theme &&
          other.reduceMotion == reduceMotion;

  @override
  int get hashCode => Object.hash(language, theme, reduceMotion);

  @override
  String toString() =>
      'AppSettings(language: ${language.name}, theme: ${theme.name}, '
      'reduceMotion: $reduceMotion)';
}
