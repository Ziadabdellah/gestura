import 'package:equatable/equatable.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura_core/gestura_core.dart';

enum OnboardingStep {
  welcome,
  signLanguage,
  dailyGoal,
  hand,
  privacy;

  bool get canSkip => this == dailyGoal || this == hand;
}

sealed class PacksStatus extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class PacksLoading extends PacksStatus {
  const new();
}

final class PacksReady extends PacksStatus {
  const new(this.packs);

  final List<SignLanguagePack> packs;

  @override
  List<Object?> get props => [packs];
}

final class PacksFailed extends PacksStatus {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class OnboardingState extends Equatable {
  const new({
    this.step = OnboardingStep.welcome,
    this.packs = const PacksLoading(),
  });

  static final int stepCount = OnboardingStep.values.length;

  final OnboardingStep step;
  final PacksStatus packs;

  int get stepNumber => step.index + 1;

  bool get isFirst => step == OnboardingStep.values.first;

  bool get isLast => step == OnboardingStep.values.last;

  bool get canContinue =>
      step != OnboardingStep.signLanguage || packs is PacksReady;

  String? packCodeFor(String? chosen) => switch (packs) {
    PacksReady(:final packs) =>
      packs.any((pack) => pack.code == chosen)
          ? chosen
          : packs.firstOrNull?.code,
    PacksLoading() || PacksFailed() => null,
  };

  OnboardingState copyWith({OnboardingStep? step, PacksStatus? packs}) =>
      OnboardingState(step: step ?? this.step, packs: packs ?? this.packs);

  @override
  List<Object?> get props => [step, packs];
}
