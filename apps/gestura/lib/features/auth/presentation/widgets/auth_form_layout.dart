import 'package:flutter/material.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura_ui/gestura_ui.dart';

class AuthFormLayout extends StatelessWidget {
  const new({
    required this.title,
    required this.children,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    final text = subtitle;
    return SafeArea(
      top: false,
      child: ReadableInset(
        minimum: context.windowSizeClass.screenPadding,
        builder: (context, inset) => ListView(
          padding: EdgeInsetsDirectional.fromSTEB(
            inset,
            sizes.md,
            inset,
            sizes.xl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.headlineSmall),
            ),
            if (text != null) ...[
              SizedBox(height: sizes.xs),
              Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            SizedBox(height: sizes.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}
