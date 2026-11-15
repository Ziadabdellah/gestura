import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/reminders/domain/reminders.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:gestura/l10n/l10n.dart';

ReminderText reminderTextOf(AppLocalizations l10n) => (
  title: l10n.reminderTitle,
  body: l10n.reminderBody,
  channel: l10n.settingsReminder,
);

class ReminderKeeper extends ConsumerStatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ReminderKeeper> createState() => _ReminderKeeperState();
}

class _ReminderKeeperState extends ConsumerState<ReminderKeeper> {
  (int?, String)? _applied;

  @override
  Widget build(BuildContext context) {
    final minutes = ref.watch(
      settingsViewModelProvider.select(
        (state) => state.settings.reminderMinutes,
      ),
    );
    final l10n = context.l10n;
    final wanted = (minutes, l10n.localeName);
    if (wanted != _applied && (minutes != null || _applied != null)) {
      _applied = wanted;
      final reminders = getIt<Reminders>();
      unawaited(
        minutes == null
            ? reminders.cancel()
            : reminders.scheduleDaily(minutes, reminderTextOf(l10n)),
      );
    }
    return widget.child;
  }
}
