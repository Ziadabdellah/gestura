import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../../helpers/fake_activity_repository.dart';
import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/fake_review_repository.dart';
import '../../../helpers/pump_app.dart';

FakeReviewRepository _due(List<String> ids) => FakeReviewRepository([
  for (final id in ids)
    ReviewCard(
      updatedAt: reviewNow,
      signId: SignId(id),
      state: CardState.initial(DateTime.utc(2026)),
    ),
]);

void main() {
  group('Review', () {
    testWidgets('shows the video, the answer and four grades with intervals', (
      tester,
    ) async {
      final reviews = _due(['hello', 'yes']);
      final activity = FakeActivityRepository();
      await tester.pumpApp(
        initialLocation: '/review',
        reviews: reviews,
        activity: activity,
      );

      expect(
        find.text('Do you remember what this sign means?'),
        findsOneWidget,
      );
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(find.widgetWithText(GButton, 'Show answer'));
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Again'), findsOneWidget);
      expect(find.text('1 day'), findsWidgets);

      await tester.tap(find.text('Good'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(GButton, 'Show answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Again'));
      await tester.pumpAndSettle();

      expect(find.text('Review done'), findsOneWidget);
      expect(
        find.text('You reviewed 2 signs and remembered 1.'),
        findsOneWidget,
      );
      expect(activity.calls, hasLength(2));

      await tester.tap(find.widgetWithText(GButton, 'Continue'));
      await tester.pumpAndSettle();
    });

    testWidgets('says when everything is reviewed', (tester) async {
      await tester.pumpApp(initialLocation: '/review');

      expect(find.text('All caught up'), findsOneWidget);
    });

    testWidgets('explains a failure and tries again', (tester) async {
      final content = FakeContentRepository()..failure = const NetworkFailure();
      await tester.pumpApp(
        initialLocation: '/review',
        content: content,
        reviews: _due(['hello']),
      );

      expect(find.byType(GErrorView), findsOneWidget);

      content.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Show answer'), findsOneWidget);
    });

    testWidgets('changes playback during the session', (tester) async {
      await tester.pumpApp(
        initialLocation: '/review',
        reviews: _due(['hello']),
        settings: englishLight.copyWith(dominantHand: DominantHand.left),
      );

      await tester.tap(find.text('0.5×'));
      await tester.tap(find.byTooltip('Loop'));
      await tester.tap(find.byTooltip('Mirror'));
      await tester.pumpAndSettle();
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
          initialLocation: '/review',
          settings: settings,
          reviews: _due(['hello']),
        );
        await tester.tap(find.byType(GButton));
        await tester.pumpAndSettle();

        await tester.expectAccessible();
        handle.dispose();
      });
    }

    testWidgets('fits at 200% text on a small phone', (tester) async {
      await tester.pumpApp(
        initialLocation: '/review',
        surfaceSize: const Size(320, 640),
        textScale: 2,
        reviews: _due(['hello']),
      );
      await tester.tap(find.byType(GButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
