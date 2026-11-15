import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gestura/core/media/media_cache.dart';
import 'package:gestura/core/media/media_image.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/content/presentation/sign_hero.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/lesson/presentation/widgets/video_controls.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';
import 'package:video_player/video_player.dart';

class SignVideoStage extends StatefulWidget {
  const new({
    required this.sign,
    required this.playback,
    required this.onSpeedChanged,
    required this.onLoopingChanged,
    required this.onMirroredChanged,
    super.key,
    this.emptyMessage,
    this.hero = false,
  });

  static const double aspectRatio = 4 / 5;
  static const double maxHeightFraction = 0.34;
  static const double playIconSize = 56;

  final Sign? sign;
  final Playback playback;
  final ValueChanged<PlaybackSpeed> onSpeedChanged;
  final ValueChanged<bool> onLoopingChanged;
  final ValueChanged<bool> onMirroredChanged;
  final String? emptyMessage;
  final bool hero;

  @override
  State<SignVideoStage> createState() => _SignVideoStageState();
}

class _SignVideoStageState extends State<SignVideoStage> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _isPlaying = false;
  bool _autoplay = true;
  bool _started = false;
  int _request = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _autoplay = !MediaQuery.disableAnimationsOf(context);
    if (!_started) {
      _started = true;
      unawaited(_open(widget.sign));
    }
  }

  @override
  void didUpdateWidget(SignVideoStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sign?.media.video != widget.sign?.media.video) {
      _close();
      unawaited(_open(widget.sign));
      return;
    }
    final controller = _controller;
    if (controller == null || !_isReady) return;
    if (oldWidget.playback.looping != widget.playback.looping) {
      unawaited(controller.setLooping(widget.playback.looping));
    }
    if (oldWidget.playback.speed != widget.playback.speed) {
      unawaited(controller.setPlaybackSpeed(widget.playback.speed.rate));
    }
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  Future<void> _open(Sign? sign) async {
    if (sign == null) return;
    final request = ++_request;
    try {
      final controller = switch (sign.media.video) {
        AssetMedia(:final path) => VideoPlayerController.asset(path),
        RemoteMedia(:final uri) => VideoPlayerController.file(
          await getIt<MediaCache>().file(uri),
        ),
      };
      if (request != _request || !mounted) {
        unawaited(controller.dispose());
        return;
      }
      _controller = controller;
      controller.addListener(_onControllerChanged);
      await controller.initialize();
      await controller.setLooping(widget.playback.looping);
      await controller.setPlaybackSpeed(widget.playback.speed.rate);
      if (_autoplay && identical(_controller, controller)) {
        await controller.play();
      }
    } on Object {
      if (request == _request) _close();
    }
  }

  void _close() {
    _request++;
    final controller = _controller;
    _controller = null;
    _isReady = false;
    _isPlaying = false;
    if (controller == null) return;
    controller.removeListener(_onControllerChanged);
    unawaited(controller.dispose());
  }

  void _onControllerChanged() {
    final value = _controller?.value;
    if (value == null) return;
    if (value.isInitialized != _isReady || value.isPlaying != _isPlaying) {
      setState(() {
        _isReady = value.isInitialized;
        _isPlaying = value.isPlaying;
      });
    }
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !_isReady) return;
    unawaited(_isPlaying ? controller.pause() : controller.play());
  }

  void _replay() {
    final controller = _controller;
    if (controller == null || !_isReady) return;
    unawaited(controller.seekTo(Duration.zero).then((_) => controller.play()));
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.gSizes;
    final maxHeight =
        MediaQuery.sizeOf(context).height * SignVideoStage.maxHeightFraction;

    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: AspectRatio(
              aspectRatio: SignVideoStage.aspectRatio,
              child: _withHero(
                ClipRRect(
                  borderRadius: BorderRadius.circular(sizes.radiusLg),
                  child: ColoredBox(
                    color: context.gColors.stage,
                    child: _stage(context),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: sizes.sm),
        VideoControls(
          playback: widget.playback,
          canPlay: _isReady,
          onReplay: _replay,
          onSpeedChanged: widget.onSpeedChanged,
          onLoopingChanged: widget.onLoopingChanged,
          onMirroredChanged: widget.onMirroredChanged,
        ),
      ],
    );
  }

  Widget _withHero(Widget child) => switch (widget.sign) {
    final Sign sign when widget.hero => SignHero(
      signId: sign.id,
      thumbnail: sign.media.thumbnail,
      child: child,
    ),
    _ => child,
  };

  Widget _stage(BuildContext context) {
    final colors = context.gColors;
    final sizes = context.gSizes;
    final sign = widget.sign;
    final controller = _controller;

    if (sign == null) {
      return Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(sizes.lg),
          child: Text(
            widget.emptyMessage ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: colors.onStage),
          ),
        ),
      );
    }

    final l10n = context.l10n;
    return Semantics(
      label: l10n.signVideo,
      button: _isReady,
      onTap: _isReady ? _togglePlay : null,
      onTapHint: _isPlaying ? l10n.videoPause : l10n.videoPlay,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _togglePlay,
        child: Transform.flip(
          flipX: widget.playback.mirrored,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaImage(media: sign.media.thumbnail),
              if (_isReady && controller != null)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox.fromSize(
                    size: controller.value.size,
                    child: VideoPlayer(controller),
                  ),
                ),
              if (_isReady && !_isPlaying)
                Center(
                  child: ExcludeSemantics(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.stage.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.all(sizes.xs),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: sizes.icon(SignVideoStage.playIconSize),
                          color: colors.onStage,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
