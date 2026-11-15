import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestura/core/links/legal_links.dart';
import 'package:gestura/core/links/open_link.dart';
import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/onboarding/presentation/view_models/onboarding_state.dart';
import 'package:gestura/features/onboarding/presentation/view_models/onboarding_view_model.dart';
import 'package:gestura/features/onboarding/presentation/widgets/onboarding_view.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:gestura/features/settings/presentation/widgets/language_sheet.dart';

class OnboardingPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => BlocProvider(
    create: (_) {
      final viewModel = OnboardingViewModel(getIt<ContentRepository>());
      unawaited(viewModel.loadPacks());
      return viewModel;
    },
    child: BlocBuilder<OnboardingViewModel, OnboardingState>(
      builder: (context, state) {
        final viewModel = context.read<OnboardingViewModel>();
        final settings = ref.watch(
          settingsViewModelProvider.select((state) => state.settings),
        );
        final preferences = ref.read(settingsViewModelProvider.notifier);

        Future<void> onContinue() async {
          switch (state.step) {
            case OnboardingStep.signLanguage:
              if (state.packCodeFor(settings.signLanguage)
                  case final String code) {
                await preferences.setSignLanguage(code);
              }
              viewModel.next();
            case OnboardingStep.privacy:
              await preferences.completeOnboarding();
              await getIt<Telemetry>().record(
                OnboardingCompleted(
                  dailyGoalMinutes: settings.dailyGoal.minutes,
                  leftHanded: settings.dominantHand.mirrorsVideo,
                ),
              );
            case OnboardingStep.welcome ||
                OnboardingStep.dailyGoal ||
                OnboardingStep.hand:
              viewModel.next();
          }
        }

        Future<void> onLanguageTap() async {
          final language = await showLanguageSheet(
            context,
            current: settings.language,
          );
          if (language != null) await preferences.setLanguage(language);
        }

        return PopScope(
          canPop: state.isFirst,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) viewModel.back();
          },
          child: Scaffold(
            body: SafeArea(
              child: OnboardingView(
                state: state,
                settings: settings,
                actions: (
                  onBack: viewModel.back,
                  onSkip: viewModel.skip,
                  onContinue: () => unawaited(onContinue()),
                  onRetryPacks: () => unawaited(viewModel.loadPacks()),
                  onLanguageTap: () => unawaited(onLanguageTap()),
                  onSignLanguageChanged: (code) =>
                      unawaited(preferences.setSignLanguage(code)),
                  onDailyGoalChanged: (goal) =>
                      unawaited(preferences.setDailyGoal(goal)),
                  onHandChanged: (hand) =>
                      unawaited(preferences.setDominantHand(hand)),
                  onReduceMotionChanged: (enabled) =>
                      unawaited(preferences.setReduceMotion(enabled: enabled)),
                  onAnalyticsChanged: (granted) => unawaited(
                    preferences.setAnalyticsConsent(granted: granted),
                  ),
                  onCrashReportsChanged: (granted) => unawaited(
                    preferences.setCrashReportsConsent(granted: granted),
                  ),
                  onOpenPrivacyPolicy: () => unawaited(
                    openLink(
                      context,
                      LegalLinks.privacyPolicy(
                        Localizations.localeOf(context).languageCode,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
