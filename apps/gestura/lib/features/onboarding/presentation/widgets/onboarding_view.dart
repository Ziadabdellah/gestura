import 'package:flutter/material.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/onboarding/presentation/view_models/onboarding_state.dart';
import 'package:gestura/features/onboarding/presentation/widgets/onboarding_progress.dart';
import 'package:gestura/features/onboarding/presentation/widgets/onboarding_steps.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

typedef OnboardingActions = ({
  VoidCallback onBack,
  VoidCallback onSkip,
  VoidCallback onContinue,
  VoidCallback onRetryPacks,
  VoidCallback onLanguageTap,
  ValueChanged<String> onSignLanguageChanged,
  ValueChanged<DailyGoal> onDailyGoalChanged,
  ValueChanged<DominantHand> onHandChanged,
  ValueChanged<bool> onReduceMotionChanged,
  ValueChanged<bool> onAnalyticsChanged,
  ValueChanged<bool> onCrashReportsChanged,
  VoidCallback onOpenPrivacyPolicy,
});

class OnboardingView extends StatelessWidget {
  const new({
    required this.state,
    required this.settings,
    required this.actions,
    super.key,
  });

  final OnboardingState state;
  final AppSettings settings;
  final OnboardingActions actions;

  Widget _step() => switch (state.step) {
    OnboardingStep.welcome => WelcomeStep(
      language: settings.language,
      onLanguageTap: actions.onLanguageTap,
    ),
    OnboardingStep.signLanguage => SignLanguageStep(
      packs: state.packs,
      selected: state.packCodeFor(settings.signLanguage),
      onSelected: actions.onSignLanguageChanged,
      onRetry: actions.onRetryPacks,
    ),
    OnboardingStep.dailyGoal => DailyGoalStep(
      goal: settings.dailyGoal,
      onChanged: actions.onDailyGoalChanged,
    ),
    OnboardingStep.hand => HandStep(
      hand: settings.dominantHand,
      reduceMotion: settings.reduceMotion,
      onHandChanged: actions.onHandChanged,
      onReduceMotionChanged: actions.onReduceMotionChanged,
    ),
    OnboardingStep.privacy => PrivacyStep(
      analytics: settings.analyticsConsent,
      crashReports: settings.crashReportsConsent,
      onAnalyticsChanged: actions.onAnalyticsChanged,
      onCrashReportsChanged: actions.onCrashReportsChanged,
      onOpenPrivacyPolicy: actions.onOpenPrivacyPolicy,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;
    final padding = context.windowSizeClass.screenPadding;

    return ReadableInset(
      builder: (context, inset) => Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: inset + sizes.xxs,
              vertical: sizes.xxs,
            ),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: sizes.tapTarget,
                  child: state.isFirst
                      ? null
                      : BackButton(onPressed: actions.onBack),
                ),
                Expanded(
                  child: Center(
                    child: OnboardingProgress(
                      current: state.stepNumber,
                      total: OnboardingState.stepCount,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: sizes.tapTarget),
                  child: state.step.canSkip
                      ? TextButton(
                          onPressed: actions.onSkip,
                          child: Text(l10n.skip),
                        )
                      : null,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              key: ValueKey(state.step),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: inset + padding,
                vertical: sizes.xs,
              ),
              children: [_step()],
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              inset + padding,
              sizes.xs,
              inset + padding,
              sizes.md,
            ),
            child: GButton(
              label: state.isFirst ? l10n.getStarted : l10n.continueAction,
              expand: true,
              onPressed: state.canContinue ? actions.onContinue : null,
            ),
          ),
        ],
      ),
    );
  }
}
