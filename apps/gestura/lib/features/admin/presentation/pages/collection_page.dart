import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/admin/data/content_store.dart';
import 'package:gestura/features/admin/domain/content_doc.dart';
import 'package:gestura/features/admin/domain/content_kind.dart';
import 'package:gestura/features/admin/presentation/view_models/collection_cubit.dart';
import 'package:gestura/features/admin/presentation/widgets/content_labels.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class CollectionPage extends StatelessWidget {
  const new({required this.kind, super.key});

  final ContentKind kind;

  Future<void> _delete(BuildContext context, ContentDoc doc) async {
    final l10n = context.l10n;
    final cubit = context.read<CollectionCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.adminDeleteTitle(doc.id)),
        content: Text(l10n.adminDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.adminCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.adminDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final done = await cubit.delete(doc.id);
    messenger.showSnackBar(
      SnackBar(content: Text(done ? l10n.adminDeleted : l10n.adminSaveFailed)),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CollectionCubit(getIt<ContentStore>(), kind)..load(),
    child: Builder(builder: _build),
  );

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;
    final padding = context.windowSizeClass.screenPadding;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.gColors;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.kindLabel(kind))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            unawaited(AdminNewRoute(kind: kind.collection).push<void>(context)),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.adminAdd),
      ),
      body: BlocBuilder<CollectionCubit, CollectionState>(
        builder: (context, state) => switch (state) {
          CollectionLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          CollectionFailed() => GErrorView(
            title: l10n.adminLoadFailed,
            message: l10n.failureNetwork,
            action: (
              label: l10n.adminTryAgain,
              onPressed: context.read<CollectionCubit>().load,
            ),
          ),
          final CollectionReady ready => Column(
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  padding,
                  sizes.xs,
                  padding,
                  sizes.xs,
                ),
                child: TextField(
                  onChanged: context.read<CollectionCubit>().search,
                  decoration: InputDecoration(
                    hintText: l10n.adminSearch,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
              Expanded(
                child: switch (ready.visible(kind)) {
                  [] => GEmptyState(
                    icon: kindIcon(kind),
                    title: l10n.adminEmptyTitle,
                    message: l10n.adminEmptyMessage,
                  ),
                  final docs => ListView.separated(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      padding,
                      sizes.xs,
                      padding,
                      sizes.xxl * 2,
                    ),
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => SizedBox(height: sizes.xs),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final title = kind.titleOf(doc.data);
                      return GCard(
                        tone: GCardTone.low,
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          onTap: () => unawaited(
                            AdminEditRoute(
                              kind: kind.collection,
                              id: doc.id,
                            ).push<void>(context),
                          ),
                          title: Text(title.isEmpty ? doc.id : title),
                          subtitle: Text(doc.id),
                          leading: Icon(
                            doc.published
                                ? Icons.public_rounded
                                : Icons.edit_note_rounded,
                            color: doc.published
                                ? colors.success
                                : scheme.onSurfaceVariant,
                            semanticLabel: doc.published
                                ? l10n.adminPublished
                                : l10n.adminDraft,
                          ),
                          trailing: IconButton(
                            tooltip: l10n.adminDelete,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: scheme.error,
                            ),
                            onPressed: () => _delete(context, doc),
                          ),
                        ),
                      );
                    },
                  ),
                },
              ),
            ],
          ),
        },
      ),
    );
  }
}
