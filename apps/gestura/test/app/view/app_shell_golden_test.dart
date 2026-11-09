import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';

import '../../helpers/golden_scenario.dart';
import '../../helpers/pump_app.dart';

const Size _tablet = Size(1024, 720);

void main() {
  setUp(registerFakes);
  tearDown(getIt.reset);

  unawaited(
    goldenTest(
      'The shell uses a navigation rail on tablets',
      fileName: 'app_shell_tablet',
      builder: () => GoldenTestGroup(
        columns: 1,
        children: [
          for (final settings in const [
            AppSettings(
              language: AppLanguage.english,
              theme: AppThemePreference.light,
            ),
            AppSettings(
              language: AppLanguage.arabic,
              theme: AppThemePreference.dark,
            ),
          ])
            appScenario(
              settings: settings,
              location: const LearnRoute().location,
              size: _tablet,
            ),
        ],
      ),
    ),
  );
}
