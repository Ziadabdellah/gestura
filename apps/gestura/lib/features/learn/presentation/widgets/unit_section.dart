import 'package:flutter/material.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/features/learn/presentation/widgets/lesson_tile.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class UnitSection extends StatelessWidget {
  const new({required this.unit, required this.lessons, super.key});

  final CourseUnit unit;
  final List<Lesson> lessons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.gSizes;

    return Padding(
      padding: EdgeInsetsDirectional.only(top: sizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.title.of(context),
                    style: theme.textTheme.titleLarge,
                  ),
                  SizedBox(height: sizes.xxs),
                  Text(
                    context.l10n.unitLessonCount(lessons.length),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: sizes.sm),
          for (final (index, lesson) in lessons.indexed) ...[
            if (index > 0) SizedBox(height: sizes.xs),
            LessonTile(number: index + 1, lesson: lesson),
          ],
        ],
      ),
    );
  }
}
