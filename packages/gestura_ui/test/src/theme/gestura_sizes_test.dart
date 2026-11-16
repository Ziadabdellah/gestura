import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

void main() {
  group('GesturaSizes', () {
    test('matches the base tokens at the design size', () {
      const sizes = GesturaSizes.standard;

      expect(
        [
          sizes.xxs,
          sizes.xs,
          sizes.sm,
          sizes.md,
          sizes.lg,
          sizes.xl,
          sizes.xxl,
        ],
        [4, 8, 12, 16, 24, 32, 48],
      );
      expect(
        [sizes.radiusSm, sizes.radiusMd, sizes.radiusLg, sizes.radiusXl],
        [12, 16, 24, 32],
      );
      expect(sizes.tapTarget, 48);
      expect(sizes.icon(24), 24);
    });

    test('scales spacing and radius with the size factor', () {
      const sizes = GesturaSizes(scale: GesturaScale(text: 1.1, size: 1.1));

      expect(sizes.md, closeTo(17.6, 0.001));
      expect(sizes.radiusLg, closeTo(26.4, 0.001));
      expect(sizes.scaled(100), closeTo(110, 0.001));
    });

    test('scales icons with the text factor', () {
      const sizes = GesturaSizes(scale: GesturaScale(text: 1.1, size: 0.9));

      expect(sizes.icon(24), closeTo(26.4, 0.001));
    });

    test('never lets a tap target drop below 48', () {
      const small = GesturaSizes(scale: GesturaScale(size: 0.9));
      const large = GesturaSizes(scale: GesturaScale(size: 1.15));

      expect(small.tapTarget, 48);
      expect(small.atLeastTapTarget(52), 48);
      expect(large.tapTarget, closeTo(55.2, 0.001));
    });

    test('copies, interpolates and compares by scale', () {
      const small = GesturaSizes(scale: GesturaScale(size: 0.9));
      const large = GesturaSizes(scale: GesturaScale(size: 1.1));
      final equal = GesturaSizes(
        scale: GesturaScale(size: double.parse('0.9')),
      );

      expect(small.copyWith(scale: large.scale), large);
      expect(small.copyWith(), small);
      expect(small.lerp(large, 0.5).scale.size, closeTo(1, 0.001));
      expect(small.lerp(null, 0.5), same(small));
      expect(equal, small);
      expect(equal.hashCode, small.hashCode);
    });
  });

  group('extension equality', () {
    test('GesturaColors compares every color', () {
      expect(GesturaColors.light.copyWith(), GesturaColors.light);
      expect(
        GesturaColors.light.copyWith().hashCode,
        GesturaColors.light.hashCode,
      );
      expect(GesturaColors.light, isNot(GesturaColors.dark));
    });

    test('GesturaTextStyles compares the gloss style', () {
      const standard = GesturaTextStyles.standard;

      expect(standard.copyWith(), standard);
      expect(standard.copyWith().hashCode, standard.hashCode);
      expect(
        standard.copyWith(gloss: const TextStyle(fontSize: 20)),
        isNot(standard),
      );
    });
  });
}
