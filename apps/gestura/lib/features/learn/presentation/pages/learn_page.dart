import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/learn/presentation/view_models/learn_state.dart';
import 'package:gestura/features/learn/presentation/view_models/learn_view_model.dart';
import 'package:gestura/features/learn/presentation/widgets/learn_view.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/l10n/l10n.dart';

class LearnPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final viewModel = LearnViewModel(
        getIt<ContentRepository>(),
        getIt<ProgressRepository>(),
      );
      unawaited(viewModel.load());
      return viewModel;
    },
    child: Scaffold(
      appBar: AppBar(title: Text(context.l10n.tabLearn)),
      body: BlocBuilder<LearnViewModel, LearnState>(
        builder: (context, state) => LearnView(
          state: state,
          onRetry: () => unawaited(context.read<LearnViewModel>().load()),
          onLessonSelected: (lesson) => unawaited(
            LessonRoute(lessonId: lesson.value).push<void>(context),
          ),
        ),
      ),
    ),
  );
}
