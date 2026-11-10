import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/learn/domain/course_outline.dart';
import 'package:gestura/features/learn/presentation/view_models/learn_state.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura_core/gestura_core.dart';

class LearnViewModel extends Cubit<LearnState> {
  new(this._content, this._progress) : super(const LearnLoading());

  final ContentRepository _content;
  final ProgressRepository _progress;
  StreamSubscription<Result<ProgressByLesson>>? _progressSubscription;

  Future<void> load() async {
    if (state is! LearnLoading) emit(const LearnLoading());
    unawaited(_progressSubscription?.cancel());
    _progressSubscription = null;
    final (packResult, coursesResult) = await (
      _content.pack(),
      _content.courses(),
    ).wait;
    if (isClosed) return;
    switch ((packResult, coursesResult)) {
      case (Ok(value: final pack), Ok(value: [final course, ...])):
        _follow(pack, course);
      case (Ok(), Ok()):
        emit(const LearnFailed(NotFoundFailure()));
      case (Err(:final failure), _) || (_, Err(:final failure)):
        emit(LearnFailed(failure));
    }
  }

  void _follow(SignLanguagePack pack, Course course) {
    _progressSubscription = _progress.watchAll().listen(
      (result) => emit(switch (result) {
        Ok(value: final progress) => LearnLoaded(
          pack: pack,
          course: course,
          outline: CourseOutline.of(course, progress),
        ),
        Err(:final failure) => LearnFailed(failure),
      }),
    );
  }

  @override
  Future<void> close() async {
    await _progressSubscription?.cancel();
    await super.close();
  }
}
