import 'package:flutter/material.dart';
import 'package:gestura/core/media/media_image.dart';
import 'package:gestura/core/widgets/failure_view.dart';
import 'package:gestura/core/widgets/list_skeleton.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/features/learn/domain/course_outline.dart';
import 'package:gestura/features/today/presentation/view_models/today_state.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class TodayView extends StatelessWidget {
  const new({
    required this.state,
    required this.goalMinutes,
    required this.onRetry,
    required this.onOpenLesson,
    required this.onReview,
    required this.onOpenSign,
    super.key,
  });

  final TodayState state;
  final int goalMinutes;
  final VoidCallback onRetry;
  final ValueChanged<LessonOutline> onOpenLesson;
  final VoidCallback onReview;
  final ValueChanged<Sign> onOpenSign;

  @override
  Widget build(BuildContext context) => switch (state) {
    TodayLoading() => const ListSkeleton(rows: 3),
    TodayFailed(:final failure) => FailureView(
      failure: failure,
      onRetry: onRetry,
    ),
    final TodayReady ready => _Ready(
      state: ready,
      goalMinutes: goalMinutes,
      onOpenLesson: onOpenLesson,
      onReview: onReview,
      onOpenSign: onOpenSign,
    ),
  };
}

class _Ready extends StatelessWidget {
  const new({
    required this.state,
    required this.goalMinutes,
    required this.onOpenLesson,
    required this.onReview,
    required this.onOpenSign,
  });

  static const double ringSize = 76;
  static const Size thumbnail = Size(64, 80);

  final TodayReady state;
  final int goalMinutes;
  final ValueChanged<LessonOutline> onOpenLesson;
  final VoidCallback onReview;
  final ValueChanged<Sign> onOpenSign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.gColors;
    final sizes = context.gSizes;
    final padding = context.windowSizeClass.screenPadding;
    final next = state.outline.nextLesson;
    final sign = state.signOfTheDay;
    final goalReached = state.minutesToday >= goalMinutes;
    final heroText = theme.textTheme.apply(
      bodyColor: colors.onHero,
      displayColor: colors.onHero,
    );

    return ReadableInset(
      minimum: padding,
      builder: (context, inset) => ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          inset,
          sizes.xs,
          inset,
          sizes.xl,
        ),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: colors.heroGradient,
              borderRadius: BorderRadius.circular(sizes.radiusXl),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.all(sizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.continueLearning,
                      style: heroText.labelLarge,
                    ),
                  ),
                  SizedBox(height: sizes.xs),
                  Text(
                    switch (next) {
                      final LessonOutline lesson => [
                        l10n.lessonNumber(lesson.number),
                        lesson.lesson.title.of(context),
                      ].join(' · '),
                      null => l10n.allLessonsDone,
                    },
                    style: heroText.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (next != null) ...[
                    SizedBox(height: sizes.md),
                    Theme(
                      data: theme.copyWith(
                        colorScheme: scheme.copyWith(
                          primary: colors.onHero,
                          onPrimary: colors.heroEnd,
                        ),
                      ),
                      child: GButton(
                        label: l10n.startLesson,
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => onOpenLesson(next),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: sizes.sm),
          GCard(
            tone: GCardTone.low,
            semanticLabel: [
              l10n.todayGoalTitle,
              l10n.todayGoalProgress(state.minutesToday, goalMinutes),
              l10n.streakDays(state.streak),
            ].join(', '),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  GProgressRing(
                    value: state.minutesToday / goalMinutes,
                    semanticLabel: l10n.todayGoalTitle,
                    size: ringSize,
                    child: Icon(
                      goalReached ? Icons.check_rounded : Icons.timer_outlined,
                      color: scheme.primary,
                    ),
                  ),
                  SizedBox(width: sizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.todayGoalTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.todayGoalProgress(
                            state.minutesToday,
                            goalMinutes,
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                        SizedBox(height: sizes.xs),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.warningContainer,
                            borderRadius: BorderRadius.circular(
                              GesturaRadius.full,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.symmetric(
                              horizontal: sizes.sm,
                              vertical: sizes.xxs,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  color: colors.coralStrong,
                                  size: sizes.icon(18),
                                ),
                                SizedBox(width: sizes.xxs),
                                Flexible(
                                  child: Text(
                                    l10n.streakDays(state.streak),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: colors.onWarningContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: sizes.sm),
          GCard(
            tone: GCardTone.low,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.reviewCardTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                SizedBox(height: sizes.xxs),
                Text(
                  l10n.signsToReview(state.dueReviews),
                  style: theme.textTheme.bodyLarge,
                ),
                if (state.dueReviews > 0) ...[
                  SizedBox(height: sizes.sm),
                  GButton.secondary(
                    label: l10n.startReview,
                    icon: Icons.replay_rounded,
                    onPressed: onReview,
                  ),
                ],
              ],
            ),
          ),
          if (sign != null) ...[
            SizedBox(height: sizes.sm),
            MergeSemantics(
              child: GCard(
                tone: GCardTone.low,
                onTap: () => onOpenSign(sign),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(sizes.radiusMd),
                      child: MediaImage(
                        media: sign.media.thumbnail,
                        width: sizes.scaled(thumbnail.width),
                        height: sizes.scaled(thumbnail.height),
                      ),
                    ),
                    SizedBox(width: sizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.signOfTheDay,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                          Text(
                            sign.meaning.of(context),
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(sign.gloss, style: context.gTextStyles.gloss),
                        ],
                      ),
                    ),
                    const ExcludeSemantics(child: Icon(Icons.chevron_right)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
