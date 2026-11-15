import 'package:flutter/material.dart';
import 'package:gestura/core/widgets/failure_view.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/dictionary/presentation/widgets/sign_tile.dart';
import 'package:gestura/features/saved/presentation/view_models/saved_signs_state.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class SavedSignsView extends StatelessWidget {
  const new({
    required this.state,
    required this.onRetry,
    required this.onOpenSign,
    super.key,
  });

  static const double iconSize = 48;

  final SavedSignsState state;
  final VoidCallback onRetry;
  final ValueChanged<Sign> onOpenSign;

  @override
  Widget build(BuildContext context) => switch (state) {
    SavedSignsLoading() => const Center(child: CircularProgressIndicator()),
    SavedSignsFailed(:final failure) => FailureView(
      failure: failure,
      onRetry: onRetry,
    ),
    SavedSignsLoaded(:final signs) when signs.isEmpty => const _Empty(),
    SavedSignsLoaded(:final signs) => ReadableInset(
      builder: (context, inset) => ListView.builder(
        padding: EdgeInsetsDirectional.fromSTEB(
          inset,
          0,
          inset,
          context.gSizes.xl,
        ),
        itemCount: signs.length,
        itemBuilder: (context, index) =>
            SignTile(sign: signs[index], onTap: () => onOpenSign(signs[index])),
      ),
    ),
  };
}

class _Empty extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.all(sizes.xl),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.favorite_border_rounded,
              size: sizes.icon(SavedSignsView.iconSize),
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: sizes.md),
          Semantics(
            header: true,
            child: Text(
              l10n.savedEmptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          SizedBox(height: sizes.xs),
          Text(
            l10n.savedEmptyMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
