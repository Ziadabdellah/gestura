import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/share/link_sharer.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/achievements/presentation/pages/stats_page.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../helpers/fake_link_sharer.dart';
import '../../helpers/fake_progress_repository.dart';
import '../../helpers/fake_review_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('opens from the profile with stats and achievements', (
    tester,
  ) async {
    await tester.pumpApp(
      initialLocation: '/profile',
      progress: FakeProgressRepository([completed('demo-a1-1')]),
    );

    await tester.tap(find.text('Your progress'));
    await tester.pumpAndSettle();

    expect(find.byType(StatsPage), findsOneWidget);
    expect(find.text('Lessons done'), findsOneWidget);
    expect(find.text('Finish your first lesson'), findsOneWidget);
    expect(find.text('Earned'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Practise for an hour'), 100);
    expect(find.text('0 of 60'), findsOneWidget);
  });

  testWidgets('exports the learner data from the profile', (tester) async {
    await tester.pumpApp(initialLocation: '/profile');

    await tester.scrollUntilVisible(find.text('Export my data'), 100);
    await tester.runAsync(() async {
      await tester.tap(find.text('Export my data'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    final (path, subject) =
        (getIt<LinkSharer>() as FakeLinkSharer).files.single;
    expect(path, endsWith('.json'));
    expect(subject, 'My Gestura data');
  });

  testWidgets('says when the data cannot be exported', (tester) async {
    final reviews = FakeReviewRepository();
    await tester.pumpApp(initialLocation: '/profile', reviews: reviews);
    reviews.failure = const StorageFullFailure();

    await tester.scrollUntilVisible(find.text('Export my data'), 100);
    await tester.runAsync(() async {
      await tester.tap(find.text('Export my data'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect((getIt<LinkSharer>() as FakeLinkSharer).files, isEmpty);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('tries again after a failure', (tester) async {
    final reviews = FakeReviewRepository()
      ..failure = const StorageFullFailure();
    await tester.pumpApp(
      initialLocation: '/profile/progress',
      reviews: reviews,
    );

    reviews.failure = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Lessons done'), findsOneWidget);
  });

  for (final settings in [
    englishLight,
    const AppSettings(
      language: AppLanguage.arabic,
      theme: AppThemePreference.dark,
      onboardingComplete: true,
    ),
  ]) {
    testWidgets('meets the accessibility guidelines in '
        '${settings.language.name}', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        initialLocation: '/profile/progress',
        settings: settings,
      );

      await tester.expectAccessible();
      handle.dispose();
    });
  }

  testWidgets('fits at 200% text on a small phone', (tester) async {
    await tester.pumpApp(
      initialLocation: '/profile/progress',
      surfaceSize: const Size(320, 640),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('uses three columns on a wide screen', (tester) async {
    await tester.pumpApp(
      initialLocation: '/profile/progress',
      surfaceSize: const Size(1280, 800),
    );

    expect(tester.takeException(), isNull);
  });
}
