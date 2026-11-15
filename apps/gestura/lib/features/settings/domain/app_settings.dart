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

enum DailyGoal {
  five(5),
  ten(10),
  fifteen(15);

  new(this.minutes);

  factory fromMinutes(int? minutes) => values.firstWhere(
    (goal) => goal.minutes == minutes,
    orElse: () => AppSettings.defaults.dailyGoal,
  );

  final int minutes;
}

enum DominantHand {
  right,
  left;

  factory fromName(String? name) => values.firstWhere(
    (hand) => hand.name == name,
    orElse: () => AppSettings.defaults.dominantHand,
  );

  bool get mirrorsVideo => this == left;
}

@immutable
final class AppSettings {
  const new({
    this.language = AppLanguage.system,
    this.theme = AppThemePreference.system,
    this.reduceMotion = false,
    this.signLanguage,
    this.dailyGoal = DailyGoal.ten,
    this.dominantHand = DominantHand.right,
    this.analyticsConsent = false,
    this.crashReportsConsent = false,
    this.onboardingComplete = false,
    this.reminderMinutes,
  });

  static const int defaultReminderMinutes = 19 * 60;
  static const int minutesPerDay = 24 * 60;

  static const AppSettings defaults = AppSettings();

  final AppLanguage language;
  final AppThemePreference theme;
  final bool reduceMotion;
  final String? signLanguage;
  final DailyGoal dailyGoal;
  final DominantHand dominantHand;
  final bool analyticsConsent;
  final bool crashReportsConsent;
  final bool onboardingComplete;
  final int? reminderMinutes;

  bool get remindsDaily => reminderMinutes != null;

  AppSettings copyWith({
    AppLanguage? language,
    AppThemePreference? theme,
    bool? reduceMotion,
    String? signLanguage,
    DailyGoal? dailyGoal,
    DominantHand? dominantHand,
    bool? analyticsConsent,
    bool? crashReportsConsent,
    bool? onboardingComplete,
    int? Function()? reminderMinutes,
  }) => AppSettings(
    language: language ?? this.language,
    theme: theme ?? this.theme,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    signLanguage: signLanguage ?? this.signLanguage,
    dailyGoal: dailyGoal ?? this.dailyGoal,
    dominantHand: dominantHand ?? this.dominantHand,
    analyticsConsent: analyticsConsent ?? this.analyticsConsent,
    crashReportsConsent: crashReportsConsent ?? this.crashReportsConsent,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    reminderMinutes: reminderMinutes == null
        ? this.reminderMinutes
        : reminderMinutes(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          other.language == language &&
          other.theme == theme &&
          other.reduceMotion == reduceMotion &&
          other.signLanguage == signLanguage &&
          other.dailyGoal == dailyGoal &&
          other.dominantHand == dominantHand &&
          other.analyticsConsent == analyticsConsent &&
          other.crashReportsConsent == crashReportsConsent &&
          other.onboardingComplete == onboardingComplete &&
          other.reminderMinutes == reminderMinutes;

  @override
  int get hashCode => Object.hash(
    language,
    theme,
    reduceMotion,
    signLanguage,
    dailyGoal,
    dominantHand,
    analyticsConsent,
    crashReportsConsent,
    onboardingComplete,
    reminderMinutes,
  );

  @override
  String toString() =>
      'AppSettings(language: ${language.name}, theme: ${theme.name}, '
      'reduceMotion: $reduceMotion, signLanguage: $signLanguage, '
      'dailyGoal: ${dailyGoal.minutes}, hand: ${dominantHand.name}, '
      'analytics: $analyticsConsent, crashReports: $crashReportsConsent, '
      'onboardingComplete: $onboardingComplete, reminder: $reminderMinutes)';
}
