import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/core/media/media_cache.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/offline/offline_pack_state.dart';
import 'package:gestura/features/offline/offline_pack_view_model.dart';
import 'package:gestura/l10n/l10n.dart';

class OfflinePackTile extends StatelessWidget {
  const new({required this.padding, super.key});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final viewModel = OfflinePackViewModel(
        getIt<ContentRepository>(),
        getIt<MediaCache>(),
      );
      unawaited(viewModel.load());
      return viewModel;
    },
    child: BlocBuilder<OfflinePackViewModel, OfflinePackState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final viewModel = context.read<OfflinePackViewModel>();
        void download() => unawaited(viewModel.download());
        Widget tile({
          required String subtitle,
          Widget? trailing,
          VoidCallback? onTap,
        }) => ListTile(
          contentPadding: padding,
          leading: const ExcludeSemantics(
            child: Icon(Icons.download_for_offline_outlined),
          ),
          title: Text(l10n.offlineTitle),
          subtitle: Text(subtitle),
          trailing: trailing,
          onTap: onTap,
        );
        return switch (state) {
          OfflinePackChecking() ||
          OfflinePackUnavailable() => const SizedBox.shrink(),
          OfflinePackIdle(:final complete) when complete => tile(
            subtitle: l10n.offlineReady,
            trailing: const ExcludeSemantics(
              child: Icon(Icons.check_circle_outline_rounded),
            ),
          ),
          OfflinePackIdle(:final files, :final saved) => tile(
            subtitle: l10n.offlineProgress(saved, files),
            trailing: const ExcludeSemantics(child: Icon(Icons.download)),
            onTap: download,
          ),
          OfflinePackDownloading(:final done, :final total, :final fraction) =>
            tile(
              subtitle: l10n.offlineProgress(done, total),
              trailing: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(value: fraction),
              ),
            ),
          OfflinePackFailed(:final saved, :final files) => tile(
            subtitle: l10n.offlineFailed(saved, files),
            trailing: const ExcludeSemantics(child: Icon(Icons.refresh)),
            onTap: download,
          ),
        };
      },
    ),
  );
}
