import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_state.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_view_model.dart';
import 'package:gestura/features/lesson/presentation/widgets/leave_lesson_dialog.dart';
import 'package:gestura/features/lesson/presentation/widgets/lesson_view.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';

class LessonPage extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) => BlocProvider(
    create: (_) {
      final hand = ref.read(settingsViewModelProvider).settings.dominantHand;
      final viewModel = LessonPlayerViewModel(
        getIt<ContentRepository>(),
        getIt<ProgressRepository>(),
        getIt<Telemetry>(),
        getIt<ReviewRepository>(),
        getIt<ActivityRepository>(),
        playback: Playback(mirrored: hand.mirrorsVideo),
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
