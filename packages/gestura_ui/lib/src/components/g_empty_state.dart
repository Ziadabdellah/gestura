import 'package:flutter/material.dart';
import 'package:gestura_ui/src/theme/gestura_theme_context.dart';

class GEmptyState extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sizes = context.gSizes;
    final button = action;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.all(sizes.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: sizes.scaled(360)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(sizes.radiusXl),
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.all(sizes.lg),
                    child: Icon(
                      icon,
                      size: sizes.icon(40),
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
              SizedBox(height: sizes.lg),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: sizes.xs),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (button != null) ...[SizedBox(height: sizes.lg), button],
            ],
          ),
        ),
      ),
    );
  }
}
