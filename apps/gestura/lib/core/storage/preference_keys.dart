abstract final class PreferenceKeys {
  static const String language = 'settings.language';
  static const String theme = 'settings.theme';
  static const String reduceMotion = 'settings.reduceMotion';
  static const String signLanguage = 'settings.signLanguage';
  static const String dailyGoal = 'settings.dailyGoalMinutes';
  static const String dominantHand = 'settings.dominantHand';
  static const String analyticsConsent = 'privacy.analytics';
  static const String crashReportsConsent = 'privacy.crashReports';
  static const String onboardingComplete = 'onboarding.complete';

  static const Set<String> all = {
    language,
    theme,
    reduceMotion,
    signLanguage,
    dailyGoal,
    dominantHand,
    analyticsConsent,
    crashReportsConsent,
    onboardingComplete,
  };
}
