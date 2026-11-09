import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

typedef ContrastPair = ({
  String name,
  Color foreground,
  Color background,
  double minimum,
});

List<ContrastPair> pairsFor(ColorScheme s, GesturaColors g) {
  const text = WcagContrast.normalText;
  const ui = WcagContrast.largeTextOrUi;
  final surfaces = {
    'surface': s.surface,
    'surfaceContainerLowest': s.surfaceContainerLowest,
    'surfaceContainerLow': s.surfaceContainerLow,
    'surfaceContainer': s.surfaceContainer,
    'surfaceContainerHigh': s.surfaceContainerHigh,
    'surfaceContainerHighest': s.surfaceContainerHighest,
  };
  return [
    for (final MapEntry(key: name, value: surface) in surfaces.entries) ...[
      (
        name: 'onSurface on $name',
        foreground: s.onSurface,
        background: surface,
        minimum: text,
      ),
      (
        name: 'onSurfaceVariant on $name',
        foreground: s.onSurfaceVariant,
        background: surface,
        minimum: text,
      ),
    ],
    (
      name: 'outline on surface',
      foreground: s.outline,
      background: s.surface,
      minimum: ui,
    ),
    (
      name: 'onPrimary on primary',
      foreground: s.onPrimary,
      background: s.primary,
      minimum: text,
    ),
    (
      name: 'primary on surface',
      foreground: s.primary,
      background: s.surface,
      minimum: text,
    ),
    (
      name: 'onPrimaryContainer on primaryContainer',
      foreground: s.onPrimaryContainer,
      background: s.primaryContainer,
      minimum: text,
    ),
    (
      name: 'onSecondary on secondary',
      foreground: s.onSecondary,
      background: s.secondary,
      minimum: text,
    ),
    (
      name: 'secondary on surface',
      foreground: s.secondary,
      background: s.surface,
      minimum: ui,
    ),
    (
      name: 'onSecondaryContainer on secondaryContainer',
      foreground: s.onSecondaryContainer,
      background: s.secondaryContainer,
      minimum: text,
    ),
    (
      name: 'onTertiary on tertiary',
      foreground: s.onTertiary,
      background: s.tertiary,
      minimum: text,
    ),
    (
      name: 'onTertiaryContainer on tertiaryContainer',
      foreground: s.onTertiaryContainer,
      background: s.tertiaryContainer,
      minimum: text,
    ),
    (
      name: 'onError on error',
      foreground: s.onError,
      background: s.error,
      minimum: text,
    ),
    (
      name: 'onErrorContainer on errorContainer',
      foreground: s.onErrorContainer,
      background: s.errorContainer,
      minimum: text,
    ),
    (
      name: 'onInverseSurface on inverseSurface',
      foreground: s.onInverseSurface,
      background: s.inverseSurface,
      minimum: text,
    ),
    (
      name: 'inversePrimary on inverseSurface',
      foreground: s.inversePrimary,
      background: s.inverseSurface,
      minimum: text,
    ),
    (
      name: 'coralStrong on surface',
      foreground: g.coralStrong,
      background: s.surface,
      minimum: text,
    ),
    (
      name: 'onSuccess on success',
      foreground: g.onSuccess,
      background: g.success,
      minimum: text,
    ),
    (
      name: 'success on surface',
      foreground: g.success,
      background: s.surface,
      minimum: text,
    ),
    (
      name: 'onSuccessContainer on successContainer',
      foreground: g.onSuccessContainer,
      background: g.successContainer,
      minimum: text,
    ),
    (
      name: 'onWarning on warning',
      foreground: g.onWarning,
      background: g.warning,
      minimum: text,
    ),
    (
      name: 'warning on surface',
      foreground: g.warning,
      background: s.surface,
      minimum: text,
    ),
    (
      name: 'onWarningContainer on warningContainer',
      foreground: g.onWarningContainer,
      background: g.warningContainer,
      minimum: text,
    ),
    (
      name: 'onStage on stage',
      foreground: g.onStage,
      background: g.stage,
      minimum: text,
    ),
    (
      name: 'onHero on heroStart',
      foreground: g.onHero,
      background: g.heroStart,
      minimum: text,
    ),
    (
      name: 'onHero on heroEnd',
      foreground: g.onHero,
      background: g.heroEnd,
      minimum: text,
    ),
  ];
}

void main() {
  group('WcagContrast.ratio', () {
    test('is 21 for black on white in either order', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);

      expect(WcagContrast.ratio(black, white), closeTo(21, 0.01));
      expect(WcagContrast.ratio(white, black), closeTo(21, 0.01));
    });

    test('is 1 for identical colors', () {
      const lagoon = Color(0xFF0B6E69);

      expect(WcagContrast.ratio(lagoon, lagoon), 1);
    });
  });

  for (final (mode, scheme, colors) in [
    ('light', GesturaColorSchemes.light, GesturaColors.light),
    ('dark', GesturaColorSchemes.dark, GesturaColors.dark),
  ]) {
    group('$mode palette meets WCAG 2.2 AA', () {
      for (final pair in pairsFor(scheme, colors)) {
        test(pair.name, () {
          expect(
            WcagContrast.ratio(pair.foreground, pair.background),
            greaterThanOrEqualTo(pair.minimum),
          );
        });
      }
    });
  }
}
