import 'package:flutter/material.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class LessonTopBar extends StatelessWidget {
  const new({required this.onClose, super.key, this.current, this.total});

  static const double progressHeight = 8;

  final VoidCallback onClose;
  final int? current;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    final step = current;
    final count = total;

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: sizes.xs,
        vertical: sizes.xxs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.closeLesson,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          if (step != null && count != null) ...[
            SizedBox(width: sizes.xs),
            Expanded(
              child: ExcludeSemantics(
                child: LinearProgressIndicator(
                  value: step / count,
                  minHeight: sizes.scaled(progressHeight),
                  borderRadius: BorderRadius.circular(sizes.radiusSm),
                ),
              ),
            ),
            SizedBox(width: sizes.sm),
            Semantics(
              label: l10n.lessonStepProgress(step, count),
              child: ExcludeSemantics(
                child: Text(
                  '$step / $count',
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
            SizedBox(width: sizes.sm),
          ],
        ],
      ),
    );
  }
}
