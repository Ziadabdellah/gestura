import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gestura_ui/gestura_ui.dart';

class WavingHand extends StatefulWidget {
  const new({super.key});

  static const double size = 112;
  static const double iconSize = 56;
  static const double swing = math.pi / 12;
  static const int waves = 2;
  static const Duration duration = Duration(milliseconds: 1600);

  static double angleAt(double progress) =>
      swing * math.sin(progress * 2 * math.pi * waves);

  @override
  State<WavingHand> createState() => _WavingHandState();
}

class _WavingHandState extends State<WavingHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: WavingHand.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gColors;
    final sizes = context.gSizes;
    final size = sizes.scaled(WavingHand.size);

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: colors.heroGradient,
          shape: BoxShape.circle,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.rotate(
            angle: WavingHand.angleAt(_controller.value),
            alignment: const Alignment(0.2, 0.6),
            child: child,
          ),
          child: Icon(
            Icons.waving_hand_rounded,
            size: sizes.icon(WavingHand.iconSize),
            color: colors.onHero,
          ),
        ),
      ),
    );
  }
}
