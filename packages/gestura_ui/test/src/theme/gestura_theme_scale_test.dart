import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

void main() {
  group('GesturaTheme with a scale', () {
    const large = GesturaScale(text: 1.1, size: 1.1);
    const small = GesturaScale(size: 0.9);

    test('scales every text style by the text factor', () {
      final base = GesturaTheme.light().textTheme;
      final scaled = GesturaTheme.light(scale: large).textTheme;

      expect(scaled.bodyLarge!.fontSize, closeTo(17.6, 0.001));
      expect(scaled.displaySmall!.fontSize, closeTo(37.4, 0.001));
      expect(scaled.labelMedium!.fontSize, closeTo(13.2, 0.001));
      expect(scaled.bodyLarge!.height, base.bodyLarge!.height);
    });

    test('scales the gloss style and icons by the text factor', () {
      final theme = GesturaTheme.light(scale: large);

      expect(
        theme.extension<GesturaTextStyles>()!.gloss.fontSize,
        closeTo(15.4, 0.001),
      );
      expect(theme.iconTheme.size, closeTo(26.4, 0.001));
      expect(theme.chipTheme.iconTheme!.size, closeTo(19.8, 0.001));
    });

    test('registers the scaled sizes extension', () {
      expect(
        GesturaTheme.dark(scale: large).extension<GesturaSizes>(),
        const GesturaSizes(scale: large),
      );
    });

    test('scales component shapes by the size factor', () {
      final theme = GesturaTheme.light(scale: large);
      final card = theme.cardTheme.shape! as RoundedRectangleBorder;

      expect(card.borderRadius, BorderRadius.circular(22));
    });

    test('keeps every tap target at 48 or more on small phones', () {
      final theme = GesturaTheme.light(scale: small);
      final filled = theme.filledButtonTheme.style!.minimumSize!.resolve({})!;
      final text = theme.textButtonTheme.style!.minimumSize!.resolve({})!;
      final icon = theme.iconButtonTheme.style!.minimumSize!.resolve({})!;

      expect(filled.height, 48);
      expect(text.height, 48);
      expect(icon, const Size.square(48));
      expect(theme.listTileTheme.minTileHeight, greaterThanOrEqualTo(48));
    });

    test('never shrinks text on small phones', () {
      expect(
        GesturaTheme.light(scale: small).textTheme.bodyMedium!.fontSize,
        14,
      );
    });

    test('reuses the same theme for the same brightness and scale', () {
      expect(
        identical(
          GesturaTheme.light(scale: large),
          GesturaTheme.light(scale: large),
        ),
        isTrue,
      );
      expect(identical(GesturaTheme.light(), GesturaTheme.dark()), isFalse);
      expect(
        identical(
          GesturaTheme.forBrightness(Brightness.dark),
          GesturaTheme.dark(),
        ),
        isTrue,
      );
    });
  });
}
