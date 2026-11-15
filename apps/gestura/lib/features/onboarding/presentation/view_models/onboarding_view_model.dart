import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/onboarding/presentation/view_models/onboarding_state.dart';
import 'package:gestura_core/gestura_core.dart';

class OnboardingViewModel extends Cubit<OnboardingState> {
  new(this._content) : super(const OnboardingState());

  final ContentRepository _content;

  Future<void> loadPacks() async {
    if (state.packs is! PacksLoading) {
      emit(state.copyWith(packs: const PacksLoading()));
    }
    final result = await _content.pack();
    if (isClosed) return;
    emit(
      state.copyWith(
        packs: switch (result) {
          Ok(value: final pack) => PacksReady([pack]),
          Err(failure: NoContentFailure()) => const PacksReady([]),
          Err(:final failure) => PacksFailed(failure),
        },
      ),
    );
  }

  void next() {
    if (state.isLast || !state.canContinue) return;
    emit(state.copyWith(step: OnboardingStep.values[state.step.index + 1]));
  }

  void back() {
    if (state.isFirst) return;
    emit(state.copyWith(step: OnboardingStep.values[state.step.index - 1]));
  }

  void skip() {
    if (!state.step.canSkip) return;
    emit(state.copyWith(step: OnboardingStep.privacy));
  }
}
