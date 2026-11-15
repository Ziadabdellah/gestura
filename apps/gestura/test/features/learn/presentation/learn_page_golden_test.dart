import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';

import '../../../helpers/fake_progress_repository.dart';
import '../../../helpers/golden_scenario.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('first lesson finished', () {
    setUp(
      () => registerFakes(
        progress: FakeProgressRepository([completed('demo-a1-1')]),
      ),
    );
    tearDown(getIt.reset);

    unawaited(
      goldenTest(
        'Learn in English and Arabic, light and dark',
        fileName: 'learn_page',
        builder: () => GoldenTestGroup(
          columns: 4,
          children: [
            for (final settings in goldenSettings)
              appScenario(
                settings: settings,
                location: const LearnRoute().location,
              ),
          ],
        ),
      ),
    );
  });

  group('first unit finished', () {
    setUp(
      () => registerFakes(
        progress: FakeProgressRepository([
          completed('demo-a1-1', score: 100),
          completed('demo-a1-2', score: 80),
        ]),
      ),
    );
    tearDown(getIt.reset);

    unawaited(
      goldenTest(
        'Learn opens the next unit and shows locked lessons',
        fileName: 'learn_page_next_unit',
        builder: () => GoldenTestGroup(
          columns: 2,
          children: [
            for (final settings in const [
              AppSettings(
                language: AppLanguage.english,
                theme: AppThemePreference.light,
                onboardingComplete: true,
              ),
              AppSettings(
                language: AppLanguage.arabic,
                theme: AppThemePreference.dark,
                onboardingComplete: true,
              ),
            ])
              appScenario(
                settings: settings,
                location: const LearnRoute().location,
              ),
          ],
        ),
      ),
    );
  });
}
