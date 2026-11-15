import 'package:flutter/material.dart';
import 'package:gestura/core/widgets/failure_view.dart';
import 'package:gestura/core/widgets/placeholder_content_notice.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/features/content/presentation/sign_hero.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/lesson/presentation/widgets/sign_video_stage.dart';
import 'package:gestura/features/sign_detail/presentation/view_models/sign_detail_state.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class SignDetailView extends StatelessWidget {
  const new({
    required this.signId,
    required this.state,
    required this.onRetry,
    required this.onOpenSign,
    required this.onSpeedChanged,
    required this.onLoopingChanged,
    required this.onMirroredChanged,
    super.key,
  });

  final SignId signId;
  final SignDetailState state;
  final VoidCallback onRetry;
  final ValueChanged<Sign> onOpenSign;
  final ValueChanged<PlaybackSpeed> onSpeedChanged;
  final ValueChanged<bool> onLoopingChanged;
  final ValueChanged<bool> onMirroredChanged;

  @override
  Widget build(BuildContext context) => switch (state) {
    SignDetailLoading() => _SignDetailSkeleton(signId: signId),
    SignDetailFailed(:final failure) => FailureView(
      failure: failure,
      onRetry: onRetry,
    ),
    final SignDetailLoaded loaded => _SignDetailBody(
      state: loaded,
      onOpenSign: onOpenSign,
      onSpeedChanged: onSpeedChanged,
      onLoopingChanged: onLoopingChanged,
      onMirroredChanged: onMirroredChanged,
    ),
  };
}

class _SignDetailBody extends StatelessWidget {
  const new({
    required this.state,
    required this.onOpenSign,
    required this.onSpeedChanged,
    required this.onLoopingChanged,
    required this.onMirroredChanged,
  });

  final SignDetailLoaded state;
  final ValueChanged<Sign> onOpenSign;
  final ValueChanged<PlaybackSpeed> onSpeedChanged;
  final ValueChanged<bool> onLoopingChanged;
  final ValueChanged<bool> onMirroredChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    final sign = state.sign;
    final category = state.category;
    final source = sign.source;

    return ReadableInset(
      minimum: context.windowSizeClass.screenPadding,
      builder: (context, inset) => ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          inset,
          sizes.xs,
          inset,
          sizes.xl,
        ),
        children: [
          SignVideoStage(
            key: ValueKey(sign.id),
            sign: sign,
            playback: state.playback,
            hero: true,
            onSpeedChanged: onSpeedChanged,
            onLoopingChanged: onLoopingChanged,
            onMirroredChanged: onMirroredChanged,
          ),
          SizedBox(height: sizes.lg),
          Semantics(
            header: true,
            child: Text(
              sign.meaning.of(context),
              style: theme.textTheme.headlineSmall,
            ),
          ),
          SizedBox(height: sizes.xxs),
          Text(
            sign.gloss,
            style: context.gTextStyles.gloss.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (category != null) ...[
            SizedBox(height: sizes.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Chip(
                avatar: const ExcludeSemantics(
                  child: Icon(Icons.label_outline_rounded),
                ),
                label: Text(category.name.of(context)),
              ),
            ),
          ],
          SizedBox(height: sizes.lg),
          _Section(
            title: l10n.howToSign,
            child: Text(
              l10n.signDescriptionPending,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          if (state.related.isNotEmpty)
            _Section(
              title: l10n.relatedSigns,
              child: Wrap(
                spacing: sizes.xs,
                runSpacing: sizes.xs,
                children: [
                  for (final other in state.related)
                    ActionChip(
                      label: Text(other.meaning.of(context)),
                      onPressed: () => onOpenSign(other),
                    ),
                ],
              ),
            ),
          if (sign.isPlaceholder)
            const PlaceholderContentNotice()
          else
            Text(
              l10n.signSource(source.name, source.license),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const new({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sizes = context.gSizes;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: sizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          SizedBox(height: sizes.xs),
          child,
        ],
      ),
    );
  }
}

class _SignDetailSkeleton extends StatelessWidget {
  const new({required this.signId});

  static const double lineWidth = 180;
  static const double shortLineWidth = 96;

  final SignId signId;

  @override
  Widget build(BuildContext context) {
    final sizes = context.gSizes;
    final stageHeight =
        MediaQuery.sizeOf(context).height * SignVideoStage.maxHeightFraction;

    return Semantics(
      container: true,
      label: context.l10n.loading,
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: context.windowSizeClass.screenPadding,
            vertical: sizes.xs,
          ),
          child: Column(
            children: [
              SignHero(
                signId: signId,
                child: GSkeleton(
                  width: stageHeight * SignVideoStage.aspectRatio,
                  height: stageHeight,
                  borderRadius: sizes.radiusLg,
                ),
              ),
              SizedBox(height: sizes.xl),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: GSkeleton(width: sizes.scaled(lineWidth)),
              ),
              SizedBox(height: sizes.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: GSkeleton(width: sizes.scaled(shortLineWidth)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
