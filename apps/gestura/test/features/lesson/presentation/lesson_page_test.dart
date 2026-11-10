import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/learn/presentation/pages/learn_page.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/lesson/presentation/pages/lesson_page.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_state.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_view_model.dart';
import 'package:gestura/features/lesson/presentation/widgets/lesson_complete_view.dart';
import 'package:gestura/features/lesson/presentation/widgets/lesson_view.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/fake_progress_repository.dart';
import '../../../helpers/pump_app.dart';

final String _firstLesson = const LessonRoute(lessonId: 'demo-a1-1').location;

const AppSettings _arabicDark = AppSettings(
  language: AppLanguage.arabic,
  theme: AppThemePreference.dark,
);

LessonPlayerViewModel _viewModel(WidgetTester tester) =>
    tester.element(find.byType(LessonView)).read<LessonPlayerViewModel>();

LessonPlayerState _state(WidgetTester tester) => _viewModel(tester).state;

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _answer(WidgetTester tester, {required bool right}) async {
  final state = _state(tester) as LessonInProgress;
  final step = state.step;
  if (step is LearnSignStep) {
    await _tapText(tester, 'Continue');
    return;
  }
  final options = switch (step) {
    ChooseWordStep(:final options) ||
    ChooseVideoStep(:final options) => options,
    LearnSignStep() => const <SignId>[],
  };
  final choice = right
      ? step.sign
      : options.firstWhere((id) => id != step.sign);
  final label = switch (step) {
    ChooseVideoStep() => 'Video ${options.indexOf(choice) + 1}',
    _ => state.signOf(choice).meaning.resolve('en'),
  };
  final option = find.bySemanticsLabel(label);
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
  await _tapText(tester, 'Check');
  await _tapText(tester, 'Continue');
}

Future<void> _finish(WidgetTester tester, {int wrongAt = -1}) async {
  for (var index = 0; _state(tester) is LessonInProgress; index++) {
    await _answer(tester, right: index != wrongAt);
  }
}

