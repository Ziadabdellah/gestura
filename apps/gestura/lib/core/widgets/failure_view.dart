import 'package:flutter/material.dart';
import 'package:gestura/core/errors/failure_presentation.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:gestura_ui/gestura_ui.dart';

class FailureView extends StatelessWidget {
  const new({required this.failure, required this.onRetry, super.key});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GErrorView(
      title: l10n.errorTitle,
      message: failure.message(l10n),
      icon: failure.icon,
      action: (label: l10n.retry, onPressed: onRetry),
    );
  }
}
