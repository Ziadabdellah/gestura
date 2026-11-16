import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/admin/data/content_store.dart';
import 'package:gestura/features/admin/domain/content_doc.dart';
import 'package:gestura/features/admin/domain/content_kind.dart';
import 'package:gestura/features/admin/presentation/widgets/content_labels.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class AdminHomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;
    final store = getIt<ContentStore>();
    final padding = context.windowSizeClass.screenPadding;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminDashboard)),
      body: ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          padding,
          sizes.xs,
          padding,
          sizes.xl,
        ),
        children: [
          for (final kind in ContentKind.values) ...[
            StreamBuilder<List<ContentDoc>>(
              stream: store.watch(kind),
              builder: (context, snapshot) {
                final docs = snapshot.data;
                final published = docs?.where((doc) => doc.published).length;
                return GCard(
                  tone: GCardTone.low,
                  onTap: () => unawaited(
                    AdminCollectionRoute(kind: kind.collection)
                        .push<void>(context),
                  ),
                  semanticLabel: l10n.kindLabel(kind),
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(sizes.radiusMd),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.all(sizes.sm),
                          child: Icon(
                            kindIcon(kind),
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                      SizedBox(width: sizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.kindLabel(kind),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              docs == null
                                  ? '…'
                                  : '${l10n.adminItems(docs.length)} · '
                                        '${l10n.adminPublished} $published',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: sizes.sm),
          ],
        ],
      ),
    );
  }
}
