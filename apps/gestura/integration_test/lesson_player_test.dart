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
import 'package:integration_test/integration_test.dart';
import 'package:video_player/video_player.dart';

const AppConfig _dev = AppConfig(flavor: Flavor.dev);

LessonPlayerState _state(WidgetTester tester) =>
    tester.element(find.byType(LessonView)).read<LessonPlayerViewModel>().state;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    final database = getIt<AppDatabase>();
    await database.delete(database.progress).go();
    await getIt<SettingsRepository>().save(AppSettings.defaults);
    await getIt.reset();
  });

  testWidgets('a learner finishes the first lesson and Learn shows it', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await configureDependencies(_dev);
    await getIt<SettingsRepository>().save(
      const AppSettings(language: AppLanguage.english),
    );
    await tester.pumpWidget(
      const ProviderScope(child: GesturaApp(config: _dev)),
    );
    await tester.pumpAndSettle();

    await _tap(tester, find.text('Hello and thank you'));
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
    expect(find.text('100%'), findsOneWidget);

    await _tap(tester, find.text('Continue'));

    expect(find.text('Completed · Best score 100%'), findsOneWidget);
    final stored = await getIt<ProgressRepository>().watchAll().first;
    expect(stored.valueOrNull?[const LessonId('demo-a1-1')]?.bestScore, 100);
    semantics.dispose();
  });
}
