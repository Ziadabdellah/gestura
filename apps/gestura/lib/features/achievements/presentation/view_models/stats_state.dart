import 'package:equatable/equatable.dart';
import 'package:gestura/features/achievements/domain/learner_stats.dart';
import 'package:gestura_core/gestura_core.dart';

sealed class StatsState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class StatsLoading extends StatsState {
  const new();
}

final class StatsFailed extends StatsState {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class StatsReady extends StatsState {
  const new(this.stats);

  final LearnerStats stats;

  @override
  List<Object?> get props => [stats];
}
