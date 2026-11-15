import 'package:flutter/material.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class OnboardingProgress extends StatelessWidget {
  const new({required this.current, required this.total, super.key});

  static const double dotSize = 8;
  static const double activeWidth = 24;

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final sizes = context.gSizes;
    final scheme = Theme.of(context).colorScheme;
    final duration = GesturaMotion.adaptive(context, GesturaMotion.medium);

    return Semantics(
      label: context.l10n.onboardingProgress(current, total),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var step = 1; step <= total; step++)
              AnimatedContainer(
                duration: duration,
                curve: GesturaMotion.enter,
                margin: EdgeInsetsDirectional.symmetric(horizontal: sizes.xxs),
                width: sizes.scaled(step == current ? activeWidth : dotSize),
                height: sizes.scaled(dotSize),
                decoration: BoxDecoration(
                  color: step <= current
                      ? scheme.primary
                      : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(sizes.scaled(dotSize)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
