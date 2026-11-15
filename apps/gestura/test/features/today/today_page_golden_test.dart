import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../helpers/fake_progress_repository.dart';
import '../../helpers/fake_review_repository.dart';
import '../../helpers/golden_scenario.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(
    () => registerFakes(
      progress: FakeProgressRepository([completed('demo-a1-1')]),
      reviews: FakeReviewRepository([
        for (final id in ['hello', 'please', 'thank-you'])
          ReviewCard(
            updatedAt: reviewNow,
            signId: SignId(id),
            state: CardState.initial(DateTime.utc(2026)),
          ),
      ]),
    ),
  );
  tearDown(getIt.reset);

  unawaited(
    goldenTest(
      'Today in English and Arabic, light and dark',
      fileName: 'today_page',
      pumpBeforeTest: loadThenPrecacheImages,
      builder: () => GoldenTestGroup(
        columns: 4,
        children: [
          for (final settings in goldenSettings)
            appScenario(
              settings: settings,
              location: '/today',
              size: const Size(360, 780),
            ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'A review with the answer shown',
      fileName: 'review_page',
      pumpBeforeTest: (tester) async {
        await loadThenPrecacheImages(tester);
        for (final button in find.text('Show answer').evaluate().toList()) {
          await tester.tap(find.byWidget(button.widget));
        }
        await tester.pumpAndSettle();
      },
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          for (final settings in [goldenSettings.first, goldenSettings.last])
            appScenario(
              settings: settings,
              location: '/review',
              size: const Size(360, 780),
            ),
        ],
      ),
    ),
  );
}
