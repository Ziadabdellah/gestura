import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_state.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_view_model.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class LessonActionBar extends StatelessWidget {
  const new({required this.state, super.key});

  static const double feedbackIconSize = 28;

  final LessonInProgress state;

  String? _answer(BuildContext context) {
    if (state.isCorrect) return null;
    final l10n = context.l10n;
    return switch (state.step) {
      ChooseVideoStep(:final options, :final sign) => l10n.correctAnswerIs(
        l10n.videoOption(options.indexOf(sign) + 1),
      ),
      final step => l10n.correctAnswerIs(
        state.signOf(step.sign).meaning.of(context),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.gColors;
    final sizes = context.gSizes;
    final viewModel = context.read<LessonPlayerViewModel>();
    final padding = context.windowSizeClass.screenPadding;

    final (Color background, Color foreground) = switch (state) {
      LessonInProgress(isChecked: true, isCorrect: true) => (
        colors.successContainer,
        colors.onSuccessContainer,
      ),
      LessonInProgress(isChecked: true) => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      _ => (scheme.surfaceContainer, scheme.onSurface),
    };
    final answer = _answer(context);

    return Material(
      color: background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            padding,
            sizes.md,
            padding,
            sizes.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.isChecked) ...[
                Semantics(
                  liveRegion: true,
                  container: true,
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          state.isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: sizes.icon(feedbackIconSize),
                          color: foreground,
                        ),
                      ),
                      SizedBox(width: sizes.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.isCorrect
                                  ? l10n.answerCorrect
                                  : l10n.answerIncorrect,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: foreground,
                              ),
                            ),
                            if (answer != null)
                              Text(
                                answer,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: foreground,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sizes.md),
              ],
              if (state.canContinue)
                GButton(
                  label: l10n.continueAction,
                  expand: true,
                  onPressed: () => unawaited(viewModel.next()),
                )
              else
                GButton(
                  label: l10n.checkAnswer,
                  expand: true,
                  onPressed: state.selected == null ? null : viewModel.check,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
