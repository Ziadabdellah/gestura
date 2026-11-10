import 'package:flutter/material.dart';
import 'package:gestura/core/errors/failure_presentation.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_state.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class LessonCompleteView extends StatelessWidget {
  const new({
    required this.state,
    required this.onDone,
    required this.onRetrySave,
    super.key,
  });

  static const double badgeSize = 96;
  static const double badgeIconSize = 52;

  final LessonFinished state;
  final VoidCallback onDone;
  final VoidCallback onRetrySave;

  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % Duration.secondsPerMinute)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sizes = context.gSizes;
    final result = state.result;
    final save = state.save;

    return ReadableInset(
      minimum: context.windowSizeClass.screenPadding,
      builder: (context, inset) => ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          inset,
          sizes.xl,
          inset,
          sizes.lg,
        ),
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: GesturaMotion.adaptive(context, GesturaMotion.long),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: ExcludeSemantics(
                child: Container(
                  width: sizes.scaled(badgeSize),
                  height: sizes.scaled(badgeSize),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: sizes.icon(badgeIconSize),
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: sizes.lg),
          Semantics(
            header: true,
            child: Text(
              l10n.lessonCompleteTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          SizedBox(height: sizes.xs),
          Text(
            state.lesson.title.of(context),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: sizes.xl),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ResultTile(
                    label: l10n.resultAccuracy,
                    value: l10n.percentValue(result.score),
                  ),
                ),
                SizedBox(width: sizes.xs),
                Expanded(
                  child: _ResultTile(
                    label: l10n.resultTime,
                    value: formatDuration(result.duration),
                  ),
                ),
                SizedBox(width: sizes.xs),
                Expanded(
                  child: _ResultTile(
                    label: l10n.resultNewSigns,
                    value: '${result.newSigns}',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: sizes.xl),
          if (save case ProgressSaveFailed(:final failure)) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                '${l10n.progressSaveFailed} ${failure.message(l10n)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
            ),
            SizedBox(height: sizes.sm),
            GButton.secondary(
              label: l10n.retry,
              icon: Icons.refresh_rounded,
              expand: true,
              onPressed: onRetrySave,
            ),
            SizedBox(height: sizes.sm),
          ],
          GButton(
            label: l10n.continueAction,
            expand: true,
            isLoading: save is ProgressSaving,
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.gSizes;

    return GCard(
      tone: GCardTone.low,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: sizes.xs,
        vertical: sizes.md,
      ),
      child: MergeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleLarge,
              ),
            ),
            SizedBox(height: sizes.xxs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
