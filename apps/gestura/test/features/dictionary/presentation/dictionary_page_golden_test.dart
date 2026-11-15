import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
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
      'Dictionary in English and Arabic, light and dark',
      fileName: 'dictionary_page',
      pumpBeforeTest: loadThenPrecacheImages,
      builder: () => GoldenTestGroup(
        columns: 4,
        children: [
          for (final settings in goldenSettings)
            appScenario(
              settings: settings,
              location: const DictionaryRoute().location,
            ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'Dictionary search with no results',
      fileName: 'dictionary_no_results',
      pumpBeforeTest: (tester) async {
        for (final field in find.byType(TextField).evaluate().toList()) {
          await tester.enterText(find.byWidget(field.widget), 'zebra');
        }
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
      },
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          for (final settings in [goldenSettings.first, goldenSettings.last])
            appScenario(
              settings: settings,
              location: const DictionaryRoute().location,
              size: const Size(360, 640),
            ),
        ],
      ),
    ),
  );
}
