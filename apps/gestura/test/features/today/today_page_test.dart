import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/lesson/presentation/pages/lesson_page.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura/features/review/presentation/pages/review_page.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/sign_detail/presentation/pages/sign_detail_page.dart';
import 'package:gestura/features/today/presentation/pages/today_page.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../helpers/fake_content_repository.dart';
import '../../helpers/fake_progress_repository.dart';
import '../../helpers/fake_review_repository.dart';
import '../../helpers/pump_app.dart';

FakeReviewRepository _dueHello() => FakeReviewRepository([
  ReviewCard(
    updatedAt: reviewNow,
    signId: const SignId('hello'),
    state: CardState.initial(DateTime.utc(2026)),
  ),
]);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Today', () {
    testWidgets('opens first after sign-in with the daily summary', (
      tester,
    ) async {
      await tester.pumpApp(initialLocation: '/', reviews: _dueHello());

      expect(find.byType(TodayPage), findsOneWidget);
      expect(find.text('Daily goal'), findsOneWidget);
      expect(find.text('0 / 10 min'), findsOneWidget);
      expect(find.text('1 sign to review'), findsOneWidget);
      expect(find.text('Lesson 1 · Hello and thank you'), findsOneWidget);
    });

    testWidgets('starts the next lesson', (tester) async {
      await tester.pumpApp(initialLocation: '/today');

      await _tap(tester, find.widgetWithText(GButton, 'Start lesson'));

      expect(find.byType(LessonPage), findsOneWidget);
    });

    testWidgets('starts a review of the due signs', (tester) async {
      await tester.pumpApp(initialLocation: '/today', reviews: _dueHello());

      await _tap(tester, find.widgetWithText(GButton, 'Start review'));

      expect(find.byType(ReviewPage), findsOneWidget);
    });

    testWidgets('opens the sign of the day', (tester) async {
      await tester.pumpApp(initialLocation: '/today');

      await _tap(tester, find.text('Sign of the day'));

      expect(find.byType(SignDetailPage), findsOneWidget);
    });

    testWidgets('celebrates a finished course and a reached goal', (
      tester,
    ) async {
      await tester.pumpApp(
        initialLocation: '/today',
        settings: englishLight.copyWith(dailyGoal: DailyGoal.five),
        progress: FakeProgressRepository([
          for (var lesson = 1; lesson <= 4; lesson++)
            completed('demo-a1-$lesson'),
        ]),
      );

      expect(
        find.text('You finished every lesson in this course.'),
        findsOneWidget,
      );
      expect(find.text('Nothing to review'), findsOneWidget);
      expect(find.widgetWithText(GButton, 'Start review'), findsNothing);
    });

    testWidgets('explains a failure and tries again', (tester) async {
      final content = FakeContentRepository()..failure = const NetworkFailure();
      await tester.pumpApp(initialLocation: '/today', content: content);

      expect(find.byType(GErrorView), findsOneWidget);

      content.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Daily goal'), findsOneWidget);
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
          initialLocation: '/today',
          settings: settings,
          reviews: _dueHello(),
        );

        await tester.expectAccessible();
        handle.dispose();
      });
    }

    testWidgets('fits at 200% text on a small phone', (tester) async {
      await tester.pumpApp(
        initialLocation: '/today',
        surfaceSize: const Size(320, 640),
        textScale: 2,
        reviews: _dueHello(),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
