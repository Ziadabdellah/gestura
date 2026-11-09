import 'package:flutter/widgets.dart';
import 'package:gestura_ui/src/tokens/gestura_scale.dart';

typedef GesturaScaledWidgetBuilder = Widget Function(
  BuildContext context,
  GesturaScale scale,
);

class GesturaAdaptiveBuilder extends StatelessWidget {
  const new({required this.builder, super.key});

  final GesturaScaledWidgetBuilder builder;

  @override
  Widget build(BuildContext context) =>
      builder(context, GesturaScale.fromSize(MediaQuery.sizeOf(context)));
}
