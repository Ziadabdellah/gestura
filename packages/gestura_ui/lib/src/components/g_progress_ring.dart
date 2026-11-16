import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gestura_ui/src/theme/gestura_theme_context.dart';
import 'package:gestura_ui/src/tokens/gestura_motion.dart';

class GProgressRing extends StatelessWidget {
  const new({
    required this.value,
    required this.semanticLabel,
    super.key,
    this.size = 64,
    this.strokeWidth = 8,
    this.child,
  });

  final double value;
  final String semanticLabel;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sizes = context.gSizes;
    final target = value.clamp(0.0, 1.0);
    final side = sizes.scaled(size);

    return Semantics(
      label: semanticLabel,
      value: '${(target * 100).round()}%',
      child: SizedBox.square(
        dimension: side,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: target),
          duration: GesturaMotion.adaptive(context, GesturaMotion.long),
          curve: GesturaMotion.enter,
          builder: (context, progress, inner) => CustomPaint(
            painter: _RingPainter(
              progress: progress,
              track: scheme.surfaceContainerHighest,
              fill: scheme.primary,
              stroke: sizes.scaled(strokeWidth),
            ),
            child: Center(child: inner),
          ),
          child: ExcludeSemantics(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const new({
    required this.progress,
    required this.track,
    required this.fill,
    required this.stroke,
  });

  final double progress;
  final Color track;
  final Color fill;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        paint..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.fill != fill ||
      old.stroke != stroke;
}
