import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/onboarding/presentation/view_models/onboarding_state.dart';
import 'package:gestura/features/onboarding/presentation/view_models/onboarding_view_model.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../../helpers/fake_content_repository.dart';

final PacksReady _ready = PacksReady([demoCatalog.pack]);

OnboardingState _at(OnboardingStep step) =>
    OnboardingState(step: step, packs: _ready);

void main() {
  late FakeContentRepository content;

  setUp(() => content = FakeContentRepository());

  test('starts on the welcome step while the packs load', () {
    final state = OnboardingViewModel(content).state;

    expect(state, const OnboardingState());
    expect(state.stepNumber, 1);
    expect(OnboardingState.stepCount, 5);
    expect(state.isFirst, isTrue);
    expect(state.isLast, isFalse);
  });

  blocTest<OnboardingViewModel, OnboardingState>(
    'loads the available sign language packs',
    build: () => OnboardingViewModel(content),
    act: (viewModel) => viewModel.loadPacks(),
    expect: () => [OnboardingState(packs: _ready)],
  );

  blocTest<OnboardingViewModel, OnboardingState>(
    'reports packs that fail to load and loads them again',
    build: () => OnboardingViewModel(content),
    act: (viewModel) async {
      content.failure = const NetworkFailure();
      await viewModel.loadPacks();
      content.failure = null;
      await viewModel.loadPacks();
    },
    expect: () => [
      const OnboardingState(packs: PacksFailed(NetworkFailure())),
      const OnboardingState(),
      OnboardingState(packs: _ready),
    ],
  );

  blocTest<OnboardingViewModel, OnboardingState>(
    'lets the learner continue while no pack is published',
    build: () => OnboardingViewModel(content),
    act: (viewModel) async {
      content.failure = const NoContentFailure();
      await viewModel.loadPacks();
      viewModel.next();
    },
    expect: () => [
      const OnboardingState(packs: PacksReady([])),
      const OnboardingState(
        step: OnboardingStep.signLanguage,
        packs: PacksReady([]),
      ),
    ],
    verify: (viewModel) {
      expect(viewModel.state.canContinue, isTrue);
      expect(viewModel.state.packCodeFor(null), isNull);
    },
  );

  blocTest<OnboardingViewModel, OnboardingState>(
    'walks forward through every step and stops at the last one',
    build: () => OnboardingViewModel(content),
    seed: () => OnboardingState(packs: _ready),
    act: (viewModel) {
      for (var i = 0; i < 6; i++) {
        viewModel.next();
      }
    },
    expect: () => [
      _at(OnboardingStep.signLanguage),
      _at(OnboardingStep.dailyGoal),
      _at(OnboardingStep.hand),
      _at(OnboardingStep.privacy),
    ],
    verify: (viewModel) => expect(viewModel.state.isLast, isTrue),
  );

  blocTest<OnboardingViewModel, OnboardingState>(
    'waits for the packs before leaving the sign language step',
    build: () => OnboardingViewModel(content),
    seed: () => const OnboardingState(step: OnboardingStep.signLanguage),
    act: (viewModel) => viewModel.next(),
    expect: () => <OnboardingState>[],
    verify: (viewModel) => expect(viewModel.state.canContinue, isFalse),
  );

  blocTest<OnboardingViewModel, OnboardingState>(
    'walks back and stops at the first step',
    build: () => OnboardingViewModel(content),
    seed: () => _at(OnboardingStep.dailyGoal),
    act: (viewModel) => viewModel
      ..back()
      ..back()
      ..back(),
    expect: () => [
      _at(OnboardingStep.signLanguage),
      _at(OnboardingStep.welcome),
    ],
  );

  blocTest<OnboardingViewModel, OnboardingState>(
    'skips to privacy only from the goal and hand steps',
    build: () => OnboardingViewModel(content),
    seed: () => _at(OnboardingStep.signLanguage),
    act: (viewModel) => viewModel
      ..skip()
      ..next()
      ..skip(),
    expect: () => [_at(OnboardingStep.dailyGoal), _at(OnboardingStep.privacy)],
  );

  test('only the goal and hand steps can be skipped', () {
    expect(
      [
        for (final step in OnboardingStep.values)
          if (step.canSkip) step,
      ],
      [OnboardingStep.dailyGoal, OnboardingStep.hand],
    );
  });

  test('picks the chosen pack, or the first one', () {
    expect(_at(OnboardingStep.signLanguage).packCodeFor(null), 'demo');
    expect(_at(OnboardingStep.signLanguage).packCodeFor('demo'), 'demo');
    expect(_at(OnboardingStep.signLanguage).packCodeFor('gone'), 'demo');
    expect(
      const OnboardingState(packs: PacksReady([])).packCodeFor(null),
      isNull,
    );
    expect(const OnboardingState().packCodeFor('demo'), isNull);
    expect(
      const OnboardingState(packs: PacksFailed(NetworkFailure()))
          .packCodeFor('demo'),
      isNull,
    );
  });

  test('stays quiet when closed before the packs arrive', () async {
    final hold = content.hold = Completer<void>();
    final viewModel = OnboardingViewModel(content);

    final loading = viewModel.loadPacks();
    await viewModel.close();
    hold.complete();
    await loading;

    expect(viewModel.state, const OnboardingState());
  });
}
