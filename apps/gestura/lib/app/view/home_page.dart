import 'package:flutter/material.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class HomePage extends StatelessWidget {
  const new({super.key});

  static const double logoSize = 72;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.all(
              context.windowSizeClass.screenPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.waving_hand_rounded,
                    size: sizes.icon(logoSize),
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: sizes.lg),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.appTitle,
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: sizes.xs),
                Text(
                  l10n.tagline,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
