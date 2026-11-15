import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:gestura/features/sign_detail/presentation/view_models/sign_detail_state.dart';
import 'package:gestura/features/sign_detail/presentation/view_models/sign_detail_view_model.dart';
import 'package:gestura/features/sign_detail/presentation/widgets/sign_detail_view.dart';

class SignDetailPage extends ConsumerWidget {
  const new({required this.signId, super.key});

  final SignId signId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => BlocProvider(
    create: (_) {
      final hand = ref.read(settingsViewModelProvider).settings.dominantHand;
      final viewModel = SignDetailViewModel(
        getIt<ContentRepository>(),
        playback: Playback(mirrored: hand.mirrorsVideo),
      );
      unawaited(viewModel.load(signId));
      return viewModel;
    },
    child: Scaffold(
      appBar: AppBar(),
      body: BlocBuilder<SignDetailViewModel, SignDetailState>(
        builder: (context, state) {
          final viewModel = context.read<SignDetailViewModel>();
          return SignDetailView(
            signId: signId,
            state: state,
            onRetry: () => unawaited(viewModel.load(signId)),
            onOpenSign: (sign) =>
                unawaited(SignRoute(signId: sign.id.value).push<void>(context)),
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
