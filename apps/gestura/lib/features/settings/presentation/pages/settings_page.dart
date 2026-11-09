import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        ),
      ),
    );
  }
}
