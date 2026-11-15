import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
import 'package:gestura/features/review/presentation/view_models/review_state.dart';
import 'package:gestura/features/review/presentation/view_models/review_view_model.dart';
import 'package:gestura/features/review/presentation/widgets/review_view.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';

class ReviewPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => BlocProvider(
    create: (_) {
      final hand = ref.read(settingsViewModelProvider).settings.dominantHand;
      final viewModel = ReviewViewModel(
        getIt<ReviewRepository>(),
        getIt<ContentRepository>(),
        getIt<ActivityRepository>(),
        playback: Playback(mirrored: hand.mirrorsVideo),
      );
      unawaited(viewModel.load());
      return viewModel;
    },
    child: BlocBuilder<ReviewViewModel, ReviewState>(
      builder: (context, state) {
        final viewModel = context.read<ReviewViewModel>();
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ReviewView(
              state: state,
              onClose: () => Navigator.of(context).maybePop(),
              onRetry: () => unawaited(viewModel.load()),
              onReveal: viewModel.reveal,
              onGrade: (grade) => unawaited(viewModel.grade(grade)),
              onSpeedChanged: viewModel.setSpeed,
              onLoopingChanged: (looping) =>
                  viewModel.setLooping(looping: looping),
              onMirroredChanged: (mirrored) =>
                  viewModel.setMirrored(mirrored: mirrored),
            ),
          ),
        );
      },
    ),
  );
}
