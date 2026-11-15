import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/core/media/media_image.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_state.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_view_model.dart';
import 'package:gestura/features/lesson/presentation/widgets/choice_tile.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class ChooseVideoQuiz extends StatelessWidget {
  const new({required this.state, required this.step, super.key});

  static const double thumbnailAspectRatio = 4 / 5;

  final LessonInProgress state;
  final ChooseVideoStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    final viewModel = context.read<LessonPlayerViewModel>();
    final word = state.signOf(step.sign).meaning.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.chooseVideoPrompt(word),
            style: theme.textTheme.titleLarge,
          ),
        ),
        SizedBox(height: sizes.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, id) in step.options.indexed) ...[
                if (index > 0) SizedBox(width: sizes.xs),
                Expanded(
                  child: ChoiceTile(
                    mark: state.markOf(id),
                    semanticLabel: l10n.videoOption(index + 1),
                    padding: EdgeInsetsDirectional.all(sizes.xxs),
                    markOnTop: true,
                    onTap: state.isChecked ? null : () => viewModel.select(id),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(sizes.radiusSm),
                          child: AspectRatio(
                            aspectRatio: thumbnailAspectRatio,
                            child: MediaImage(
                              media: state.signOf(id).media.thumbnail,
                            ),
                          ),
                        ),
                        SizedBox(height: sizes.xxs),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
