import 'package:flutter/material.dart';
import 'package:gestura_ui/gestura_ui.dart';

class SettingsSectionHeader extends StatelessWidget {
  const new({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        context.windowSizeClass.screenPadding,
        sizes.lg,
        context.windowSizeClass.screenPadding,
        sizes.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
