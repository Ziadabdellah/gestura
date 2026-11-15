import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/dictionary/presentation/view_models/dictionary_state.dart';
import 'package:gestura/features/dictionary/presentation/view_models/dictionary_view_model.dart';
import 'package:gestura/features/dictionary/presentation/widgets/dictionary_view.dart';
import 'package:gestura/l10n/l10n.dart';

class DictionaryPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final viewModel = DictionaryViewModel(getIt<ContentRepository>());
      unawaited(viewModel.load());
      return viewModel;
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tabDictionary),
        actions: [
          IconButton(
            tooltip: context.l10n.savedSigns,
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () =>
                unawaited(const SavedSignsRoute().push<void>(context)),
          ),
        ],
      ),
      body: BlocBuilder<DictionaryViewModel, DictionaryState>(
        builder: (context, state) {
          final viewModel = context.read<DictionaryViewModel>();
          return DictionaryView(
            state: state,
            onRetry: () => unawaited(viewModel.load()),
            onSearch: viewModel.search,
            onClearSearch: () => unawaited(viewModel.clearSearch()),
            onCategorySelected: (category) =>
                unawaited(viewModel.selectCategory(category)),
            onOpenSign: (sign) =>
                unawaited(SignRoute(signId: sign.id.value).push<void>(context)),
          );
        },
      ),
    ),
  );
}
