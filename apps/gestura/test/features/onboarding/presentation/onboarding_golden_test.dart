import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:gestura/features/onboarding/presentation/view_models/onboarding_state.dart';
import 'package:gestura/features/onboarding/presentation/widgets/onboarding_view.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';

import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/golden_scenario.dart';

const AppSettings _englishLight = AppSettings(
  language: AppLanguage.english,
  theme: AppThemePreference.light,
  reduceMotion: true,
);
const AppSettings _arabicDark = AppSettings(
  language: AppLanguage.arabic,
  theme: AppThemePreference.dark,
  reduceMotion: true,
  dominantHand: DominantHand.left,
);

void _ignore() {}

void _ignoreValue(Object? _) {}

const OnboardingActions _actions = (
  onBack: _ignore,
  onSkip: _ignore,
  onContinue: _ignore,
  onRetryPacks: _ignore,
  onLanguageTap: _ignore,
  onSignLanguageChanged: _ignoreValue,
  onDailyGoalChanged: _ignoreValue,
  onHandChanged: _ignoreValue,
  onReduceMotionChanged: _ignoreValue,
  onAnalyticsChanged: _ignoreValue,
  onCrashReportsChanged: _ignoreValue,
  onOpenPrivacyPolicy: _ignore,
);

void main() {
  unawaited(
    goldenTest(
      'The five onboarding steps in English and Arabic',
      fileName: 'onboarding_steps',
      builder: () => GoldenTestGroup(
        columns: 5,
        children: [
          for (final settings in [_englishLight, _arabicDark])
            for (final step in OnboardingStep.values)
              viewScenario(
                name: '${step.name} ${settings.language.code}',
                settings: settings,
                child: MediaQuery.withNoTextScaling(
                  child: Builder(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(disableAnimations: true),
                      child: Scaffold(
                        body: SafeArea(
                          child: OnboardingView(
                            state: OnboardingState(
                              step: step,
                              packs: PacksReady([demoCatalog.pack]),
                            ),
                            settings: settings,
                            actions: _actions,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}
