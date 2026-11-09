import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:gestura_ui/gestura_ui.dart';

typedef ReadableInsetBuilder = Widget Function(
  BuildContext context,
  double inset,
);

class ReadableInset extends StatelessWidget {
  const new({required this.builder, super.key, this.minimum = 0});

  static const double maxContentWidth = 640;

  final ReadableInsetBuilder builder;
  final double minimum;

  @override
  Widget build(BuildContext context) {
    final maxWidth = context.gSizes.scaled(maxContentWidth);
    return LayoutBuilder(
      builder: (context, constraints) => builder(
        context,
        math.max(minimum, (constraints.maxWidth - maxWidth) / 2),
      ),
    );
  }
}