void main() {
  group('Opening a lesson', () {
    testWidgets('opens the next lesson from Learn over the whole screen', (
      tester,
    ) async {
      await tester.pumpApp();

      await tester.tap(find.text('Hello and thank you'));
      await tester.pumpAndSettle();

      expect(find.byType(LessonPage), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('1 / 6'), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('keeps locked lessons closed', (tester) async {
      await tester.pumpApp();

      await tester.tap(find.text('Yes, no and sorry'));
      await tester.pumpAndSettle();

      expect(find.byType(LessonPage), findsNothing);
    });

    testWidgets('lets a finished lesson be played again', (tester) async {
      await tester.pumpApp(
        progress: FakeProgressRepository([completed('demo-a1-1')]),
      );

      await tester.tap(find.text('Hello and thank you'));
      await tester.pumpAndSettle();

      expect(find.byType(LessonPage), findsOneWidget);
    });

    testWidgets('explains a lesson that cannot be found', (tester) async {
      await tester.pumpApp(
        initialLocation: const LessonRoute(lessonId: 'nope').location,
      );

      expect(
        find.text("We couldn't find what you're looking for."),
        findsOneWidget,
      );
    });

    testWidgets('loads again after a failure', (tester) async {
      final content = FakeContentRepository();
      await tester.pumpApp(content: content);
      content.failure = const NetworkFailure();

      await tester.tap(find.text('Hello and thank you'));
      await tester.pumpAndSettle();
      expect(
        find.text("You're offline. Check your connection and try again."),
        findsOneWidget,
      );

      content.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('1 / 6'), findsOneWidget);
    });

    testWidgets('closes a lesson that failed without asking', (tester) async {
      final content = FakeContentRepository();
      await tester.pumpApp(content: content);
      content.failure = const NetworkFailure();
      await tester.tap(find.text('Hello and thank you'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Close lesson'));
      await tester.pumpAndSettle();

      expect(find.text('Leave this lesson?'), findsNothing);
      expect(find.byType(LearnPage), findsOneWidget);
    });

    testWidgets('shows a spinner while the lesson loads', (tester) async {
      final content = FakeContentRepository();
      await tester.pumpApp(content: content);
      content.hold = Completer<void>();

      await tester.tap(find.text('Hello and thank you'));
      await tester.pump();
      await tester.pump();

      expect(find.bySemanticsLabel('Loading'), findsOneWidget);

      content.hold!.complete();
      await tester.pumpAndSettle();
      expect(find.text('1 / 6'), findsOneWidget);
    });
  });

  group('Playing a lesson', () {
    testWidgets('teaches each sign with its meaning and gloss', (tester) async {
      await tester.pumpApp(initialLocation: _firstLesson);

      expect(find.text('New sign'), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('HELLO'), findsOneWidget);
      expect(
        find.text(
          'A description of how to make this sign comes with the recorded '
          'video.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('keeps speed, loop and mirror for the rest of the lesson', (
      tester,
    ) async {
      await tester.pumpApp(initialLocation: _firstLesson);

      await tester.tap(find.text('0.5×'));
      await tester.tap(find.byTooltip('Loop'));
      await tester.tap(find.byTooltip('Mirror'));
      await tester.pumpAndSettle();
      await _answer(tester, right: true);

      final state = _state(tester) as LessonInProgress;
      expect(state.stepIndex, 1);
      expect(
        state.playback,
        const Playback(
          speed: PlaybackSpeed.half,
          looping: false,
          mirrored: true,
        ),
      );
      expect(fakeVideo.calls, containsAll(['speed 0.5', 'looping false']));
    });

    testWidgets('asks to choose before checking', (tester) async {
      await tester.pumpApp(initialLocation: _firstLesson);
      for (var step = 0; step < 3; step++) {
        await _answer(tester, right: true);
      }

      expect(find.text('What does this sign mean?'), findsOneWidget);
      final check = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Check'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(check.onPressed, isNull);
    });

    testWidgets('explains a wrong answer with colour, icon, text and haptics', (
      tester,
    ) async {
      final haptics = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpApp(initialLocation: _firstLesson);
      for (var step = 0; step < 3; step++) {
        await _answer(tester, right: true);
      }

      final state = _state(tester) as LessonInProgress;
      final step = state.step as ChooseWordStep;
      final wrong = step.options.firstWhere((id) => id != step.sign);
      await tester.tap(
        find.bySemanticsLabel(state.signOf(wrong).meaning.resolve('en')),
      );
      await tester.pumpAndSettle();
      await _tapText(tester, 'Check');

      expect(find.text('Not quite'), findsOneWidget);
      expect(
        find.text('Answer: ${state.signOf(step.sign).meaning.resolve('en')}'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cancel_rounded), findsWidgets);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(haptics, ['HapticFeedbackType.heavyImpact']);

      await _tapText(tester, 'Continue');
      await _answer(tester, right: true);
      expect(haptics.last, 'HapticFeedbackType.lightImpact');
    });

    testWidgets('names the right video when the video answer is wrong', (
      tester,
    ) async {
      await tester.pumpApp(initialLocation: _firstLesson);
      while ((_state(tester) as LessonInProgress).step is! ChooseVideoStep) {
        await _answer(tester, right: true);
      }

      expect(
        find.text('Tap a video to watch it, then check your answer.'),
        findsOneWidget,
      );
      final state = _state(tester) as LessonInProgress;
      final step = state.step as ChooseVideoStep;
      final wrong = step.options.indexWhere((id) => id != step.sign);
      await tester.tap(find.bySemanticsLabel('Video ${wrong + 1}'));
      await tester.pumpAndSettle();

      expect(
        fakeVideo.opened.last,
        state.signOf(step.options[wrong]).media.videoAsset,
      );

      await _tapText(tester, 'Check');

      expect(
        find.text('Answer: Video ${step.options.indexOf(step.sign) + 1}'),
        findsOneWidget,
      );
    });

    testWidgets('finishes, saves the score and goes back to Learn', (
      tester,
    ) async {
      final progress = FakeProgressRepository();
      await tester.pumpApp(progress: progress);
      await tester.tap(find.text('Hello and thank you'));
      await tester.pumpAndSettle();

      await _finish(tester);

      expect(find.byType(LessonCompleteView), findsOneWidget);
      expect(find.text('Lesson complete!'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(progress.stored[const LessonId('demo-a1-1')]?.bestScore, 100);

      await _tapText(tester, 'Continue');

      expect(find.byType(LearnPage), findsOneWidget);
      expect(find.text('Completed · Best score 100%'), findsOneWidget);
    });

    testWidgets('offers to save again when saving fails', (tester) async {
      final progress = FakeProgressRepository()
        ..saveFailure = const StorageFullFailure();
      await tester.pumpApp(initialLocation: _firstLesson, progress: progress);

      await _finish(tester, wrongAt: 3);

      expect(
        find.text(
          "Couldn't save your progress. Your device is out of space. Free "
          'some up and try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('67%'), findsOneWidget);

      progress.saveFailure = null;
      await _tapText(tester, 'Try again');

      expect(find.text('Try again'), findsNothing);
      expect(progress.stored[const LessonId('demo-a1-1')]?.bestScore, 67);
    });
  });

  group('Leaving a lesson', () {
    Future<void> openFromLearn(WidgetTester tester) async {
      await tester.pumpApp();
      await tester.tap(find.text('Hello and thank you'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks before closing and can keep going', (tester) async {
      await openFromLearn(tester);

      await tester.tap(find.byTooltip('Close lesson'));
      await tester.pumpAndSettle();

      expect(find.text('Leave this lesson?'), findsOneWidget);
      expect(
        find.text("Your answers in this lesson won't be saved."),
        findsOneWidget,
      );

      await tester.tap(find.text('Keep going'));
      await tester.pumpAndSettle();

      expect(find.byType(LessonPage), findsOneWidget);
    });

    testWidgets('leaves after confirming, also from the back button', (
      tester,
    ) async {
      await openFromLearn(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      expect(find.byType(LessonPage), findsNothing);
      expect(find.byType(LearnPage), findsOneWidget);
    });
  });

  group('Accessibility', () {
    for (final settings in [englishLight, _arabicDark]) {
      testWidgets('meets the guidelines while learning and answering in '
          '${settings.language.name}', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpApp(settings: settings, initialLocation: _firstLesson);

        await tester.expectAccessible();

        while ((_state(tester) as LessonInProgress).step is LearnSignStep) {
          await tester.tap(find.byType(FilledButton).last);
          await tester.pumpAndSettle();
        }
        final state = _state(tester) as LessonInProgress;
        _viewModel(tester)
          ..select(state.step.sign)
          ..check();
        await tester.pumpAndSettle();

        await tester.expectAccessible();
        handle.dispose();
      });
    }

    testWidgets('meets the guidelines on the complete screen', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(initialLocation: _firstLesson);
      await _finish(tester);

      await tester.expectAccessible();
      handle.dispose();
    });

    testWidgets('fits at 200% text on a small phone', (tester) async {
      await tester.pumpApp(
        initialLocation: _firstLesson,
        surfaceSize: const Size(320, 640),
        textScale: 2,
      );

      await _finish(tester, wrongAt: 3);

      expect(find.byType(LessonCompleteView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
