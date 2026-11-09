import 'package:flutter/painting.dart';

abstract final class WcagContrast {
  static const double normalText = 4.5;
  static const double largeTextOrUi = 3;

  static double ratio(Color a, Color b) {
    final first = a.computeLuminance();
    final second = b.computeLuminance();
    final (lighter, darker) = first >= second
        ? (first, second)
        : (second, first);
    return (lighter + 0.05) / (darker + 0.05);
  }
}
