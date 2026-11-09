import 'package:flutter/material.dart';
import 'package:gestura/core/widgets/failure_view.dart';
import 'package:gestura/core/widgets/list_skeleton.dart';
import 'package:gestura/core/widgets/placeholder_content_notice.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/dictionary/presentation/view_models/dictionary_state.dart';
import 'package:gestura/features/dictionary/presentation/widgets/sign_tile.dart';
import 'package:gestura_ui/gestura_ui.dart';

class DictionaryView extends StatelessWidget {
  const new({required this.state, required this.onRetry, super.key});

  final DictionaryState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final padding = context.windowSizeClass.screenPadding;
    final sizes = context.gSizes;

    return switch (state) {
      DictionaryLoading() => const ListSkeleton(),
      DictionaryFailed(:final failure) => FailureView(
        failure: failure,
        onRetry: onRetry,
      ),
      DictionaryLoaded(:final signs, :final hasPlaceholders) => ReadableInset(
        builder: (context, inset) => ListView(
          padding: EdgeInsetsDirectional.fromSTEB(
            inset,
            sizes.xs,
            inset,
            sizes.xl,
          ),
          children: [
            if (hasPlaceholders)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  padding,
                  0,
                  padding,
                  sizes.sm,
                ),
                child: const PlaceholderContentNotice(),
              ),
            for (final sign in signs) SignTile(sign: sign),
          ],
        ),
      ),
    };
  }
}
