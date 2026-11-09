import 'package:flutter/material.dart';
import 'package:gestura_ui/src/components/g_button.dart';
import 'package:gestura_ui/src/theme/gestura_theme_context.dart';

typedef GErrorAction = ({String label, VoidCallback onPressed});

class GErrorView extends StatelessWidget {
  const new({
    required this.title,
    required this.message,
    super.key,
    this.action,
    this.icon = Icons.cloud_off_rounded,
  });

  final String title;
  final String message;
  final GErrorAction? action;
  final IconData icon;

  static const double maxContentWidth = 360;
  static const double iconSize = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final retry = action;
    final sizes = context.gSizes;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.all(sizes.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: sizes.scaled(maxContentWidth)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  icon,
                  size: sizes.icon(iconSize),
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: sizes.md),
              Semantics(
                liveRegion: true,
                child: Column(
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge,
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
                  ],
                ),
              ),
              if (retry != null) ...[
                SizedBox(height: sizes.lg),
                GButton(
                  label: retry.label,
                  onPressed: retry.onPressed,
                  icon: Icons.refresh_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
