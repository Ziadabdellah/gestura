import 'package:flutter/material.dart';
import 'package:gestura_ui/gestura_ui.dart';

class UnitProgressRing extends StatelessWidget {
  const new({
    required this.number,
    required this.completed,
    required this.total,
    super.key,
  });

  static const double size = 44;
  static const double strokeWidth = 4;
  static const double checkSize = 22;

  final int number;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sizes = context.gSizes;
    final isComplete = total > 0 && completed == total;

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: sizes.scaled(size),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: total == 0 ? 0 : completed / total,
              strokeWidth: sizes.scaled(strokeWidth),
              strokeCap: StrokeCap.round,
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
            Center(
              child: isComplete
                  ? Icon(
                      Icons.check_rounded,
                      color: scheme.primary,
                      size: sizes.icon(checkSize),
                    )
                  : Padding(
                      padding: EdgeInsetsDirectional.all(sizes.sm),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$number',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
