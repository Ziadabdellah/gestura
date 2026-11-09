import 'package:flutter/material.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura_ui/gestura_ui.dart';

class LessonTile extends StatelessWidget {
  const new({required this.number, required this.lesson, super.key});

  static const double badgeSize = 40;

  final int number;
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sizes = context.gSizes;

    return GCard(
      tone: GCardTone.low,
      child: MergeSemantics(
        child: Row(
          children: [
            SizedBox.square(
              dimension: sizes.scaled(badgeSize),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.all(sizes.xxs),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$number',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: sizes.md),
            Expanded(
              child: Text(
                lesson.title.of(context),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
