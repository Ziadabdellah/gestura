import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gestura_ui/src/tokens/gestura_radius.dart';
import 'package:gestura_ui/src/tokens/gestura_scale.dart';
import 'package:gestura_ui/src/tokens/gestura_spacing.dart';
import 'package:gestura_ui/src/tokens/gestura_touch.dart';

@immutable
class GesturaSizes extends ThemeExtension<GesturaSizes> {
  const new({this.scale = GesturaScale.identity});

  static const GesturaSizes standard = GesturaSizes();

  final GesturaScale scale;

  double get xxs => scaled(GesturaSpacing.xxs);
  double get xs => scaled(GesturaSpacing.xs);
  double get sm => scaled(GesturaSpacing.sm);
  double get md => scaled(GesturaSpacing.md);
  double get lg => scaled(GesturaSpacing.lg);
  double get xl => scaled(GesturaSpacing.xl);
  double get xxl => scaled(GesturaSpacing.xxl);

  double get radiusSm => scaled(GesturaRadius.sm);
  double get radiusMd => scaled(GesturaRadius.md);
  double get radiusLg => scaled(GesturaRadius.lg);
  double get radiusXl => scaled(GesturaRadius.xl);

  double get tapTarget => atLeastTapTarget(GesturaTouch.minimumTarget);

  double scaled(double value) => value * scale.size;

  double icon(double value) => value * scale.text;

  double atLeastTapTarget(double value) =>
      math.max(GesturaTouch.minimumTarget, scaled(value));

  @override
  GesturaSizes copyWith({GesturaScale? scale}) =>
      GesturaSizes(scale: scale ?? this.scale);

  @override
  GesturaSizes lerp(GesturaSizes? other, double t) {
    if (other is! GesturaSizes) return this;
    return GesturaSizes(scale: GesturaScale.lerp(scale, other.scale, t));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GesturaSizes && other.scale == scale;

  @override
  int get hashCode => scale.hashCode;
}
