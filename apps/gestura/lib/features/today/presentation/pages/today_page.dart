import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:gestura/features/today/presentation/view_models/today_state.dart';
import 'package:gestura/features/today/presentation/view_models/today_view_model.dart';
import 'package:gestura/features/today/presentation/widgets/today_view.dart';
import 'package:gestura/l10n/l10n.dart';

class TodayPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(
      settingsViewModelProvider.select((state) => state.settings.dailyGoal),
    );
    return BlocProvider(
      create: (_) {
        final viewModel = TodayViewModel(
          getIt<ContentRepository>(),
          getIt<ProgressRepository>(),
          getIt<ReviewRepository>(),
          getIt<ActivityRepository>(),
        );
        unawaited(viewModel.load());
        return viewModel;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.tabToday)),
        body: BlocBuilder<TodayViewModel, TodayState>(
          builder: (context, state) => TodayView(
            state: state,
            goalMinutes: goal.minutes,
            onRetry: () => unawaited(context.read<TodayViewModel>().load()),
            onOpenLesson: (lesson) => unawaited(
              LessonRoute(lessonId: lesson.lesson.id.value).push<void>(context),
            ),
            onReview: () => unawaited(const ReviewRoute().push<void>(context)),
            onOpenSign: (sign) => SignRoute(signId: sign.id.value).go(context),
          ),
        ),
      ),
    );
  }
}
