import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class GesturaColors extends ThemeExtension<GesturaColors> {
  const new({
    required this.coralStrong,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.stage,
    required this.onStage,
    required this.heroStart,
    required this.heroEnd,
    required this.onHero,
  });

  static const GesturaColors light = GesturaColors(
    coralStrong: Color(0xFFB13E22),
    success: Color(0xFF1F7A47),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFD4F3DF),
    onSuccessContainer: Color(0xFF0A3A1F),
    warning: Color(0xFF8A5A00),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFFE7B0),
    onWarningContainer: Color(0xFF3D2800),
    stage: Color(0xFF101C21),
    onStage: Color(0xFFFFFFFF),
    heroStart: Color(0xFF0B6E69),
    heroEnd: Color(0xFF085550),
    onHero: Color(0xFFFFFFFF),
  );

  static const GesturaColors dark = GesturaColors(
    coralStrong: Color(0xFFFF9C82),
    success: Color(0xFF73D99B),
    onSuccess: Color(0xFF00391C),
    successContainer: Color(0xFF0F5130),
    onSuccessContainer: Color(0xFFC8F5D7),
    warning: Color(0xFFF5C266),
    onWarning: Color(0xFF3D2800),
    warningContainer: Color(0xFF5C4300),
    onWarningContainer: Color(0xFFFFE7B0),
    stage: Color(0xFF0A1215),
    onStage: Color(0xFFFFFFFF),
    heroStart: Color(0xFF0D4F4A),
    heroEnd: Color(0xFF0A3B37),
    onHero: Color(0xFFE4ECEA),
  );

  final Color coralStrong;
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color stage;
  final Color onStage;
  final Color heroStart;
  final Color heroEnd;
  final Color onHero;

  LinearGradient get heroGradient => LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [heroStart, heroEnd],
  );

  @override
  GesturaColors copyWith({
    Color? coralStrong,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? stage,
    Color? onStage,
    Color? heroStart,
    Color? heroEnd,
    Color? onHero,
  }) => GesturaColors(
    coralStrong: coralStrong ?? this.coralStrong,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    stage: stage ?? this.stage,
    onStage: onStage ?? this.onStage,
    heroStart: heroStart ?? this.heroStart,
    heroEnd: heroEnd ?? this.heroEnd,
    onHero: onHero ?? this.onHero,
  );

  @override
  GesturaColors lerp(GesturaColors? other, double t) {
    if (other is! GesturaColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return GesturaColors(
      coralStrong: mix(coralStrong, other.coralStrong),
      success: mix(success, other.success),
      onSuccess: mix(onSuccess, other.onSuccess),
      successContainer: mix(successContainer, other.successContainer),
      onSuccessContainer: mix(onSuccessContainer, other.onSuccessContainer),
      warning: mix(warning, other.warning),
      onWarning: mix(onWarning, other.onWarning),
      warningContainer: mix(warningContainer, other.warningContainer),
      onWarningContainer: mix(onWarningContainer, other.onWarningContainer),
      stage: mix(stage, other.stage),
      onStage: mix(onStage, other.onStage),
      heroStart: mix(heroStart, other.heroStart),
      heroEnd: mix(heroEnd, other.heroEnd),
      onHero: mix(onHero, other.onHero),
    );
  }

  List<Color> get _values => [
    coralStrong,
    success,
    onSuccess,
    successContainer,
    onSuccessContainer,
    warning,
    onWarning,
    warningContainer,
    onWarningContainer,
    stage,
    onStage,
    heroStart,
    heroEnd,
    onHero,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GesturaColors && listEquals(other._values, _values);

  @override
  int get hashCode => Object.hashAll(_values);
}
