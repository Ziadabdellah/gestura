import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/gestura_app.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/core/database/app_database.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_state.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_view_model.dart';
import 'package:gestura/features/lesson/presentation/widgets/lesson_view.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/domain/settings_repository.dart';
import 'package:gestura/features/sign_detail/presentation/pages/sign_detail_page.dart';
import 'package:gestura/features/today/presentation/pages/today_page.dart';
import 'package:gestura_ui/gestura_ui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player/video_player.dart';

import 'support/emulated_auth.dart';

const AppConfig _dev = AppConfig(flavor: Flavor.dev);

LessonPlayerState _state(WidgetTester tester) =>
    tester.element(find.byType(LessonView)).read<LessonPlayerViewModel>().state;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _button(WidgetTester tester, String label) =>
    _tap(tester, find.widgetWithText(GButton, label));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    final database = getIt<AppDatabase>();
    await database.delete(database.progress).go();
    await getIt<SettingsRepository>().save(AppSettings.defaults);
    await getIt.reset();
    await signOutEverywhere();
  });

  testWidgets('a guest goes from the first start to a finished lesson', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await emulatedAuth();
    await configureDependencies(_dev);
    await getIt<SettingsRepository>().save(
      const AppSettings(language: AppLanguage.english),
    );
    await tester.pumpWidget(
      const ProviderScope(child: GesturaApp(config: _dev)),
    );
    await tester.pumpAndSettle();

    await _button(tester, 'Get started');
    await _button(tester, 'Continue');
    await _button(tester, 'Continue');
    await _button(tester, 'Continue');
    await _button(tester, 'Continue');
    await _button(tester, 'Continue as guest');

    expect(FirebaseAuth.instance.currentUser?.isAnonymous, isTrue);
    expect(find.byType(TodayPage), findsOneWidget);
    expect(find.text('Lesson 1 · Hello and thank you'), findsOneWidget);

    await _tap(tester, find.text('Start lesson'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(VideoPlayer), findsOneWidget);

    while (_state(tester) is LessonInProgress) {
      final state = _state(tester) as LessonInProgress;
      switch (state.step) {
        case LearnSignStep():
          break;
        case ChooseWordStep(:final sign):
          await _tap(
            tester,
            find.bySemanticsLabel(state.signOf(sign).meaning.resolve('en')),
          );
          await _tap(tester, find.text('Check'));
        case ChooseVideoStep(:final sign, :final options):
          await _tap(
            tester,
            find.bySemanticsLabel('Video ${options.indexOf(sign) + 1}'),
          );
          await _tap(tester, find.text('Check'));
      }
      await _tap(tester, find.text('Continue'));
    }

    expect(find.text('Lesson complete!'), findsOneWidget);
    await _tap(tester, find.text('Continue'));

    expect(find.byType(TodayPage), findsOneWidget);
    expect(find.textContaining('signs to review'), findsOneWidget);
    await _tap(
      tester,
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Learn'),
      ),
    );

    expect(find.text('Completed · Best score 100%'), findsOneWidget);
    expect(find.text('1 of 4 done'), findsOneWidget);
    final stored = await getIt<ProgressRepository>().readAll();
    expect(stored.valueOrNull?[const LessonId('demo-a1-1')]?.bestScore, 100);

    await _tap(
      tester,
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Dictionary'),
      ),
    );
    await tester.enterText(find.byType(TextField), 'thank');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    await _tap(tester, find.text('THANK-YOU'));

    expect(find.byType(SignDetailPage), findsOneWidget);
    expect(find.text('Thank you'), findsWidgets);
    semantics.dispose();
  });
}
