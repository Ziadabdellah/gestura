import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestura/core/links/legal_links.dart';
import 'package:gestura/core/links/open_link.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/reminders/domain/reminders.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_state.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:gestura/features/settings/presentation/widgets/settings_view.dart';
import 'package:gestura/l10n/l10n.dart';

class SettingsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(settingsViewModelProvider, (previous, next) {
      if (next case SettingsSaveFailed() when next != previous) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(context.l10n.settingsSaveFailed)),
          );
      }
    });

    final settings = ref.watch(
      settingsViewModelProvider.select((state) => state.settings),
    );
    final viewModel = ref.read(settingsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: SafeArea(
        top: false,
        child: SettingsView(
          settings: settings,
          onThemeChanged: (theme) => unawaited(viewModel.setTheme(theme)),
          onLanguageChanged: (language) =>
              unawaited(viewModel.setLanguage(language)),
          onReduceMotionChanged: (enabled) =>
              unawaited(viewModel.setReduceMotion(enabled: enabled)),
          onDailyGoalChanged: (goal) => unawaited(viewModel.setDailyGoal(goal)),
          onReminderChanged: (enabled) =>
              unawaited(_changeReminder(context, viewModel, enabled: enabled)),
          onPickReminderTime: () => unawaited(
            _pickReminderTime(context, viewModel, settings.reminderMinutes!),
          ),
          onDominantHandChanged: (hand) =>
              unawaited(viewModel.setDominantHand(hand)),
          onAnalyticsChanged: (granted) =>
              unawaited(viewModel.setAnalyticsConsent(granted: granted)),
          onCrashReportsChanged: (granted) =>
              unawaited(viewModel.setCrashReportsConsent(granted: granted)),
          onOpenTerms: () => unawaited(
            openLink(
              context,
              LegalLinks.terms(Localizations.localeOf(context).languageCode),
            ),
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
    );
  }

  static Future<void> _changeReminder(
    BuildContext context,
    SettingsViewModel viewModel, {
    required bool enabled,
  }) async {
    if (!enabled) return await viewModel.setReminder(null);
    final granted = await getIt<Reminders>().requestPermission();
    if (!context.mounted) return;
    if (granted) {
      return await viewModel.setReminder(AppSettings.defaultReminderMinutes);
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.reminderPermissionDenied)),
      );
  }

  static Future<void> _pickReminderTime(
    BuildContext context,
    SettingsViewModel viewModel,
    int minutes,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTimeOf(minutes),
    );
    if (picked == null) return;
    await viewModel.setReminder(
      picked.hour * TimeOfDay.minutesPerHour + picked.minute,
    );
  }
}
