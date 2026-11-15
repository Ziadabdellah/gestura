import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/core/share/link_sharer.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/saved/domain/saved_signs_repository.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:gestura/features/sign_detail/presentation/view_models/sign_detail_state.dart';
import 'package:gestura/features/sign_detail/presentation/view_models/sign_detail_view_model.dart';
import 'package:gestura/features/sign_detail/presentation/widgets/sign_detail_view.dart';
import 'package:gestura/l10n/l10n.dart';

class SignDetailPage extends ConsumerWidget {
  const new({required this.signId, super.key});

  final SignId signId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => BlocProvider(
    create: (_) {
      final hand = ref.read(settingsViewModelProvider).settings.dominantHand;
      final viewModel = SignDetailViewModel(
        getIt<ContentRepository>(),
        getIt<SavedSignsRepository>(),
        playback: Playback(mirrored: hand.mirrorsVideo),
      );
      unawaited(viewModel.load(signId));
      return viewModel;
    },
    child: Scaffold(
      appBar: AppBar(
        actions: [
          BlocBuilder<SignDetailViewModel, SignDetailState>(
            builder: (context, state) => switch (state) {
              SignDetailLoaded(:final sign, :final saved) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (button) => IconButton(
                      tooltip: context.l10n.shareSign,
                      icon: const Icon(Icons.ios_share_rounded),
                      onPressed: () {
                        final box = button.findRenderObject()! as RenderBox;
                        unawaited(
                          getIt<LinkSharer>().share(
                            signLink(sign.id),
                            subject: sign.gloss,
                            origin: box.localToGlobal(Offset.zero) & box.size,
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    isSelected: saved,
                    tooltip: saved
                        ? context.l10n.removeSavedSign
                        : context.l10n.saveSign,
                    icon: const Icon(Icons.favorite_border_rounded),
                    selectedIcon: const Icon(Icons.favorite_rounded),
                    onPressed: () => unawaited(
                      context.read<SignDetailViewModel>().toggleSaved(),
                    ),
                  ),
                ],
              ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
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
