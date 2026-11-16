import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/achievements/presentation/view_models/stats_state.dart';
import 'package:gestura/features/achievements/presentation/view_models/stats_view_model.dart';
import 'package:gestura/features/achievements/presentation/widgets/stats_view.dart';
import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
import 'package:gestura/l10n/l10n.dart';

class StatsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => StatsViewModel(
      getIt<ProgressRepository>(),
      getIt<ReviewRepository>(),
      getIt<ActivityRepository>(),
      clock: getIt<Clock>(),
    )..start(),
    child: Scaffold(
      appBar: AppBar(title: Text(context.l10n.statsTitle)),
      body: BlocBuilder<StatsViewModel, StatsState>(
        builder: (context, state) => StatsView(
          state: state,
          onRetry: context.read<StatsViewModel>().start,
        ),
      ),
    ),
  );
}
