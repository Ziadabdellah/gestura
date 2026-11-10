import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/core/widgets/failure_view.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_state.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_view_model.dart';
import 'package:gestura/features/lesson/presentation/widgets/choose_video_quiz.dart';
import 'package:gestura/features/lesson/presentation/widgets/choose_word_quiz.dart';
import 'package:gestura/features/lesson/presentation/widgets/learn_sign_card.dart';
import 'package:gestura/features/lesson/presentation/widgets/lesson_action_bar.dart';
import 'package:gestura/features/lesson/presentation/widgets/lesson_complete_view.dart';
import 'package:gestura/features/lesson/presentation/widgets/lesson_top_bar.dart';
import 'package:gestura/features/lesson/presentation/widgets/sign_video_stage.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class LessonView extends StatelessWidget {
  const new({
    required this.state,
    required this.onClose,
    required this.onRetry,
    required this.onDone,
    super.key,
  });

  final LessonPlayerState state;
  final VoidCallback onClose;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => switch (state) {
    LessonPlayerLoading() => Column(
      children: [
        LessonTopBar(onClose: onClose),
        Expanded(
          child: Center(
            child: CircularProgressIndicator(
              semanticsLabel: context.l10n.loading,
            ),
          ),
        ),
      ],
    ),
    LessonPlayerFailed(:final failure) => Column(
      children: [
        LessonTopBar(onClose: onClose),
        Expanded(
          child: FailureView(failure: failure, onRetry: onRetry),
        ),
      ],
    ),
    final LessonInProgress active => _StepView(state: active, onClose: onClose),
    final LessonFinished finished => LessonCompleteView(
      state: finished,
      onDone: onDone,
      onRetrySave: () =>
          unawaited(context.read<LessonPlayerViewModel>().retrySave()),
    ),
  };
}

class _StepView extends StatelessWidget {
  const new({required this.state, required this.onClose});

  final LessonInProgress state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final sizes = context.gSizes;
    final viewModel = context.read<LessonPlayerViewModel>();
    final step = state.step;

    return Column(
      children: [
        LessonTopBar(
          onClose: onClose,
          current: state.stepIndex + 1,
          total: state.stepCount,
        ),
        Expanded(
          child: ReadableInset(
            minimum: context.windowSizeClass.screenPadding,
            builder: (context, inset) => ListView(
              key: ValueKey(state.stepIndex),
              padding: EdgeInsetsDirectional.fromSTEB(
                inset,
                sizes.xs,
                inset,
                sizes.lg,
              ),
              children: [
                SignVideoStage(
                  sign: state.videoSign,
                  playback: state.playback,
                  emptyMessage: context.l10n.chooseVideoHint,
                  onSpeedChanged: viewModel.setSpeed,
                  onLoopingChanged: (looping) =>
                      viewModel.setLooping(looping: looping),
                  onMirroredChanged: (mirrored) =>
                      viewModel.setMirrored(mirrored: mirrored),
                ),
                SizedBox(height: sizes.lg),
                switch (step) {
                  LearnSignStep(:final sign) => LearnSignCard(
                    sign: state.signOf(sign),
                  ),
                  final ChooseWordStep quiz => ChooseWordQuiz(
                    state: state,
                    step: quiz,
                  ),
                  final ChooseVideoStep quiz => ChooseVideoQuiz(
                    state: state,
                    step: quiz,
                  ),
                },
              ],
            ),
          ),
        ),
        LessonActionBar(state: state),
      ],
    );
  }
}
