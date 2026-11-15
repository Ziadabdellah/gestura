import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/gestura_app.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/core/database/app_database.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/domain/settings_repository.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:integration_test/integration_test.dart';

import 'support/emulated_auth.dart';

const AppConfig _dev = AppConfig(flavor: Flavor.dev);
const LessonId _first = LessonId('demo-a1-1');

Future<void> _start() async {
  await signInAsGuest();
  await configureDependencies(_dev);
  await getIt<SettingsRepository>().save(
    const AppSettings(language: AppLanguage.english, onboardingComplete: true),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    final database = getIt<AppDatabase>();
    await database.delete(database.progress).go();
    await getIt<SettingsRepository>().save(AppSettings.defaults);
    await getIt.reset();
    await signOutEverywhere();
  });

  testWidgets('a finished lesson survives a restart of the database', (
    tester,
  ) async {
    await _start();

    final saved = await getIt<ProgressRepository>().recordCompletion(
      _first,
      score: 90,
    );
    await getIt.reset();
    await configureDependencies(_dev);
    final afterRestart = await getIt<ProgressRepository>().watchAll().first;

    expect(saved, const Ok<void>(null));
    expect(afterRestart.valueOrNull?[_first]?.bestScore, 90);
  });

  testWidgets('Learn shows the progress stored on the device', (tester) async {
    await _start();
    await getIt<ProgressRepository>().recordCompletion(_first, score: 90);

    await tester.pumpWidget(
      const ProviderScope(child: GesturaApp(config: _dev)),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 of 4 done'), findsOneWidget);
    expect(find.text('Completed · Best score 90%'), findsOneWidget);
    expect(find.text('Up next'), findsOneWidget);

    await getIt<ProgressRepository>().recordCompletion(
      const LessonId('demo-a1-2'),
      score: 70,
    );
    await tester.pumpAndSettle();

    expect(find.text('2 of 4 done'), findsOneWidget);
  });
}
