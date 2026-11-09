import 'package:flutter/material.dart';

@immutable
class GesturaTextStyles extends ThemeExtension<GesturaTextStyles> {
  const new({required this.gloss});

  static const GesturaTextStyles standard = GesturaTextStyles(
    gloss: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      leadingDistribution: TextLeadingDistribution.even,
    ),
  );

  final TextStyle gloss;

  @override
  GesturaTextStyles copyWith({TextStyle? gloss}) =>
      GesturaTextStyles(gloss: gloss ?? this.gloss);

  @override
  GesturaTextStyles lerp(GesturaTextStyles? other, double t) {
    if (other is! GesturaTextStyles) return this;
    return GesturaTextStyles(gloss: TextStyle.lerp(gloss, other.gloss, t)!);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GesturaTextStyles && other.gloss == gloss;

  @override
  int get hashCode => gloss.hashCode;
}
