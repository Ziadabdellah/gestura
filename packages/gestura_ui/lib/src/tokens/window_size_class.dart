import 'package:flutter/widgets.dart';
import 'package:gestura_ui/src/tokens/gestura_spacing.dart';

enum WindowSizeClass {
  compact(screenPadding: GesturaSpacing.md),
  medium(screenPadding: GesturaSpacing.lg),
  expanded(screenPadding: GesturaSpacing.lg);

  new({required this.screenPadding});

  factory fromWidth(double width) => switch (width) {
    < mediumMinWidth => compact,
    < expandedMinWidth => medium,
    _ => expanded,
  };

  factory of(BuildContext context) =>
      WindowSizeClass.fromWidth(MediaQuery.sizeOf(context).width);

  static const double mediumMinWidth = 600;
  static const double expandedMinWidth = 840;

  final double screenPadding;

  bool get usesNavigationRail => this != compact;
}
