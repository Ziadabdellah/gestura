import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/practice/domain/self_camera.dart';
import 'package:gestura/features/practice/presentation/view_models/practice_state.dart';
import 'package:gestura/features/practice/presentation/view_models/practice_view_model.dart';
import 'package:gestura/features/practice/presentation/widgets/practice_view.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:gestura/l10n/l10n.dart';

class PracticePage extends ConsumerWidget {
  const new({required this.signId, super.key});

  final SignId signId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => BlocProvider(
    create: (_) {
      final hand = ref.read(settingsViewModelProvider).settings.dominantHand;
      final viewModel = PracticeViewModel(
        getIt<ContentRepository>(),
        getIt<SelfCamera>(),
        playback: Playback(mirrored: hand.mirrorsVideo),
      );
      unawaited(viewModel.load(signId));
      return viewModel;
    },
    child: Scaffold(
      appBar: AppBar(title: Text(context.l10n.practiceTitle)),
      body: BlocBuilder<PracticeViewModel, PracticeState>(
        builder: (context, state) {
          final viewModel = context.read<PracticeViewModel>();
          return PracticeView(
            state: state,
            onRetry: () => unawaited(viewModel.load(signId)),
            onRetryCamera: () => unawaited(viewModel.startCamera()),
            onSpeedChanged: viewModel.setSpeed,
            onLoopingChanged: (looping) =>
                viewModel.setLooping(looping: looping),
            onMirroredChanged: (mirrored) =>
                viewModel.setMirrored(mirrored: mirrored),
          );
        },
      ),
    ),
  );
}
