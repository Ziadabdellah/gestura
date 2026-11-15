import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/app_policy/domain/app_policy.dart';

import '../../helpers/fake_policy_source.dart';
import '../../helpers/golden_scenario.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(
    () =>
        registerFakes(policy: FakePolicySource(const AppPolicy(minBuild: 999))),
  );
  tearDown(getIt.reset);

  unawaited(
    goldenTest(
      'Update required in English and Arabic, light and dark',
      fileName: 'update_required',
      pumpBeforeTest: loadThenPrecacheImages,
      builder: () => GoldenTestGroup(
        columns: 4,
        children: [
          for (final settings in goldenSettings)
            appScenario(
              settings: settings,
              location: '/learn',
              size: const Size(360, 640),
            ),
        ],
      ),
    ),
  );
}
