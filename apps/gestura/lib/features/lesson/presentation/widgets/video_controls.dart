import 'package:flutter/material.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class VideoControls extends StatelessWidget {
  const new({
    required this.playback,
    required this.canPlay,
    required this.onReplay,
    required this.onSpeedChanged,
    required this.onLoopingChanged,
    required this.onMirroredChanged,
    super.key,
  });

  final Playback playback;
  final bool canPlay;
  final VoidCallback onReplay;
  final ValueChanged<PlaybackSpeed> onSpeedChanged;
  final ValueChanged<bool> onLoopingChanged;
  final ValueChanged<bool> onMirroredChanged;

  String _speedLabel(AppLocalizations l10n, PlaybackSpeed speed) =>
      switch (speed) {
        PlaybackSpeed.half => l10n.speedHalf,
        PlaybackSpeed.threeQuarters => l10n.speedThreeQuarters,
        PlaybackSpeed.normal => l10n.speedNormal,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;

    return Column(
      children: [
        Semantics(
          container: true,
          label: l10n.videoSpeed,
          child: SegmentedButton<PlaybackSpeed>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            segments: [
              for (final speed in PlaybackSpeed.values)
                ButtonSegment(
                  value: speed,
                  label: Text(
                    _speedLabel(l10n, speed),
                    textDirection: TextDirection.ltr,
                  ),
                ),
            ],
            selected: {playback.speed},
            onSelectionChanged: (selection) => onSpeedChanged(selection.single),
          ),
        ),
        SizedBox(height: sizes.xxs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: l10n.videoReplay,
              onPressed: canPlay ? onReplay : null,
              icon: const Icon(Icons.replay_rounded),
            ),
            IconButton(
              tooltip: l10n.videoLoop,
              isSelected: playback.looping,
              onPressed: () => onLoopingChanged(!playback.looping),
              icon: const Icon(Icons.repeat_rounded),
              selectedIcon: const Icon(Icons.repeat_on_rounded),
            ),
            IconButton(
              tooltip: l10n.videoMirror,
              isSelected: playback.mirrored,
              onPressed: () => onMirroredChanged(!playback.mirrored),
              icon: const Icon(Icons.flip_outlined),
              selectedIcon: const Icon(Icons.flip_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
