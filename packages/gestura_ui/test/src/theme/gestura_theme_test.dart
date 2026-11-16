import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

void main() {
  for (final (mode, build, scheme, colors) in [
    (
      'light',
      GesturaTheme.light,
      GesturaColorSchemes.light,
      GesturaColors.light,
    ),
    ('dark', GesturaTheme.dark, GesturaColorSchemes.dark, GesturaColors.dark),
  ]) {
    group('GesturaTheme.$mode', () {
      final theme = build();

      test('uses Material 3 with the fixed brand color scheme', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.colorScheme, scheme);
        expect(theme.scaffoldBackgroundColor, scheme.surface);
      });

      test('registers the brand theme extensions', () {
        expect(theme.extension<GesturaColors>(), colors);
        expect(theme.extension<GesturaTextStyles>(), isNotNull);
      });

      test('uses the bundled fonts with a Cyrillic fallback', () {
        final style = theme.textTheme.bodyLarge!;

        expect(style.fontFamily, GesturaFonts.family);
        expect(style.fontFamilyFallback, GesturaFonts.fallback);
      });

      test('follows the type scale', () {
        final t = theme.textTheme;
        final scale = {
          'displaySmall': (t.displaySmall!, 34.0, 42.0, FontWeight.w700),
          'headlineMedium': (t.headlineMedium!, 28.0, 36.0, FontWeight.w700),
          'headlineSmall': (t.headlineSmall!, 24.0, 32.0, FontWeight.w600),
          'titleLarge': (t.titleLarge!, 20.0, 28.0, FontWeight.w600),
          'titleMedium': (t.titleMedium!, 16.0, 24.0, FontWeight.w600),
          'bodyLarge': (t.bodyLarge!, 16.0, 24.0, FontWeight.w400),
          'bodyMedium': (t.bodyMedium!, 14.0, 20.0, FontWeight.w400),
          'labelLarge': (t.labelLarge!, 14.0, 20.0, FontWeight.w600),
          'labelMedium': (t.labelMedium!, 12.0, 16.0, FontWeight.w600),
        };

        for (final MapEntry(key: name, value: (style, size, line, weight))
            in scale.entries) {
          expect(style.fontSize, size, reason: name);
          expect(style.fontSize! * style.height!, closeTo(line, 0.01));
          expect(style.fontWeight, weight, reason: name);
        }
      });

      test('keeps body text tall enough for Arabic', () {
        final t = theme.textTheme;
        for (final style in [t.bodyLarge!, t.bodyMedium!, t.bodySmall!]) {
          expect(style.height, greaterThanOrEqualTo(1.4));
        }
      });

      test('colors text with the ink color', () {
        expect(theme.textTheme.bodyLarge!.color, scheme.onSurface);
      });

      test('gives the gloss style its own spacing and color', () {
        final gloss = theme.extension<GesturaTextStyles>()!.gloss;

        expect(gloss.fontSize, 14);
        expect(gloss.fontWeight, FontWeight.w700);
        expect(gloss.letterSpacing, 1.2);
        expect(gloss.color, scheme.onSurface);
        expect(gloss.fontFamily, GesturaFonts.family);
      });

      test('shapes buttons as pills with 48dp or larger targets', () {
        final filled = theme.filledButtonTheme.style!;
        final text = theme.textButtonTheme.style!;

        expect(filled.shape!.resolve({}), isA<StadiumBorder>());
        expect(filled.minimumSize!.resolve({}), GesturaTheme.buttonMinimumSize);
        expect(text.minimumSize!.resolve({})!.height, 48);
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      });

      test('uses tonal cards with 24 radius and no elevation', () {
        final card = theme.cardTheme;
        final shape = card.shape! as RoundedRectangleBorder;

        expect(card.elevation, 0);
        expect(card.color, scheme.surfaceContainerLow);
        expect(shape.borderRadius, BorderRadius.circular(24));
      });

      test('rounds only the top of bottom sheets with 32', () {
        final shape = theme.bottomSheetTheme.shape! as RoundedRectangleBorder;

        expect(
          shape.borderRadius,
          const BorderRadius.vertical(top: Radius.circular(32)),
        );
      });

      test('fills chips by selection state', () {
        final color = theme.chipTheme.color!;

        expect(color.resolve({WidgetState.selected}), scheme.primaryContainer);
        expect(color.resolve({}), scheme.surfaceContainerHigh);
        expect(color.resolve({WidgetState.disabled}), isNot(scheme.surface));
      });

      test('styles chip labels with the label font and state colors', () {
        final label = theme.chipTheme.labelStyle!;
        Color? colorFor(Set<WidgetState> states) =>
            WidgetStateProperty.resolveAs<Color?>(label.color, states);

        expect(label.fontFamily, GesturaFonts.family);
        expect(label.fontSize, 12);
        expect(label.fontWeight, FontWeight.w600);
        expect(colorFor({WidgetState.selected}), scheme.onPrimaryContainer);
        expect(colorFor({}), scheme.onSurface);
        expect(colorFor({WidgetState.disabled}), isNot(scheme.onSurface));
      });
    });
  }
}
