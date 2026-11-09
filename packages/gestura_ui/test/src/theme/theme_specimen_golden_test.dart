import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../helpers/gestura_test_scope.dart';
import '../../helpers/sample_text.dart';

const List<Locale> _scripts = [Locale('en'), Locale('ar'), Locale('ru')];
const List<Brightness> _modes = [Brightness.light, Brightness.dark];

void main() {
  unawaited(
    goldenTest(
      'Type scale in Latin, Arabic and Cyrillic',
      fileName: 'typography',
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          for (final locale in _scripts)
            for (final brightness in _modes)
              GoldenTestScenario(
                name: '${locale.languageCode} ${brightness.name}',
                child: GesturaTestScope(
                  locale: locale,
                  brightness: brightness,
                  child: _TypeSpecimen(text: sampleTextFor(locale)),
                ),
              ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'Color palette',
      fileName: 'palette',
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          for (final brightness in _modes)
            GoldenTestScenario(
              name: brightness.name,
              child: GesturaTestScope(
                brightness: brightness,
                child: const _PaletteSpecimen(),
              ),
            ),
        ],
      ),
    ),
  );
}

class _TypeSpecimen extends StatelessWidget {
  const new({required this.text});

  final SampleText text;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('12', style: styles.displaySmall),
        Text(text.cardTitle, style: styles.headlineMedium),
        Text(text.errorTitle, style: styles.titleLarge),
        Text(text.tagline, style: styles.bodyLarge),
        Text(text.errorMessage, style: styles.bodyMedium),
        Text(text.primary, style: styles.labelLarge),
        Text(text.gloss, style: context.gTextStyles.gloss),
      ],
    );
  }
}

class _PaletteSpecimen extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final g = context.gColors;
    final swatches = <(String, Color, Color)>[
      ('primary', s.primary, s.onPrimary),
      ('primaryContainer', s.primaryContainer, s.onPrimaryContainer),
      ('secondary', s.secondary, s.onSecondary),
      ('secondaryContainer', s.secondaryContainer, s.onSecondaryContainer),
      ('tertiary', s.tertiary, s.onTertiary),
      ('tertiaryContainer', s.tertiaryContainer, s.onTertiaryContainer),
      ('error', s.error, s.onError),
      ('success', g.success, g.onSuccess),
      ('successContainer', g.successContainer, g.onSuccessContainer),
      ('warning', g.warning, g.onWarning),
      ('warningContainer', g.warningContainer, g.onWarningContainer),
      ('stage', g.stage, g.onStage),
      ('surfaceContainerLowest', s.surfaceContainerLowest, s.onSurface),
      ('surfaceContainer', s.surfaceContainer, s.onSurface),
      ('surfaceContainerHighest', s.surfaceContainerHighest, s.onSurface),
      ('inverseSurface', s.inverseSurface, s.onInverseSurface),
    ];
    final labelStyle = Theme.of(context).textTheme.labelMedium;

    return Column(
      children: [
        Container(
          height: 56,
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: GesturaSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: g.heroGradient,
            borderRadius: BorderRadius.circular(GesturaRadius.lg),
          ),
          child: Text('hero', style: labelStyle?.copyWith(color: g.onHero)),
        ),
        const SizedBox(height: GesturaSpacing.xs),
        for (final (name, background, foreground) in swatches)
          Container(
            height: 32,
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: GesturaSpacing.sm,
            ),
            color: background,
            child: Text(name, style: labelStyle?.copyWith(color: foreground)),
          ),
      ],
    );
  }
}
