import 'package:flutter/material.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/features/learn/domain/course_outline.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class LessonTile extends StatelessWidget {
  const new({
    required this.outline,
    required this.isFirst,
    required this.isLast,
    super.key,
    this.onTap,
  });

  static const double nodeSize = 32;

  final LessonOutline outline;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  String _statusText(AppLocalizations l10n) => switch (outline.status) {
    LessonCompleted(:final bestScore) =>
      '${l10n.lessonCompleted} · ${l10n.bestScore(bestScore)}',
    LessonAvailable() => l10n.lessonUpNext,
    LessonLocked() => l10n.lessonLocked,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sizes = context.gSizes;
    final status = outline.status;

    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(sizes.radiusMd),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: sizes.scaled(nodeSize),
                child: Semantics(
                  label: l10n.lessonNumber(outline.number),
                  child: ExcludeSemantics(
                    child: _TimelineTrack(
                      outline: outline,
                      isFirst: isFirst,
                      isLast: isLast,
                    ),
                  ),
                ),
              ),
              SizedBox(width: sizes.md),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(vertical: sizes.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        outline.lesson.title.of(context),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: status is LessonLocked
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                        ),
                      ),
                      SizedBox(height: sizes.xxs),
                      Text(
                        _statusText(l10n),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: status is LessonAvailable
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineTrack extends StatelessWidget {
  const new({
    required this.outline,
    required this.isFirst,
    required this.isLast,
  });

  static const double lineWidth = 2;
  static const double iconSize = 18;

  final LessonOutline outline;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sizes = context.gSizes;
    final status = outline.status;
    final reached = status is! LessonLocked;

    Widget line({required bool visible, required bool active}) => Expanded(
      child: visible
          ? Center(
              child: SizedBox(
                width: sizes.scaled(lineWidth),
                height: double.infinity,
                child: ColoredBox(
                  color: active ? scheme.primary : scheme.outlineVariant,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );

    final (background, foreground) = switch (status) {
      LessonCompleted() => (scheme.primary, scheme.onPrimary),
      LessonAvailable() => (scheme.primaryContainer, scheme.onPrimaryContainer),
      LessonLocked() => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };

    return Column(
      children: [
        line(visible: !isFirst, active: reached),
        Container(
          width: sizes.scaled(LessonTile.nodeSize),
          height: sizes.scaled(LessonTile.nodeSize),
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: status is LessonAvailable
                ? Border.all(color: scheme.primary, width: sizes.scaled(2))
                : null,
          ),
          alignment: Alignment.center,
          child: switch (status) {
            LessonCompleted() => Icon(
              Icons.check_rounded,
              size: sizes.icon(iconSize),
              color: foreground,
            ),
            LessonLocked() => Icon(
              Icons.lock_outline_rounded,
              size: sizes.icon(iconSize),
              color: foreground,
            ),
            LessonAvailable() => FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${outline.number}',
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ),
          },
        ),
        line(visible: !isLast, active: status is LessonCompleted),
      ],
    );
  }
}
