import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/saved/domain/saved_signs_repository.dart';
import 'package:gestura/features/saved/presentation/view_models/saved_signs_state.dart';
import 'package:gestura/features/saved/presentation/view_models/saved_signs_view_model.dart';
import 'package:gestura/features/saved/presentation/widgets/saved_signs_view.dart';
import 'package:gestura/l10n/l10n.dart';

class SavedSignsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SavedSignsViewModel(
      getIt<ContentRepository>(),
      getIt<SavedSignsRepository>(),
    )..start(),
    child: Scaffold(
      appBar: AppBar(title: Text(context.l10n.savedSigns)),
      body: BlocBuilder<SavedSignsViewModel, SavedSignsState>(
        builder: (context, state) => SavedSignsView(
          state: state,
          onRetry: context.read<SavedSignsViewModel>().start,
          onOpenSign: (sign) =>
              unawaited(SignRoute(signId: sign.id.value).push<void>(context)),
        ),
      ),
    ),
  );
}
