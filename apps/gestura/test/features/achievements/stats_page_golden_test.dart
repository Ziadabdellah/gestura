import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/content/domain/content_ids.dart';

import '../../helpers/fake_activity_repository.dart';
import '../../helpers/fake_progress_repository.dart';
import '../../helpers/fake_review_repository.dart';
import '../../helpers/golden_scenario.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(() async {
    final reviews = FakeReviewRepository();
    await reviews.addSigns({
      for (final id in ['hello', 'thank-you', 'please', 'yes']) SignId(id),
    });
    await registerFakes(
      progress: FakeProgressRepository([completed('demo-a1-1')]),
      reviews: reviews,
      activity: FakeActivityRepository([
        DailyActivity(day: DateTime(2025), lessons: 1, seconds: 900),
        DailyActivity(day: DateTime(2025, 1, 2), reviews: 4, seconds: 300),
      ]),
    );
  });
  tearDown(getIt.reset);

  unawaited(
    goldenTest(
      'Progress and achievements in English and Arabic, light and dark',
      fileName: 'stats_page',
      pumpBeforeTest: loadThenPrecacheImages,
      builder: () => GoldenTestGroup(
        columns: 4,
        children: [
          for (final settings in goldenSettings)
            appScenario(
              settings: settings,
              location: '/profile/progress',
              size: const Size(360, 900),
            ),
        ],
      ),
    ),
  );
}
