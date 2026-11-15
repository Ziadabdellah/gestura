import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_ids.dart';

import '../../helpers/fake_saved_signs_repository.dart';
import '../../helpers/golden_scenario.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(
    () => registerFakes(
      saved: FakeSavedSignsRepository([
        for (final id in ['thank-you', 'hello', 'yes']) SignId(id),
      ]),
    ),
  );
  tearDown(getIt.reset);

  unawaited(
    goldenTest(
      'Saved signs in English and Arabic, light and dark',
      fileName: 'saved_signs_page',
      pumpBeforeTest: loadThenPrecacheImages,
      builder: () => GoldenTestGroup(
        columns: 4,
        children: [
          for (final settings in goldenSettings)
            appScenario(
              settings: settings,
              location: '/dictionary/saved',
              size: const Size(360, 780),
            ),
        ],
      ),
    ),
  );
}
