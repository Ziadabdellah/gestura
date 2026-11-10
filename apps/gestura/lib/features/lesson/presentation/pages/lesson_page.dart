import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_state.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_view_model.dart';
import 'package:gestura/features/lesson/presentation/widgets/leave_lesson_dialog.dart';
import 'package:gestura/features/lesson/presentation/widgets/lesson_view.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';

class LessonPage extends StatelessWidget {
  const new({required this.lessonId, super.key});

  final LessonId lessonId;

  static bool answerChecked(
    LessonPlayerState previous,
    LessonPlayerState current,
  ) =>
      previous is LessonInProgress &&
      current is LessonInProgress &&
      !previous.isChecked &&
      current.isChecked;

  static Future<void> answerFeedback(LessonPlayerState state) async {
    if (state case LessonInProgress(:final isCorrect)) {
      await (isCorrect
          ? HapticFeedback.lightImpact()
          : HapticFeedback.heavyImpact());
    }
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final viewModel = LessonPlayerViewModel(
        getIt<ContentRepository>(),
        getIt<ProgressRepository>(),
      );
      unawaited(viewModel.load(lessonId));
      return viewModel;
    },
    child: BlocConsumer<LessonPlayerViewModel, LessonPlayerState>(
      listenWhen: answerChecked,
      listener: (context, state) => unawaited(answerFeedback(state)),
      builder: (context, state) => PopScope(
        canPop: state is! LessonInProgress,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final navigator = Navigator.of(context);
          if (await confirmLeaveLesson(context)) navigator.pop();
        },
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: LessonView(
              state: state,
              onClose: () => Navigator.of(context).maybePop(),
              onRetry: () => unawaited(
                context.read<LessonPlayerViewModel>().load(lessonId),
              ),
              onDone: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    ),
  );
}
