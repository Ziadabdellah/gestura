import 'package:flutter/material.dart';
import 'package:gestura/core/widgets/failure_view.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/fingerspelling/presentation/view_models/fingerspelling_state.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/lesson/presentation/widgets/sign_video_stage.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class FingerspellingView extends StatelessWidget {
  const new({
    required this.state,
    required this.onRetry,
    required this.onSelect,
    required this.onSpell,
    required this.onSpeedChanged,
    required this.onLoopingChanged,
    required this.onMirroredChanged,
    super.key,
  });

  final FingerspellingState state;
  final VoidCallback onRetry;
  final ValueChanged<Sign> onSelect;
  final ValueChanged<String> onSpell;
  final ValueChanged<PlaybackSpeed> onSpeedChanged;
  final ValueChanged<bool> onLoopingChanged;
  final ValueChanged<bool> onMirroredChanged;

  @override
  Widget build(BuildContext context) => switch (state) {
    FingerspellingLoading() => const Center(child: CircularProgressIndicator()),
    FingerspellingFailed(:final failure) => FailureView(
      failure: failure,
      onRetry: onRetry,
    ),
    FingerspellingEmpty() => Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(context.gSizes.xl),
        child: Text(
          context.l10n.fingerspellingEmpty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ),
    final FingerspellingReady ready => _Ready(
      state: ready,
      onSelect: onSelect,
      onSpell: onSpell,
      onSpeedChanged: onSpeedChanged,
      onLoopingChanged: onLoopingChanged,
      onMirroredChanged: onMirroredChanged,
    ),
  };
}

class _Ready extends StatelessWidget {
  const new({
    required this.state,
    required this.onSelect,
    required this.onSpell,
    required this.onSpeedChanged,
    required this.onLoopingChanged,
    required this.onMirroredChanged,
  });

  static const double letterSize = 52;

  final FingerspellingReady state;
  final ValueChanged<Sign> onSelect;
  final ValueChanged<String> onSpell;
  final ValueChanged<PlaybackSpeed> onSpeedChanged;
  final ValueChanged<bool> onLoopingChanged;
  final ValueChanged<bool> onMirroredChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    final size = sizes.scaled(letterSize);

    Widget letter(Sign sign, {String? semanticsSuffix}) {
      final selected = sign == state.selected;
      return Semantics(
        selected: selected,
        button: true,
        label: l10n.fingerspellingLetter(sign.gloss),
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: size,
          child: Material(
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(sizes.radiusSm),
            child: InkWell(
              borderRadius: BorderRadius.circular(sizes.radiusSm),
              onTap: () => onSelect(sign),
              child: Center(
                child: Text(
                  sign.gloss,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ReadableInset(
      minimum: context.windowSizeClass.screenPadding,
      builder: (context, inset) => ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          inset,
          sizes.sm,
          inset,
          sizes.xl,
        ),
        children: [
          SignVideoStage(
            sign: state.selected,
            playback: state.playback,
            onSpeedChanged: onSpeedChanged,
            onLoopingChanged: onLoopingChanged,
            onMirroredChanged: onMirroredChanged,
          ),
          SizedBox(height: sizes.md),
          TextField(
            decoration: InputDecoration(
              labelText: l10n.fingerspellingSpell,
              prefixIcon: const Icon(Icons.edit_outlined),
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: onSpell,
          ),
          if (state.word.isNotEmpty) ...[
            SizedBox(height: sizes.sm),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                spacing: sizes.xs,
                runSpacing: sizes.xs,
                children: [for (final sign in state.word) letter(sign)],
              ),
            ),
          ],
          SizedBox(height: sizes.lg),
          Semantics(
            header: true,
            child: Text(
              l10n.fingerspellingAlphabet,
              style: theme.textTheme.titleMedium,
            ),
          ),
          SizedBox(height: sizes.sm),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              spacing: sizes.xs,
              runSpacing: sizes.xs,
              children: [for (final sign in state.letters) letter(sign)],
            ),
          ),
        ],
      ),
    );
  }
}
