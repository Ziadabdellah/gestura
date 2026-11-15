import 'package:flutter/material.dart';
import 'package:gestura/core/widgets/failure_view.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/lesson/presentation/widgets/sign_video_stage.dart';
import 'package:gestura/features/practice/presentation/view_models/practice_state.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class PracticeView extends StatelessWidget {
  const new({
    required this.state,
    required this.onRetry,
    required this.onRetryCamera,
    required this.onSpeedChanged,
    required this.onLoopingChanged,
    required this.onMirroredChanged,
    super.key,
  });

  final PracticeState state;
  final VoidCallback onRetry;
  final VoidCallback onRetryCamera;
  final ValueChanged<PlaybackSpeed> onSpeedChanged;
  final ValueChanged<bool> onLoopingChanged;
  final ValueChanged<bool> onMirroredChanged;

  @override
  Widget build(BuildContext context) => switch (state) {
    PracticeLoading() => const Center(child: CircularProgressIndicator()),
    PracticeFailed(:final failure) => FailureView(
      failure: failure,
      onRetry: onRetry,
    ),
    final PracticeReady ready => _Ready(
      state: ready,
      onRetryCamera: onRetryCamera,
      onSpeedChanged: onSpeedChanged,
      onLoopingChanged: onLoopingChanged,
      onMirroredChanged: onMirroredChanged,
    ),
  };
}

class _Ready extends StatelessWidget {
  const new({
    required this.state,
    required this.onRetryCamera,
    required this.onSpeedChanged,
    required this.onLoopingChanged,
    required this.onMirroredChanged,
  });

  static const double minCameraHeight = 220;
  static const Size previewSize = Size(300, 400);

  final PracticeReady state;
  final VoidCallback onRetryCamera;
  final ValueChanged<PlaybackSpeed> onSpeedChanged;
  final ValueChanged<bool> onLoopingChanged;
  final ValueChanged<bool> onMirroredChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    final camera = switch (state.camera) {
      CameraStatus.starting => const Center(child: CircularProgressIndicator()),
      CameraStatus.live => Semantics(
        label: l10n.practiceCameraLabel,
        image: true,
        child: ExcludeSemantics(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: previewSize.width,
              height: previewSize.height,
              child: state.session!.preview(),
            ),
          ),
        ),
      ),
      CameraStatus.denied => _Message(
        icon: Icons.no_photography_outlined,
        text: l10n.practiceCameraDenied,
        action: l10n.retry,
        onAction: onRetryCamera,
      ),
      CameraStatus.missing => _Message(
        icon: Icons.videocam_off_outlined,
        text: l10n.practiceCameraMissing,
      ),
    };
    return ReadableInset(
      minimum: context.windowSizeClass.screenPadding,
      builder: (context, inset) => CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              inset,
              sizes.sm,
              inset,
              sizes.md,
            ),
            sliver: SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  SignVideoStage(
                    sign: state.sign,
                    playback: state.playback,
                    onSpeedChanged: onSpeedChanged,
                    onLoopingChanged: onLoopingChanged,
                    onMirroredChanged: onMirroredChanged,
                  ),
                  SizedBox(height: sizes.sm),
                  Text(
                    l10n.practiceHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: sizes.sm),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: minCameraHeight,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(sizes.radiusLg),
                        child: ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Stack(
                            children: [Positioned.fill(child: camera)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const new({
    required this.icon,
    required this.text,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.all(sizes.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: sizes.xs),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (action case final String action) ...[
            SizedBox(height: sizes.sm),
            GButton.secondary(label: action, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
