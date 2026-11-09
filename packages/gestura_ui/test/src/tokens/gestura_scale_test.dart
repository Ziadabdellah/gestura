import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

void main() {
  group('GesturaScale.fromSize', () {
    test('keeps the design size on a 360 wide phone', () {
      expect(
        GesturaScale.fromSize(const Size(360, 780)),
        GesturaScale.identity,
      );
    });

    test('grows text and sizes on larger phones', () {
      expect(
        GesturaScale.fromSize(const Size(393, 852)),
        const GesturaScale(text: 1.09, size: 1.09),
      );
      expect(
        GesturaScale.fromSize(const Size(412, 915)),
        const GesturaScale(text: 1.12, size: 1.14),
      );
    });

    test('caps the growth on the widest phones', () {
      expect(
        GesturaScale.fromSize(const Size(480, 1000)),
        const GesturaScale(text: GesturaScale.maxText, size: 1.15),
      );
    });

    test('tightens sizes on small phones but never shrinks text', () {
      expect(
        GesturaScale.fromSize(const Size(320, 640)),
        const GesturaScale(size: 0.9),
      );
      expect(
        GesturaScale.fromSize(const Size(280, 600)),
        const GesturaScale(size: GesturaScale.minSize),
      );
    });

    test('ignores orientation by using the shortest side', () {
      expect(
        GesturaScale.fromSize(const Size(852, 393)),
        GesturaScale.fromSize(const Size(393, 852)),
      );
    });

    test('leaves tablets at the design size', () {
      expect(
        GesturaScale.fromSize(const Size(800, 1280)),
        GesturaScale.identity,
      );
      expect(
        GesturaScale.fromSize(const Size(1280, 800)),
        GesturaScale.identity,
      );
    });

    test('falls back to the design size for an empty screen', () {
      expect(GesturaScale.fromSize(Size.zero), GesturaScale.identity);
    });
  });

  group('GesturaScale', () {
    test('interpolates both factors', () {
      const a = GesturaScale(size: 0.9);
      const b = GesturaScale(text: 1.1, size: 1.1);

      expect(GesturaScale.lerp(a, b, 0.5), const GesturaScale(text: 1.05));
    });

    test('compares by value and describes itself', () {
      final size = double.parse('1.1');

      expect(
        GesturaScale(text: size, size: size),
        isNot(GesturaScale.identity),
      );
      expect(
        GesturaScale(text: size, size: size),
        const GesturaScale(text: 1.1, size: 1.1),
      );
      expect(
        GesturaScale(text: size, size: size).hashCode,
        const GesturaScale(text: 1.1, size: 1.1).hashCode,
      );
      expect(
        GesturaScale.identity.toString(),
        'GesturaScale(text: 1.0, size: 1.0)',
      );
    });
  });
}
