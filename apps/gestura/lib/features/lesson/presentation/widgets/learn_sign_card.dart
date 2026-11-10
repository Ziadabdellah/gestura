import 'package:flutter/material.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class LearnSignCard extends StatelessWidget {
  const new({required this.sign, super.key});

  final Sign sign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sizes = context.gSizes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.newSignTitle,
          style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary),
        ),
        SizedBox(height: sizes.xs),
        Semantics(
          header: true,
          child: Text(
            sign.meaning.of(context),
            style: theme.textTheme.headlineSmall,
          ),
        ),
        SizedBox(height: sizes.xxs),
        Text(
          sign.gloss,
          style: context.gTextStyles.gloss.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: sizes.md),
        Text(
          l10n.signDescriptionPending,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
