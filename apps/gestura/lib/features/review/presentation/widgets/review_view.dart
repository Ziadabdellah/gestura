import 'package:flutter/material.dart';
import 'package:gestura/core/widgets/failure_view.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/lesson/presentation/widgets/lesson_top_bar.dart';
import 'package:gestura/features/lesson/presentation/widgets/sign_video_stage.dart';
import 'package:gestura/features/review/presentation/view_models/review_state.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:gestura_ui/gestura_ui.dart';

class ReviewView extends StatelessWidget {
  const new({
    required this.state,
    required this.onClose,
    required this.onRetry,
    required this.onReveal,
    required this.onGrade,
    required this.onSpeedChanged,
    required this.onLoopingChanged,
    required this.onMirroredChanged,
    super.key,
  });

  static const double iconSize = 64;

  final ReviewState state;
  final VoidCallback onClose;
  final VoidCallback onRetry;
  final VoidCallback onReveal;
  final ValueChanged<ReviewGrade> onGrade;
  final ValueChanged<PlaybackSpeed> onSpeedChanged;
  final ValueChanged<bool> onLoopingChanged;
  final ValueChanged<bool> onMirroredChanged;

  Widget _message(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    return Column(
      children: [
        LessonTopBar(onClose: onClose),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.all(sizes.xl),
            child: Column(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    icon,
                    size: sizes.icon(iconSize),
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: sizes.md),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                SizedBox(height: sizes.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: sizes.xl),
                GButton(
                  label: context.l10n.continueAction,
                  expand: true,
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (state) {
      ReviewLoading() => Column(
        children: [
          LessonTopBar(onClose: onClose),
          Expanded(
            child: Center(
              child: CircularProgressIndicator(semanticsLabel: l10n.loading),
            ),
          ),
        ],
      ),
      ReviewFailed(:final failure) => Column(
        children: [
          LessonTopBar(onClose: onClose),
          Expanded(
            child: FailureView(failure: failure, onRetry: onRetry),
          ),
        ],
      ),
      ReviewNothingDue() => _message(
        context,
        icon: Icons.task_alt_rounded,
        title: l10n.reviewNothingDueTitle,
        message: l10n.reviewNothingDue,
      ),
      ReviewFinished(:final reviewed, :final remembered) => _message(
        context,
        icon: Icons.emoji_events_rounded,
        title: l10n.reviewDoneTitle,
        message: l10n.reviewDoneMessage(reviewed, remembered),
      ),
      final ReviewInProgress active => _Session(
        state: active,
        onClose: onClose,
        onReveal: onReveal,
        onGrade: onGrade,
        onSpeedChanged: onSpeedChanged,
        onLoopingChanged: onLoopingChanged,
        onMirroredChanged: onMirroredChanged,
      ),
    };
  }
}

class _Session extends StatelessWidget {
  const new({
    required this.state,
    required this.onClose,
    required this.onReveal,
    required this.onGrade,
    required this.onSpeedChanged,
    required this.onLoopingChanged,
    required this.onMirroredChanged,
  });

  final ReviewInProgress state;
  final VoidCallback onClose;
  final VoidCallback onReveal;
  final ValueChanged<ReviewGrade> onGrade;
  final ValueChanged<PlaybackSpeed> onSpeedChanged;
  final ValueChanged<bool> onLoopingChanged;
  final ValueChanged<bool> onMirroredChanged;

  String _label(BuildContext context, ReviewGrade grade) {
    final l10n = context.l10n;
    return switch (grade) {
      ReviewGrade.again => l10n.gradeAgain,
      ReviewGrade.hard => l10n.gradeHard,
      ReviewGrade.good => l10n.gradeGood,
      ReviewGrade.easy => l10n.gradeEasy,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    final sign = state.sign;

    return Column(
      children: [
        LessonTopBar(
          onClose: onClose,
          current: state.index + 1,
          total: state.cards.length,
        ),
        Expanded(
          child: ReadableInset(
            minimum: context.windowSizeClass.screenPadding,
            builder: (context, inset) => ListView(
              key: ValueKey(state.index),
              padding: EdgeInsetsDirectional.fromSTEB(
                inset,
                sizes.xs,
                inset,
                sizes.lg,
              ),
              children: [
                SignVideoStage(
                  sign: sign,
                  playback: state.playback,
                  onSpeedChanged: onSpeedChanged,
                  onLoopingChanged: onLoopingChanged,
                  onMirroredChanged: onMirroredChanged,
                ),
                SizedBox(height: sizes.lg),
                if (state.revealed)
                  Semantics(
                    liveRegion: true,
                    child: Column(
                      children: [
                        Text(
                          sign.meaning.of(context),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        SizedBox(height: sizes.xxs),
                        Text(
                          sign.gloss,
                          style: context.gTextStyles.gloss.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    l10n.reviewPrompt,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            context.windowSizeClass.screenPadding,
            sizes.xs,
            context.windowSizeClass.screenPadding,
            sizes.md,
          ),
          child: SafeArea(
            top: false,
            child: state.revealed
                ? Row(
                    children: [
                      for (final grade in ReviewGrade.values) ...[
                        if (grade != ReviewGrade.again)
                          SizedBox(width: sizes.xs),
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: [
                              _label(context, grade),
                              l10n.reviewInterval(state.daysAfter(grade)),
                            ].join(', '),
                            excludeSemantics: true,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(0, sizes.tapTarget),
                                padding: EdgeInsetsDirectional.symmetric(
                                  horizontal: sizes.xxs,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    sizes.radiusMd,
                                  ),
                                ),
                              ),
                              onPressed: () => onGrade(grade),
                              child: Padding(
                                padding: EdgeInsetsDirectional.symmetric(
                                  vertical: sizes.xs,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(_label(context, grade)),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        l10n.reviewInterval(
                                          state.daysAfter(grade),
                                        ),
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : GButton(
                    label: l10n.showAnswer,
                    expand: true,
                    onPressed: onReveal,
                  ),
          ),
        ),
      ],
    );
  }
}
