import 'package:flutter/material.dart';
import 'package:gestura/core/errors/failure_presentation.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:gestura_ui/gestura_ui.dart';

enum AuthMessageTone { error, success }

class AuthMessage extends StatelessWidget {
  const new({required this.text, required this.tone, super.key});

  factory failure(Failure failure, {required AppLocalizations l10n}) =>
      AuthMessage(text: failure.message(l10n), tone: AuthMessageTone.error);

  static const double iconSize = 20;

  final String text;
  final AuthMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.gColors;
    final sizes = context.gSizes;
    final (background, foreground, icon) = switch (tone) {
      AuthMessageTone.error => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
        Icons.error_outline_rounded,
      ),
      AuthMessageTone.success => (
        colors.successContainer,
        colors.onSuccessContainer,
        Icons.check_circle_outline_rounded,
      ),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(sizes.radiusMd),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: sizes.md,
            vertical: sizes.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  icon,
                  size: sizes.icon(iconSize),
                  color: foreground,
                ),
              ),
              SizedBox(width: sizes.sm),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
