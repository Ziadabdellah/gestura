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

  group('DailyGoal', () {
    test('offers five, ten and fifteen minutes', () {
      expect(DailyGoal.values.map((goal) => goal.minutes), [5, 10, 15]);
    });

    test('reads a goal from its minutes and falls back to ten', () {
      for (final goal in DailyGoal.values) {
        expect(DailyGoal.fromMinutes(goal.minutes), goal);
      }
      expect(DailyGoal.fromMinutes(7), DailyGoal.ten);
      expect(DailyGoal.fromMinutes(null), DailyGoal.ten);
    });
  });

  group('DominantHand', () {
    test('reads a hand from its name and falls back to the right one', () {
      for (final hand in DominantHand.values) {
        expect(DominantHand.fromName(hand.name), hand);
      }
      expect(DominantHand.fromName('both'), DominantHand.right);
      expect(DominantHand.fromName(null), DominantHand.right);
    });

    test('mirrors videos for left-handed signers only', () {
      expect(DominantHand.left.mirrorsVideo, isTrue);
      expect(DominantHand.right.mirrorsVideo, isFalse);
    });
  });

  group('AppSettings', () {
    test('defaults to the device language and theme with motion on', () {
      expect(AppSettings.defaults.language, AppLanguage.system);
      expect(AppSettings.defaults.theme, AppThemePreference.system);
      expect(AppSettings.defaults.reduceMotion, isFalse);
    });

    test('keeps tracking and crash reports off until the learner agrees', () {
      expect(AppSettings.defaults.analyticsConsent, isFalse);
      expect(AppSettings.defaults.crashReportsConsent, isFalse);
      expect(AppSettings.defaults.onboardingComplete, isFalse);
      expect(AppSettings.defaults.signLanguage, isNull);
      expect(AppSettings.defaults.dailyGoal, DailyGoal.ten);
      expect(AppSettings.defaults.dominantHand, DominantHand.right);
    });

    test('copyWith replaces the onboarding choices one by one', () {
      const base = AppSettings.defaults;

      expect(base.copyWith(signLanguage: 'demo').signLanguage, 'demo');
      expect(
        base.copyWith(dailyGoal: DailyGoal.five).dailyGoal,
        DailyGoal.five,
      );
      expect(
        base.copyWith(dominantHand: DominantHand.left).dominantHand,
        DominantHand.left,
      );
      expect(base.copyWith(analyticsConsent: true).analyticsConsent, isTrue);
      expect(
        base.copyWith(crashReportsConsent: true).crashReportsConsent,
        isTrue,
      );
      expect(
        base.copyWith(onboardingComplete: true).onboardingComplete,
        isTrue,
      );
      final reminding = base.copyWith(reminderMinutes: () => 480);
      expect(reminding.reminderMinutes, 480);
      expect(reminding.remindsDaily, isTrue);
      expect(reminding.copyWith().reminderMinutes, 480);
      expect(
        reminding.copyWith(reminderMinutes: () => null).remindsDaily,
        false,
      );
      expect(reminding, isNot(base));
      expect(
        base.copyWith(signLanguage: 'demo').copyWith(),
        const AppSettings(signLanguage: 'demo'),
      );
    });

    test('tells settings apart by every field', () {
      const variants = [
        AppSettings(signLanguage: 'demo'),
        AppSettings(dailyGoal: DailyGoal.fifteen),
        AppSettings(dominantHand: DominantHand.left),
        AppSettings(analyticsConsent: true),
        AppSettings(crashReportsConsent: true),
        AppSettings(onboardingComplete: true),
      ];

      for (final variant in variants) {
        expect(variant, isNot(AppSettings.defaults));
      }
      expect(variants.toSet(), hasLength(variants.length));
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
        'AppSettings(language: system, theme: system, reduceMotion: false, '
        'signLanguage: null, dailyGoal: 10, hand: right, analytics: false, '
        'crashReports: false, onboardingComplete: false, reminder: null)',
      );
    });
  });
}
