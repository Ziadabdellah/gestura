import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/di/injection.dart';

import '../../../helpers/golden_scenario.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUp(registerFakes);
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
}
