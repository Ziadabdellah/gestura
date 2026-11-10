import 'package:bloc_test/bloc_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/lesson/domain/lesson_result.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_state.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_view_model.dart';

import 'fake_content_repository.dart';

class MockLessonPlayerViewModel extends MockCubit<LessonPlayerState>
    implements LessonPlayerViewModel;

final Lesson firstLesson = demoCatalog.lesson(const LessonId('demo-a1-1'))!;

LessonInProgress inProgress({
  int stepIndex = 0,
  SignId? selected,
  bool isChecked = false,
}) => LessonInProgress(
  lesson: firstLesson,
  signs: {for (final id in firstLesson.signs) id: demoCatalog.sign(id)!},
  stepIndex: stepIndex,
  selected: selected,
  isChecked: isChecked,
);

int stepOf<T extends LessonStep>() =>
    firstLesson.steps.indexWhere((step) => step is T);

LessonFinished finished({ProgressSave save = const ProgressSaved()}) =>
    LessonFinished(
      lesson: firstLesson,
      result: LessonResult(
        lessonId: firstLesson.id,
        correctAnswers: 2,
        questions: 3,
        newSigns: 3,
        duration: const Duration(minutes: 1, seconds: 5),
      ),
      save: save,
    );
