import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/fingerspelling/presentation/view_models/fingerspelling_state.dart';
import 'package:gestura/features/fingerspelling/presentation/view_models/fingerspelling_view_model.dart';
import 'package:gestura/features/fingerspelling/presentation/widgets/fingerspelling_view.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:gestura/l10n/l10n.dart';

class FingerspellingPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => BlocProvider(
    create: (_) {
      final hand = ref.read(settingsViewModelProvider).settings.dominantHand;
      final viewModel = FingerspellingViewModel(
        getIt<ContentRepository>(),
        playback: Playback(mirrored: hand.mirrorsVideo),
      );
      unawaited(viewModel.load());
      return viewModel;
    },
    child: Scaffold(
      appBar: AppBar(title: Text(context.l10n.fingerspellingTitle)),
      body: BlocBuilder<FingerspellingViewModel, FingerspellingState>(
        builder: (context, state) {
          final viewModel = context.read<FingerspellingViewModel>();
          return FingerspellingView(
            state: state,
            onRetry: () => unawaited(viewModel.load()),
            onSelect: viewModel.select,
            onSpell: viewModel.spell,
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
