import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_state.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_view_model.dart';
import 'package:gestura/features/lesson/presentation/widgets/choice_tile.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class ChooseWordQuiz extends StatelessWidget {
  const new({required this.state, required this.step, super.key});

  final LessonInProgress state;
  final ChooseWordStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    final viewModel = context.read<LessonPlayerViewModel>();

    Widget option(SignId id) {
      final meaning = state.signOf(id).meaning.of(context);
      return ChoiceTile(
        mark: state.markOf(id),
        semanticLabel: meaning,
        onTap: state.isChecked ? null : () => viewModel.select(id),
        child: Text(meaning, style: theme.textTheme.titleMedium),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            context.l10n.chooseWordPrompt,
            style: theme.textTheme.titleLarge,
          ),
        ),
        SizedBox(height: sizes.md),
        for (final (index, pair) in [
          step.options.take(2).toList(),
          step.options.skip(2).toList(),
        ].indexed) ...[
          if (index > 0) SizedBox(height: sizes.xs),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (column, id) in pair.indexed) ...[
                  if (column > 0) SizedBox(width: sizes.xs),
                  Expanded(child: option(id)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
