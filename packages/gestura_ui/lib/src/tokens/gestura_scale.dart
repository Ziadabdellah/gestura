import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:gestura_ui/src/tokens/window_size_class.dart';

@immutable
final class GesturaScale {
  const new({this.text = 1, this.size = 1});

  factory fromSize(Size screen) {
    final shortestSide = screen.shortestSide;
    if (shortestSide <= 0 || shortestSide >= tabletShortestSide) {
      return identity;
    }
    final ratio = shortestSide / designWidth;
    return GesturaScale(
      text: _round(ratio.clamp(minText, maxText)),
      size: _round(ratio.clamp(minSize, maxSize)),
    );
  }

  factory lerp(GesturaScale a, GesturaScale b, double t) => GesturaScale(
    text: lerpDouble(a.text, b.text, t)!,
    size: lerpDouble(a.size, b.size, t)!,
  );

  static const GesturaScale identity = GesturaScale();
  static const double designWidth = 360;
  static const double tabletShortestSide = WindowSizeClass.mediumMinWidth;
  static const double minText = 1;
  static const double maxText = 1.12;
  static const double minSize = 0.9;
  static const double maxSize = 1.15;

  final double text;
  final double size;

  static double _round(double value) => (value * 100).roundToDouble() / 100;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GesturaScale && other.text == text && other.size == size;

  @override
  int get hashCode => Object.hash(text, size);

  @override
  String toString() => 'GesturaScale(text: $text, size: $size)';
}
