import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

void main() {
  group('GesturaColors', () {
    const light = GesturaColors.light;
    const dark = GesturaColors.dark;

    test('copyWith with no arguments keeps every color', () {
      final copy = light.copyWith();

      expect(copy.coralStrong, light.coralStrong);
      expect(copy.success, light.success);
      expect(copy.onSuccess, light.onSuccess);
      expect(copy.successContainer, light.successContainer);
      expect(copy.onSuccessContainer, light.onSuccessContainer);
      expect(copy.warning, light.warning);
      expect(copy.onWarning, light.onWarning);
      expect(copy.warningContainer, light.warningContainer);
      expect(copy.onWarningContainer, light.onWarningContainer);
      expect(copy.stage, light.stage);
      expect(copy.onStage, light.onStage);
      expect(copy.heroStart, light.heroStart);
      expect(copy.heroEnd, light.heroEnd);
      expect(copy.onHero, light.onHero);
    });

    test('copyWith replaces only the given colors', () {
      final copy = light.copyWith(
        coralStrong: dark.coralStrong,
        success: dark.success,
        onSuccess: dark.onSuccess,
        successContainer: dark.successContainer,
        onSuccessContainer: dark.onSuccessContainer,
        warning: dark.warning,
        onWarning: dark.onWarning,
        warningContainer: dark.warningContainer,
        onWarningContainer: dark.onWarningContainer,
        stage: dark.stage,
        onStage: dark.onStage,
        heroStart: dark.heroStart,
        heroEnd: dark.heroEnd,
        onHero: dark.onHero,
      );

      expect(copy.lerp(dark, 0).stage, dark.stage);
      expect(copy.coralStrong, dark.coralStrong);
      expect(copy.onHero, dark.onHero);
      expect(light.copyWith(stage: dark.stage).success, light.success);
    });

    test('lerp returns each end at 0 and 1', () {
      final start = light.lerp(dark, 0);
      final end = light.lerp(dark, 1);

      expect(start.coralStrong, light.coralStrong);
      expect(start.onHero, light.onHero);
      expect(end.coralStrong, dark.coralStrong);
      expect(end.warningContainer, dark.warningContainer);
      expect(end.onHero, dark.onHero);
    });

    test('lerp with null keeps the current colors', () {
      expect(light.lerp(null, 0.5), same(light));
    });

    test(
      'hero gradient runs from heroStart to heroEnd along the start edge',
      () {
        final gradient = light.heroGradient;

        expect(gradient.colors, [light.heroStart, light.heroEnd]);
        expect(gradient.begin, AlignmentDirectional.topStart);
        expect(gradient.end, AlignmentDirectional.bottomEnd);
      },
    );
  });

  group('GesturaTextStyles', () {
    const standard = GesturaTextStyles.standard;

    test('copyWith replaces the gloss style', () {
      const replacement = TextStyle(fontSize: 18);

      expect(standard.copyWith(gloss: replacement).gloss, replacement);
      expect(standard.copyWith().gloss, standard.gloss);
    });

    test('lerp blends the gloss style', () {
      final other = standard.copyWith(
        gloss: standard.gloss.copyWith(fontSize: 18),
      );

      expect(standard.lerp(other, 1).gloss.fontSize, 18);
      expect(standard.lerp(null, 0.5), same(standard));
    });
  });

  group('GesturaThemeContext', () {
    Future<(GesturaColors, GesturaTextStyles)> read(
      WidgetTester tester,
      ThemeData theme,
    ) async {
      late GesturaColors colors;
      late GesturaTextStyles styles;
      await tester.pumpWidget(
        Theme(
          data: theme,
          child: Builder(
            builder: (context) {
              colors = context.gColors;
              styles = context.gTextStyles;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return (colors, styles);
    }

    testWidgets('reads the extensions from a Gestura theme', (tester) async {
      final (colors, styles) = await read(tester, GesturaTheme.dark());

      expect(colors, GesturaColors.dark);
      expect(styles.gloss.color, GesturaColorSchemes.dark.onSurface);
    });

    testWidgets('falls back by brightness on a foreign theme', (tester) async {
      final (lightColors, styles) = await read(tester, ThemeData());
      final (darkColors, _) = await read(
        tester,
        ThemeData(brightness: Brightness.dark),
      );

      expect(lightColors, GesturaColors.light);
      expect(darkColors, GesturaColors.dark);
      expect(styles, GesturaTextStyles.standard);
    });
  });
}
