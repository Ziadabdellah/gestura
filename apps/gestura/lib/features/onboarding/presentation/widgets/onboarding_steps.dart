import 'package:flutter/material.dart';
import 'package:gestura/core/widgets/failure_view.dart';
import 'package:gestura/core/widgets/placeholder_content_notice.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/features/onboarding/presentation/view_models/onboarding_state.dart';
import 'package:gestura/features/onboarding/presentation/widgets/onboarding_option_tile.dart';
import 'package:gestura/features/onboarding/presentation/widgets/waving_hand.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/presentation/settings_presentation.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class WelcomeStep extends StatelessWidget {
  const new({required this.language, required this.onLanguageTap, super.key});

  final AppLanguage language;
  final VoidCallback onLanguageTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    return Column(
      children: [
        SizedBox(height: sizes.xl),
        const WavingHand(),
        SizedBox(height: sizes.lg),
        Semantics(
          header: true,
          child: Text(
            l10n.appTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall,
          ),
        ),
        SizedBox(height: sizes.xs),
        Text(
          l10n.tagline,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: sizes.xl),
        ListTile(
          tileColor: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sizes.radiusLg),
          ),
          leading: const ExcludeSemantics(child: Icon(Icons.language_rounded)),
          title: Text(l10n.settingsLanguage),
          subtitle: Text(language.label(l10n)),
          trailing: const ExcludeSemantics(child: Icon(Icons.chevron_right)),
          onTap: onLanguageTap,
        ),
      ],
    );
  }
}

class SignLanguageStep extends StatelessWidget {
  const new({
    required this.packs,
    required this.selected,
    required this.onSelected,
    required this.onRetry,
    super.key,
  });

  static const double skeletonHeight = 72;

  final PacksStatus packs;
  final String? selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingHeading(
          title: l10n.signLanguageTitle,
          subtitle: l10n.signLanguageSubtitle,
        ),
        switch (packs) {
          PacksLoading() => Semantics(
            container: true,
            label: l10n.loading,
            child: GSkeleton(
              height: sizes.scaled(skeletonHeight),
              borderRadius: sizes.radiusLg,
            ),
          ),
          PacksFailed(:final failure) => FailureView(
            failure: failure,
            onRetry: onRetry,
          ),
          PacksReady(:final packs) when packs.isEmpty => Text(
            l10n.packsComingSoon,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          PacksReady(:final packs) => RadioGroup<String>(
            groupValue: selected,
            onChanged: (code) {
              if (code != null) onSelected(code);
            },
            child: Column(
              children: [
                for (final pack in packs)
                  OnboardingRadioTile(
                    value: pack.code,
                    title: pack.name.of(context),
                    icon: const ExcludeSemantics(
                      child: Icon(Icons.sign_language_rounded),
                    ),
                  ),
                if (packs.any((pack) => pack.isPlaceholder))
                  const PlaceholderContentNotice(),
              ],
            ),
          ),
        },
      ],
    );
  }
}

class DailyGoalStep extends StatelessWidget {
  const new({required this.goal, required this.onChanged, super.key});

  final DailyGoal goal;
  final ValueChanged<DailyGoal> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingHeading(
          title: l10n.dailyGoalTitle,
          subtitle: l10n.dailyGoalSubtitle,
        ),
        RadioGroup<DailyGoal>(
          groupValue: goal,
          onChanged: (goal) {
            if (goal != null) onChanged(goal);
          },
          child: Column(
            children: [
              for (final option in DailyGoal.values)
                OnboardingRadioTile(
                  value: option,
                  title: option.label(l10n),
                  subtitle: option.description(l10n),
                  icon: const ExcludeSemantics(
                    child: Icon(Icons.timer_outlined),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class HandStep extends StatelessWidget {
  const new({
    required this.hand,
    required this.reduceMotion,
    required this.onHandChanged,
    required this.onReduceMotionChanged,
    super.key,
  });

  final DominantHand hand;
  final bool reduceMotion;
  final ValueChanged<DominantHand> onHandChanged;
  final ValueChanged<bool> onReduceMotionChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingHeading(title: l10n.handTitle, subtitle: l10n.handSubtitle),
        RadioGroup<DominantHand>(
          groupValue: hand,
          onChanged: (hand) {
            if (hand != null) onHandChanged(hand);
          },
          child: Column(
            children: [
              for (final option in DominantHand.values)
                OnboardingRadioTile(
                  value: option,
                  title: option.label(l10n),
                  icon: ExcludeSemantics(
                    child: Transform.flip(
                      flipX: option == DominantHand.left,
                      child: const Icon(Icons.back_hand_outlined),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: sizes.sm),
        OnboardingSwitchTile(
          value: reduceMotion,
          onChanged: onReduceMotionChanged,
          title: l10n.reduceMotionTitle,
          subtitle: l10n.reduceMotionSubtitle,
        ),
      ],
    );
  }
}

class PrivacyStep extends StatelessWidget {
  const new({
    required this.analytics,
    required this.crashReports,
    required this.onAnalyticsChanged,
    required this.onCrashReportsChanged,
    required this.onOpenPrivacyPolicy,
    super.key,
  });

  final bool analytics;
  final bool crashReports;
  final ValueChanged<bool> onAnalyticsChanged;
  final ValueChanged<bool> onCrashReportsChanged;
  final VoidCallback onOpenPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingHeading(
          title: l10n.privacyTitle,
          subtitle: l10n.privacySubtitle,
        ),
        OnboardingSwitchTile(
          value: analytics,
          onChanged: onAnalyticsChanged,
          title: l10n.analyticsTitle,
          subtitle: l10n.analyticsSubtitle,
        ),
        OnboardingSwitchTile(
          value: crashReports,
          onChanged: onCrashReportsChanged,
          title: l10n.crashReportsTitle,
          subtitle: l10n.crashReportsSubtitle,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: onOpenPrivacyPolicy,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(l10n.privacyPolicy),
          ),
        ),
      ],
    );
  }
}
