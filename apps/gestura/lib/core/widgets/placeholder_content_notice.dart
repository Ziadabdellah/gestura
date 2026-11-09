import 'package:flutter/material.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class PlaceholderContentNotice extends StatelessWidget {
  const new({super.key});

  static const double iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sizes = context.gSizes;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
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
                Icons.science_outlined,
                size: sizes.icon(iconSize),
                color: scheme.onSecondaryContainer,
              ),
            ),
            SizedBox(width: sizes.sm),
            Expanded(
              child: Text(
                context.l10n.placeholderContentNotice,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
