import 'package:equatable/equatable.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/lesson/domain/lesson_result.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura_core/gestura_core.dart';

enum OptionMark { none, selected, correct, wrong }

sealed class LessonPlayerState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class LessonPlayerLoading extends LessonPlayerState {
  const new();
}

final class LessonPlayerFailed extends LessonPlayerState {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class LessonInProgress extends LessonPlayerState {
  const new({
    required this.lesson,
    required this.signs,
    this.stepIndex = 0,
    this.selected,
    this.isChecked = false,
    this.correctAnswers = 0,
    this.playback = const Playback(),
  });

  final Lesson lesson;
  final Map<SignId, Sign> signs;
  final int stepIndex;
  final SignId? selected;
  final bool isChecked;
  final int correctAnswers;
  final Playback playback;

  LessonStep get step => lesson.steps[stepIndex];

  int get stepCount => lesson.steps.length;

  bool get isLastStep => stepIndex == stepCount - 1;

  bool get isQuiz => step is! LearnSignStep;

  bool get isCorrect => selected == step.sign;

  bool get canContinue => !isQuiz || isChecked;

  Sign signOf(SignId id) => signs[id]!;

  Sign? get videoSign => switch (step) {
    ChooseVideoStep() => selected == null ? null : signOf(selected!),
    _ => signOf(step.sign),
  };

  OptionMark markOf(SignId option) => switch ((isChecked, option)) {
    (true, _) when option == step.sign => OptionMark.correct,
    (true, _) when option == selected => OptionMark.wrong,
    (false, _) when option == selected => OptionMark.selected,
    _ => OptionMark.none,
  };

  LessonInProgress copyWith({
    int? stepIndex,
    SignId? Function()? selected,
    bool? isChecked,
    int? correctAnswers,
    Playback? playback,
  }) => LessonInProgress(
    lesson: lesson,
    signs: signs,
    stepIndex: stepIndex ?? this.stepIndex,
    selected: selected == null ? this.selected : selected(),
    isChecked: isChecked ?? this.isChecked,
    correctAnswers: correctAnswers ?? this.correctAnswers,
    playback: playback ?? this.playback,
  );

  @override
  List<Object?> get props => [
    lesson,
    signs,
    stepIndex,
    selected,
    isChecked,
    correctAnswers,
    playback,
  ];
}

sealed class ProgressSave extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class ProgressSaving extends ProgressSave {
  const new();
}

final class ProgressSaved extends ProgressSave {
  const new();
}

final class ProgressSaveFailed extends ProgressSave {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class LessonFinished extends LessonPlayerState {
  const new({required this.lesson, required this.result, required this.save});

  final Lesson lesson;
  final LessonResult result;
  final ProgressSave save;

  @override
  List<Object?> get props => [lesson, result, save];
}
