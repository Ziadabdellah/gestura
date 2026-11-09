import 'package:flutter/material.dart';
import 'package:gestura_ui/src/theme/gestura_theme_context.dart';

enum GCardTone {
  lowest,
  low,
  container,
  high;

  Color resolve(ColorScheme scheme) => switch (this) {
    lowest => scheme.surfaceContainerLowest,
    low => scheme.surfaceContainerLow,
    container => scheme.surfaceContainer,
    high => scheme.surfaceContainerHigh,
  };
}

class GCard extends StatelessWidget {
  const new({
    required this.child,
    super.key,
    this.onTap,
    this.semanticLabel,
    this.tone = GCardTone.lowest,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final GCardTone tone;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sizes = context.gSizes;
    final body = Padding(
      padding: padding ?? EdgeInsetsDirectional.all(sizes.md),
      child: child,
    );
    final tap = onTap;

    return Semantics(
      container: true,
      button: tap != null,
      label: semanticLabel,
      child: Card(
        color: tone.resolve(scheme),
        child: tap == null
            ? body
            : InkWell(
                onTap: tap,
                borderRadius: BorderRadius.circular(sizes.radiusLg),
                child: body,
              ),
      ),
    );
  }
}
