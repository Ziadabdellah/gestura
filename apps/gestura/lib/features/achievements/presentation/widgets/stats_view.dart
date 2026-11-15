import 'package:flutter/material.dart';
import 'package:gestura/core/widgets/failure_view.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/achievements/domain/learner_stats.dart';
import 'package:gestura/features/achievements/presentation/view_models/stats_state.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

extension AchievementText on Achievement {
  IconData get icon => switch (this) {
    Achievement.firstLesson => Icons.flag_rounded,
    Achievement.tenSigns || Achievement.fiftySigns => Icons.back_hand_rounded,
    Achievement.firstMastered => Icons.workspace_premium_rounded,
    Achievement.threeDays ||
    Achievement.sevenDays ||
    Achievement.thirtyDays => Icons.local_fire_department_rounded,
    Achievement.hundredReviews => Icons.replay_rounded,
    Achievement.hourOfPractice => Icons.timer_rounded,
  };

  String title(AppLocalizations l10n) => switch (this) {
    Achievement.firstLesson => l10n.achievementFirstLesson,
    Achievement.tenSigns => l10n.achievementSigns(target),
    Achievement.fiftySigns => l10n.achievementSigns(target),
    Achievement.firstMastered => l10n.achievementFirstMastered,
    Achievement.threeDays => l10n.achievementStreak(target),
    Achievement.sevenDays => l10n.achievementStreak(target),
    Achievement.thirtyDays => l10n.achievementStreak(target),
    Achievement.hundredReviews => l10n.achievementReviews(target),
    Achievement.hourOfPractice => l10n.achievementHour,
  };
}

class StatsView extends StatelessWidget {
  const new({required this.state, required this.onRetry, super.key});

  final StatsState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => switch (state) {
    StatsLoading() => const Center(child: CircularProgressIndicator()),
    StatsFailed(:final failure) => FailureView(
      failure: failure,
      onRetry: onRetry,
    ),
    StatsReady(:final stats) => _Stats(stats: stats),
  };
}

class _Stats extends StatelessWidget {
  const new({required this.stats});

  final LearnerStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    final tiles = [
      (Icons.local_fire_department_rounded, l10n.statStreak, stats.streak),
      (Icons.emoji_events_rounded, l10n.statBestStreak, stats.bestStreak),
      (Icons.menu_book_rounded, l10n.statLessons, stats.lessons),
      (Icons.back_hand_rounded, l10n.statSigns, stats.signs),
      (Icons.workspace_premium_rounded, l10n.statMastered, stats.mastered),
      (Icons.timer_rounded, l10n.statMinutes, stats.minutes),
    ];
    return ReadableInset(
      minimum: context.windowSizeClass.screenPadding,
      builder: (context, inset) => ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          inset,
          sizes.sm,
          inset,
          sizes.xl,
        ),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 3 : 2;
              final width =
                  (constraints.maxWidth - sizes.sm * (columns - 1)) / columns;
              return Wrap(
                spacing: sizes.sm,
                runSpacing: sizes.sm,
                children: [
                  for (final (icon, label, value) in tiles)
                    SizedBox(
                      width: width,
                      child: MergeSemantics(
                        child: GCard(
                          tone: GCardTone.low,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ExcludeSemantics(
                                child: Icon(
                                  icon,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              SizedBox(height: sizes.xs),
                              Text(
                                '$value',
                                style: theme.textTheme.headlineSmall,
                              ),
                              Text(label, style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(height: sizes.lg),
          Semantics(
            header: true,
            child: Text(
              l10n.achievementsTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),
          SizedBox(height: sizes.xs),
          for (final achievement in Achievement.values)
            _AchievementRow(achievement: achievement, stats: stats),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const new({required this.achievement, required this.stats});

  final Achievement achievement;
  final LearnerStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    final earned = achievement.earnedIn(stats);
    final progress = achievement.progressIn(stats);
    final colors = theme.colorScheme;
    return MergeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: sizes.xs),
        child: Row(
          children: [
            ExcludeSemantics(
              child: CircleAvatar(
                backgroundColor: earned
                    ? colors.primaryContainer
                    : colors.surfaceContainerHighest,
                foregroundColor: earned
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
                child: Icon(achievement.icon),
              ),
            ),
            SizedBox(width: sizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title(l10n),
                    style: theme.textTheme.titleSmall,
                  ),
                  SizedBox(height: sizes.xxs),
                  if (earned)
                    Text(
                      l10n.achievementEarned,
                      style: theme.textTheme.bodySmall,
                    )
                  else ...[
                    ExcludeSemantics(
                      child: LinearProgressIndicator(
                        value: progress / achievement.target,
                      ),
                    ),
                    SizedBox(height: sizes.xxs),
                    Text(
                      l10n.achievementProgress(progress, achievement.target),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
