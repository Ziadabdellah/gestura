import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_state.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_view_model.dart';
import 'package:gestura/features/lesson/presentation/widgets/lesson_view.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../../helpers/fake_video_player_platform.dart';
import '../../../helpers/golden_scenario.dart';
import '../../../helpers/lesson_states.dart';

const AppSettings _englishLight = AppSettings(
  language: AppLanguage.english,
  theme: AppThemePreference.light,
);
const AppSettings _arabicDark = AppSettings(
  language: AppLanguage.arabic,
  theme: AppThemePreference.dark,
);

Widget _player(LessonPlayerState state) {
  final viewModel = MockLessonPlayerViewModel();
  whenListen(
    viewModel,
    const Stream<LessonPlayerState>.empty(),
    initialState: state,
  );
  return BlocProvider<LessonPlayerViewModel>.value(
    value: viewModel,
    child: Scaffold(
      body: SafeArea(
        child: LessonView(
          state: state,
          onClose: () {},
          onRetry: () {},
          onDone: () {},
        ),
      ),
    ),
  );
}

List<GoldenTestScenario> _both(String name, LessonPlayerState state) => [
  for (final settings in [_englishLight, _arabicDark])
    viewScenario(
      name: '$name ${settings.language.code} ${settings.theme.name}',
      settings: settings,
      child: _player(state),
    ),
];

void main() {
  setUp(() => VideoPlayerPlatform.instance = FakeVideoPlayerPlatform());

  final chooseWord = stepOf<ChooseWordStep>();
  final chooseVideo = stepOf<ChooseVideoStep>();
  final wordStep = firstLesson.steps[chooseWord];
  final wrong = (wordStep as ChooseWordStep).options.firstWhere(
    (id) => id != wordStep.sign,
  );
  final videoStep = firstLesson.steps[chooseVideo] as ChooseVideoStep;

  unawaited(
    goldenTest(
      'The lesson player: a new sign and the two quizzes',
      fileName: 'lesson_steps',
      pumpBeforeTest: precacheImages,
      builder: () => GoldenTestGroup(
        columns: 4,
        children: [
          ..._both('learn', inProgress()),
          ..._both(
            'wrong answer',
            inProgress(stepIndex: chooseWord, selected: wrong, isChecked: true),
          ),
          ..._both(
            'choose the video',
            inProgress(stepIndex: chooseVideo, selected: videoStep.options[1]),
          ),
          ..._both(
            'right answer',
            inProgress(
              stepIndex: chooseVideo,
              selected: videoStep.sign,
              isChecked: true,
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'The lesson player: the end of a lesson',
      fileName: 'lesson_complete',
      builder: () => GoldenTestGroup(
        columns: 4,
        children: [
          ..._both('saved', finished()),
          ..._both(
            'not saved',
            finished(save: const ProgressSaveFailed(StorageFullFailure())),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'The lesson player before any choice in the video quiz',
      fileName: 'lesson_choose_video_empty',
      pumpBeforeTest: precacheImages,
      builder: () => GoldenTestGroup(
        columns: 2,
        children: _both('nothing chosen', inProgress(stepIndex: chooseVideo)),
      ),
    ),
  );

  test('the demo lesson has every step type', () {
    expect(chooseWord, isNonNegative);
    expect(chooseVideo, isNonNegative);
    expect(wrong, isNot(const SignId('')));
  });
}
