import 'package:flutter/material.dart';
import 'package:gestura/core/widgets/failure_view.dart';
import 'package:gestura/core/widgets/list_skeleton.dart';
import 'package:gestura/core/widgets/placeholder_content_notice.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/dictionary/presentation/view_models/dictionary_state.dart';
import 'package:gestura/features/dictionary/presentation/widgets/category_filter_bar.dart';
import 'package:gestura/features/dictionary/presentation/widgets/dictionary_search_field.dart';
import 'package:gestura/features/dictionary/presentation/widgets/sign_tile.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class DictionaryView extends StatefulWidget {
  const new({
    required this.state,
    required this.onRetry,
    required this.onSearch,
    required this.onClearSearch,
    required this.onCategorySelected,
    required this.onOpenSign,
    super.key,
  });

  final DictionaryState state;
  final VoidCallback onRetry;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;
  final ValueChanged<CategoryId?> onCategorySelected;
  final ValueChanged<Sign> onOpenSign;

  @override
  State<DictionaryView> createState() => _DictionaryViewState();
}

class _DictionaryViewState extends State<DictionaryView> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _clear() {
    _query.clear();
    widget.onClearSearch();
  }

  @override
  Widget build(BuildContext context) => ReadableInset(
    builder: (context, inset) {
      final padding = inset + context.windowSizeClass.screenPadding;
      final sizes = context.gSizes;
      return Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              padding,
              sizes.xxs,
              padding,
              sizes.xs,
            ),
            child: DictionarySearchField(
              controller: _query,
              onChanged: widget.onSearch,
              onCleared: _clear,
            ),
          ),
          Expanded(
            child: switch (widget.state) {
              DictionaryLoading() => const ListSkeleton(),
              DictionaryFailed(:final failure) => FailureView(
                failure: failure,
                onRetry: widget.onRetry,
              ),
              final DictionaryLoaded loaded => _Results(
                state: loaded,
                inset: inset,
                onClearSearch: _clear,
                onCategorySelected: widget.onCategorySelected,
                onOpenSign: widget.onOpenSign,
              ),
            },
          ),
        ],
      );
    },
  );
}

sealed class _Row {
  const new();
}

final class _NoticeRow extends _Row {
  const new();
}

final class _HeaderRow extends _Row {
  const new(this.initial);

  final String initial;
}

final class _SignRow extends _Row {
  const new(this.sign);

  final Sign sign;
}

class _Results extends StatelessWidget {
  const new({
    required this.state,
    required this.inset,
    required this.onClearSearch,
    required this.onCategorySelected,
    required this.onOpenSign,
  });

  final DictionaryLoaded state;
  final double inset;
  final VoidCallback onClearSearch;
  final ValueChanged<CategoryId?> onCategorySelected;
  final ValueChanged<Sign> onOpenSign;

  List<_Row> get _rows => [
    if (state.hasPlaceholders) const _NoticeRow(),
    for (final section in state.sections) ...[
      if (section.initial.isNotEmpty) _HeaderRow(section.initial),
      for (final sign in section.signs) _SignRow(sign),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;
    final padding = context.windowSizeClass.screenPadding;
    final rows = _rows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoryFilterBar(
          categories: state.categories,
          selected: state.category,
          onSelected: onCategorySelected,
          padding: inset + padding,
        ),
        if (state.results.isNotEmpty)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                inset + padding,
                sizes.xs,
                inset + padding,
                sizes.xxs,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.signResultCount(state.results.length),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: state.results.isEmpty
              ? _NoResults(
                  state: state,
                  onClearSearch: onClearSearch,
                  onShowAll: () => onCategorySelected(null),
                )
              : ListView.builder(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    inset,
                    0,
                    inset,
                    sizes.xl,
                  ),
                  itemCount: rows.length,
                  itemBuilder: (context, index) => switch (rows[index]) {
                    _NoticeRow() => Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        padding,
                        sizes.xs,
                        padding,
                        sizes.xs,
                      ),
                      child: const PlaceholderContentNotice(),
                    ),
                    _HeaderRow(:final initial) => Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        padding,
                        sizes.sm,
                        padding,
                        sizes.xxs,
                      ),
                      child: Semantics(
                        header: true,
                        child: Text(
                          initial,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ),
                    _SignRow(:final sign) => SignTile(
                      sign: sign,
                      onTap: () => onOpenSign(sign),
                    ),
                  },
                ),
        ),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const new({
    required this.state,
    required this.onClearSearch,
    required this.onShowAll,
  });

  final DictionaryLoaded state;
  final VoidCallback onClearSearch;
  final VoidCallback onShowAll;

  static const double iconSize = 48;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    final searching = state.isSearching;

    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.all(sizes.xl),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.search_off_rounded,
              size: sizes.icon(iconSize),
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: sizes.md),
          Semantics(
            liveRegion: true,
            child: Text(
              searching
                  ? l10n.noSignsFound(state.query.trim())
                  : l10n.noSignsInCategory,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          SizedBox(height: sizes.md),
          if (searching)
            GButton.secondary(
              label: l10n.clearSearch,
              icon: Icons.close_rounded,
              onPressed: onClearSearch,
            )
          else
            GButton.secondary(label: l10n.categoryAll, onPressed: onShowAll),
        ],
      ),
    );
  }
}
