import 'package:flutter/material.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/features/learn/domain/course_outline.dart';
import 'package:gestura/features/learn/presentation/widgets/lesson_tile.dart';
import 'package:gestura/features/learn/presentation/widgets/unit_progress_ring.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class UnitSection extends StatelessWidget {
  const new({required this.outline, required this.onLessonSelected, super.key});

  final UnitOutline outline;
  final ValueChanged<LessonId> onLessonSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    final lessons = outline.lessons;
    final count = lessons.length;

    return GCard(
      tone: GCardTone.low,
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: PageStorageKey<int>(outline.unit.index),
        initiallyExpanded: outline.hasNextLesson,
        expansionAnimationStyle: MediaQuery.disableAnimationsOf(context)
            ? AnimationStyle.noAnimation
            : null,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: EdgeInsetsDirectional.symmetric(
          horizontal: sizes.md,
          vertical: sizes.xs,
        ),
        childrenPadding: EdgeInsetsDirectional.fromSTEB(
          sizes.md,
          0,
          sizes.md,
          sizes.sm,
        ),
        leading: UnitProgressRing(
          number: outline.unit.index + 1,
          completed: outline.completed,
          total: count,
        ),
        title: Semantics(
          header: true,
          child: Text(
            outline.unit.title.of(context),
            style: theme.textTheme.titleMedium,
          ),
        ),
        subtitle: Text(
          '${l10n.unitLessonCount(count)} · '
          '${l10n.progressDone(outline.completed, count)}',
        ),
        children: [
          for (final (index, lesson) in lessons.indexed)
            LessonTile(
              outline: lesson,
              isFirst: index == 0,
              isLast: index == count - 1,
              onTap: lesson.status is LessonLocked
                  ? null
                  : () => onLessonSelected(lesson.lesson.id),
            ),
        ],
      ),
    );
  }
}
