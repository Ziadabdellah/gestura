import 'package:flutter/material.dart';
import 'package:gestura_ui/src/theme/gestura_theme_context.dart';

class GHeroCard extends StatelessWidget {
  const new({
    required this.title,
    required this.subtitle,
    super.key,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.gColors;
    final sizes = context.gSizes;
    final radius = BorderRadius.circular(sizes.radiusXl);
    final start = leading;
    final end = trailing;

    return Semantics(
      container: true,
      button: onTap != null,
      child: Material(
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(gradient: colors.heroGradient),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsetsDirectional.all(sizes.lg),
              child: Row(
                children: [
                  if (start != null) ...[start, SizedBox(width: sizes.md)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.onHero,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: sizes.xxs),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onHero,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (end != null) ...[SizedBox(width: sizes.md), end],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
