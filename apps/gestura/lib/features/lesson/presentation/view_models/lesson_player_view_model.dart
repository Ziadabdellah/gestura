import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/lesson/domain/lesson_result.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_state.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
import 'package:gestura_core/gestura_core.dart';

class LessonPlayerViewModel extends Cubit<LessonPlayerState> {
  new(
    this._content,
    this._progress,
    this._telemetry,
    this._reviews,
    this._activity, {
    this.playback = const Playback(),
  }) : super(const LessonPlayerLoading());

  final ContentRepository _content;
  final ProgressRepository _progress;
  final Telemetry _telemetry;
  final ReviewRepository _reviews;
  final ActivityRepository _activity;
  final Playback playback;
  DateTime _startedAt = clock.now();

  Future<void> load(LessonId id) async {
    if (state is! LessonPlayerLoading) emit(const LessonPlayerLoading());
    final lessonResult = await _content.lesson(id);
    final Lesson lesson;
    switch (lessonResult) {
      case Ok(:final value):
        lesson = value;
      case Err(:final failure):
        if (!isClosed) emit(LessonPlayerFailed(failure));
        return;
    }
    final signsResult = await _content.signs(lesson.signs);
    if (isClosed) return;
    switch (signsResult) {
      case Ok(value: final List<Sign> signs):
        _startedAt = clock.now();
        emit(
          LessonInProgress(
            lesson: lesson,
            signs: {for (final sign in signs) sign.id: sign},
            playback: playback,
          ),
        );
      case Err(:final failure):
        emit(LessonPlayerFailed(failure));
    }
  }

  void select(SignId option) {
    if (state case final LessonInProgress active
        when active.isQuiz && !active.isChecked) {
      emit(active.copyWith(selected: () => option));
    }
  }

  void check() {
    if (state case final LessonInProgress active
        when active.isQuiz && !active.isChecked && active.selected != null) {
      emit(
        active.copyWith(
          isChecked: true,
          correctAnswers: active.correctAnswers + (active.isCorrect ? 1 : 0),
        ),
      );
    }
  }

  Future<void> next() async {
    if (state case final LessonInProgress active when active.canContinue) {
      if (!active.isLastStep) {
        emit(
          active.copyWith(
            stepIndex: active.stepIndex + 1,
            selected: () => null,
            isChecked: false,
          ),
        );
        return;
      }
      final steps = active.lesson.steps;
      final result = LessonResult(
        lessonId: active.lesson.id,
        correctAnswers: active.correctAnswers,
        questions: steps.where((step) => step is! LearnSignStep).length,
        newSigns: {
          for (final step in steps)
            if (step is LearnSignStep) step.sign,
        }.length,
        duration: clock.now().difference(_startedAt),
      );
      unawaited(
        _telemetry.record(
          LessonCompleted(lessonId: result.lessonId.value, score: result.score),
        ),
      );
      unawaited(
        _reviews.addSigns({
          for (final step in steps)
            if (step is LearnSignStep) step.sign,
        }),
      );
      unawaited(_activity.recordLesson(result.duration));
      await _save(active.lesson, result);
    }
  }

  Future<void> retrySave() async {
    if (state case LessonFinished(
      :final lesson,
      :final result,
      save: ProgressSaveFailed(),
    )) {
      await _save(lesson, result);
    }
  }

  void setSpeed(PlaybackSpeed speed) =>
      _updatePlayback((playback) => playback.copyWith(speed: speed));

  void setLooping({required bool looping}) =>
      _updatePlayback((playback) => playback.copyWith(looping: looping));

  void setMirrored({required bool mirrored}) =>
      _updatePlayback((playback) => playback.copyWith(mirrored: mirrored));

  void _updatePlayback(Playback Function(Playback playback) change) {
    if (state case final LessonInProgress active) {
      emit(active.copyWith(playback: change(active.playback)));
    }
  }

  Future<void> _save(Lesson lesson, LessonResult result) async {
    emit(
      LessonFinished(
        lesson: lesson,
        result: result,
        save: const ProgressSaving(),
      ),
    );
    final saved = await _progress.recordCompletion(
      lesson.id,
      score: result.score,
    );
    if (isClosed) return;
    emit(
      LessonFinished(
        lesson: lesson,
        result: result,
        save: switch (saved) {
          Ok() => const ProgressSaved(),
          Err(:final failure) => ProgressSaveFailed(failure),
        },
      ),
    );
  }
}
