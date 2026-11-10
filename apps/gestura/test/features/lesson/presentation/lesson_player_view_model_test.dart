import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/lesson/domain/lesson_result.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_state.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_view_model.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/fake_progress_repository.dart';
import '../../../helpers/lesson_states.dart';

class _MockContentRepository extends Mock implements ContentRepository;

final DateTime _start = DateTime.utc(2026, 11, 10, 9);

void main() {
  late _MockContentRepository content;
  late FakeProgressRepository progress;
  late DateTime now;
  final lesson = firstLesson;
  final quiz = stepOf<ChooseWordStep>();
  final word = lesson.steps[quiz] as ChooseWordStep;
  final wrong = word.options.firstWhere((id) => id != word.sign);

  setUpAll(() => registerFallbackValue(<SignId>{}));

  setUp(() {
    now = _start;
    content = _MockContentRepository();
    progress = FakeProgressRepository();
    when(() => content.lesson(lesson.id)).thenAnswer((_) async => Ok(lesson));
    when(() => content.signs(any())).thenAnswer(
      (invocation) async => Ok([
        for (final id in invocation.positionalArguments.single as Set<SignId>)
          demoCatalog.sign(id)!,
      ]),
    );
  });

  LessonPlayerViewModel build() => withClock(
    Clock(() => now),
    () => LessonPlayerViewModel(content, progress),
  );

  Future<T> timed<T>(Future<T> Function() body) =>
      withClock(Clock(() => now), body);

  Future<void> answer(
    LessonPlayerViewModel viewModel, {
    required bool right,
  }) async {
    final state = viewModel.state as LessonInProgress;
    if (state.isQuiz) {
      final step = state.step;
      final options = switch (step) {
        ChooseWordStep(:final options) ||
        ChooseVideoStep(:final options) => options,
        LearnSignStep() => const <SignId>[],
      };
      viewModel
        ..select(
          right ? step.sign : options.firstWhere((id) => id != step.sign),
        )
        ..check();
    }
    await timed(viewModel.next);
  }

  group('loading', () {
    test('starts loading', () {
      expect(build().state, const LessonPlayerLoading());
    });

    blocTest<LessonPlayerViewModel, LessonPlayerState>(
      'opens the lesson at its first step with every sign it needs',
      build: build,
      act: (viewModel) => viewModel.load(lesson.id),
      expect: () => [inProgress()],
      verify: (_) => verify(() => content.signs(lesson.signs)).called(1),
    );

    blocTest<LessonPlayerViewModel, LessonPlayerState>(
      'reports a lesson that does not exist',
      setUp: () =>
          when(() => content.lesson(lesson.id))
              .thenAnswer((_) async => const Err(NotFoundFailure())),
      build: build,
      act: (viewModel) => viewModel.load(lesson.id),
      expect: () => [const LessonPlayerFailed(NotFoundFailure())],
    );

    blocTest<LessonPlayerViewModel, LessonPlayerState>(
      'reports signs that cannot be read and loads again on retry',
      setUp: () =>
          when(() => content.signs(any()))
              .thenAnswer((_) async => const Err(UnexpectedFailure('broken'))),
      build: build,
      act: (viewModel) async {
        await viewModel.load(lesson.id);
        await viewModel.load(lesson.id);
      },
      expect: () => [
        const LessonPlayerFailed(UnexpectedFailure('broken')),
        const LessonPlayerLoading(),
        const LessonPlayerFailed(UnexpectedFailure('broken')),
      ],
    );

    test('stays quiet when closed before the lesson arrives', () async {
      final arrival = Completer<Result<Lesson>>();
      when(() => content.lesson(lesson.id)).thenAnswer((_) => arrival.future);
      final viewModel = build();

      final loading = viewModel.load(lesson.id);
      await viewModel.close();
      arrival.complete(const Err(NotFoundFailure()));
      await loading;

      expect(viewModel.state, const LessonPlayerLoading());
    });

    test('stays quiet when closed before the signs arrive', () async {
      final arrival = Completer<Result<List<Sign>>>();
      when(() => content.signs(any())).thenAnswer((_) => arrival.future);
      final viewModel = build();

      final loading = viewModel.load(lesson.id);
      await pumpEventQueue();
      await viewModel.close();
      arrival.complete(const Ok([]));
      await loading;

      expect(viewModel.state, const LessonPlayerLoading());
    });
  });

  group('answering', () {
    blocTest<LessonPlayerViewModel, LessonPlayerState>(
      'ignores choices on a new-sign step and checks without a choice',
      build: build,
      seed: inProgress,
      act: (viewModel) => viewModel
        ..select(word.sign)
        ..check(),
      expect: () => <LessonPlayerState>[],
    );

    blocTest<LessonPlayerViewModel, LessonPlayerState>(
      'counts a right answer and keeps the choice after checking',
      build: build,
      seed: () => inProgress(stepIndex: quiz),
      act: (viewModel) => viewModel
        ..check()
        ..select(wrong)
        ..select(word.sign)
        ..check()
        ..select(wrong)
        ..check(),
      expect: () => [
        inProgress(stepIndex: quiz, selected: wrong),
        inProgress(stepIndex: quiz, selected: word.sign),
        inProgress(
          stepIndex: quiz,
          selected: word.sign,
          isChecked: true,
        ).copyWith(correctAnswers: 1),
      ],
    );

    blocTest<LessonPlayerViewModel, LessonPlayerState>(
      'does not count a wrong answer',
      build: build,
      seed: () => inProgress(stepIndex: quiz, selected: wrong),
      act: (viewModel) => viewModel.check(),
      expect: () => [
        inProgress(stepIndex: quiz, selected: wrong, isChecked: true),
      ],
    );

    blocTest<LessonPlayerViewModel, LessonPlayerState>(
      'waits for a quiz to be checked before moving on',
      build: build,
      seed: () => inProgress(stepIndex: quiz, selected: wrong),
      act: (viewModel) => viewModel.next(),
      expect: () => <LessonPlayerState>[],
    );

    blocTest<LessonPlayerViewModel, LessonPlayerState>(
      'moves to the next step with a fresh choice',
      build: build,
      seed: () => inProgress(stepIndex: quiz, selected: wrong, isChecked: true),
      act: (viewModel) => viewModel.next(),
      expect: () => [inProgress(stepIndex: quiz + 1)],
    );
  });

  group('finishing', () {
    test('saves the score and reports time and new signs', () async {
      final viewModel = build();
      await timed(() => viewModel.load(lesson.id));
      final states = <LessonPlayerState>[];
      final subscription = viewModel.stream.listen(states.add);

      for (var step = 0; step < lesson.steps.length; step++) {
        now = now.add(const Duration(seconds: 10));
        await answer(viewModel, right: step != quiz);
      }
      await pumpEventQueue();
      await subscription.cancel();

      const expected = LessonResult(
        lessonId: LessonId('demo-a1-1'),
        correctAnswers: 2,
        questions: 3,
        newSigns: 3,
        duration: Duration(seconds: 60),
      );
      expect(states.whereType<LessonFinished>(), [
        LessonFinished(
          lesson: lesson,
          result: expected,
          save: const ProgressSaving(),
        ),
        LessonFinished(
          lesson: lesson,
          result: expected,
          save: const ProgressSaved(),
        ),
      ]);
      expect(progress.stored[lesson.id]?.bestScore, 67);
    });

    blocTest<LessonPlayerViewModel, LessonPlayerState>(
      'lets the learner try saving again',
      setUp: () => progress.saveFailure = const StorageFullFailure(),
      build: build,
      seed: () =>
          finished(save: const ProgressSaveFailed(StorageFullFailure())),
      act: (viewModel) async {
        await viewModel.retrySave();
        progress.saveFailure = null;
        await viewModel.retrySave();
      },
      expect: () => [
        finished(save: const ProgressSaving()),
        finished(save: const ProgressSaveFailed(StorageFullFailure())),
        finished(save: const ProgressSaving()),
        finished(),
      ],
    );

    blocTest<LessonPlayerViewModel, LessonPlayerState>(
      'saves only after a failed save',
      build: build,
      seed: finished,
      act: (viewModel) => viewModel.retrySave(),
      expect: () => <LessonPlayerState>[],
    );

    test('stays quiet when closed while saving', () async {
      final viewModel = build()
        ..emit(finished(save: const ProgressSaveFailed(NetworkFailure())));

      final saving = viewModel.retrySave();
      await viewModel.close();
      await saving;

      expect(viewModel.state, finished(save: const ProgressSaving()));
    });
  });

  group('playback', () {
    blocTest<LessonPlayerViewModel, LessonPlayerState>(
      'changes speed, looping and mirroring for the rest of the lesson',
      build: build,
      seed: inProgress,
      act: (viewModel) => viewModel
        ..setSpeed(PlaybackSpeed.half)
        ..setLooping(looping: false)
        ..setMirrored(mirrored: true),
      expect: () => [
        inProgress().copyWith(
          playback: const Playback(speed: PlaybackSpeed.half),
        ),
        inProgress().copyWith(
          playback: const Playback(speed: PlaybackSpeed.half, looping: false),
        ),
        inProgress().copyWith(
          playback: const Playback(
            speed: PlaybackSpeed.half,
            looping: false,
            mirrored: true,
          ),
        ),
      ],
    );

    blocTest<LessonPlayerViewModel, LessonPlayerState>(
      'ignores playback changes outside a lesson',
      build: build,
      act: (viewModel) => viewModel.setSpeed(PlaybackSpeed.half),
      expect: () => <LessonPlayerState>[],
    );
  });

  group('state', () {
    test('marks the options before and after checking', () {
      final chosen = inProgress(stepIndex: quiz, selected: wrong);
      final checked = inProgress(
        stepIndex: quiz,
        selected: wrong,
        isChecked: true,
      );
      final untouched = word.options.firstWhere(
        (id) => id != wrong && id != word.sign,
      );

      expect(chosen.markOf(wrong), OptionMark.selected);
      expect(chosen.markOf(word.sign), OptionMark.none);
      expect(checked.markOf(wrong), OptionMark.wrong);
      expect(checked.markOf(word.sign), OptionMark.correct);
      expect(checked.markOf(untouched), OptionMark.none);
    });

    test('shows the video of the step, or of the chosen option', () {
      final video = stepOf<ChooseVideoStep>();
      final step = lesson.steps[video] as ChooseVideoStep;

      expect(inProgress().videoSign?.id, lesson.steps.first.sign);
      expect(inProgress(stepIndex: video).videoSign, isNull);
      expect(
        inProgress(stepIndex: video, selected: step.options.last).videoSign?.id,
        step.options.last,
      );
    });

    test('knows the last step', () {
      expect(inProgress().isLastStep, isFalse);
      expect(inProgress(stepIndex: lesson.steps.length - 1).isLastStep, isTrue);
    });
  });

  group('LessonResult', () {
    LessonResult result(int correct, int questions) => LessonResult(
      lessonId: lesson.id,
      correctAnswers: correct,
      questions: questions,
      newSigns: 0,
      duration: Duration.zero,
    );

    test('turns right answers into a rounded percentage', () {
      expect(result(2, 3).score, 67);
      expect(result(1, 3).score, 33);
      expect(result(3, 3).score, 100);
    });

    test('gives full marks to a lesson without questions', () {
      expect(result(0, 0).score, 100);
    });
  });
}
