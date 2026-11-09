import 'package:flutter/material.dart';
import 'package:gestura_ui/src/theme/gestura_theme_context.dart';

class GSkeleton extends StatefulWidget {
  const new({super.key, this.width, this.height, this.borderRadius})
    : shape = BoxShape.rectangle;

  const new circle({required double size, super.key})
    : width = size,
      height = size,
      borderRadius = 0,
      shape = BoxShape.circle;

  final double? width;
  final double? height;
  final double? borderRadius;
  final BoxShape shape;

  static const Duration pulseDuration = Duration(milliseconds: 900);
  static const double defaultHeight = 16;

  @override
  State<GSkeleton> createState() => _GSkeletonState();
}

class _GSkeletonState extends State<GSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: GSkeleton.pulseDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sizes = context.gSizes;
    final radius = switch (widget.shape) {
      BoxShape.circle => null,
      BoxShape.rectangle => BorderRadius.circular(
        widget.borderRadius ?? sizes.radiusSm,
      ),
    };

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Container(
            width: widget.width,
            height: widget.height ?? sizes.scaled(GSkeleton.defaultHeight),
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius: radius,
              color: Color.lerp(
                scheme.surfaceContainerHigh,
                scheme.surfaceContainerHighest,
                Curves.easeInOut.transform(_controller.value),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
