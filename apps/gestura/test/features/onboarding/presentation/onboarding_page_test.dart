import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/widgets/placeholder_content_notice.dart';
import 'package:gestura/features/auth/presentation/pages/welcome_page.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/localized_text.dart';
import 'package:gestura/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:gestura/features/onboarding/presentation/view_models/onboarding_state.dart';
import 'package:gestura/features/onboarding/presentation/widgets/onboarding_progress.dart';
import 'package:gestura/features/onboarding/presentation/widgets/onboarding_steps.dart';
import 'package:gestura/features/onboarding/presentation/widgets/waving_hand.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/presentation/widgets/language_sheet.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/fake_settings_repository.dart';
import '../../../helpers/fake_telemetry.dart';
import '../../../helpers/golden_scenario.dart';
import '../../../helpers/pump_app.dart';

const AppSettings _firstRun = AppSettings(
  language: AppLanguage.english,
  theme: AppThemePreference.light,
);

Future<FakeSettingsRepository> _start(
  WidgetTester tester, {
  AppSettings settings = _firstRun,
  FakeContentRepository? content,
  FakeTelemetry? telemetry,
  double textScale = 1,
  Size surfaceSize = phoneSize,
}) => tester.pumpApp(
  settings: settings,
  content: content,
  auth: FakeAuthRepository(null),
  telemetry: telemetry,
  textScale: textScale,
  surfaceSize: surfaceSize,
);

Future<void> _continue(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(GButton, 'Continue'));
  await tester.pumpAndSettle();
}

Future<void> _getStarted(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(GButton, 'Get started'));
  await tester.pumpAndSettle();
}

String _progress(WidgetTester tester) =>
    tester.getSemantics(find.byType(OnboardingProgress)).label;

void main() {
  group('Onboarding', () {
    testWidgets('opens on the first run and welcomes the learner', (
      tester,
    ) async {
      await _start(tester);

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.byType(WavingHand), findsOneWidget);
      expect(find.text('Gestura'), findsOneWidget);
      expect(find.text('Sign language, in your hands.'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('waves once and rests, and keeps still under reduce motion', (
      tester,
    ) async {
      expect(WavingHand.angleAt(0), 0);
      expect(WavingHand.angleAt(1), closeTo(0, 1e-9));
      expect(WavingHand.angleAt(0.125), closeTo(WavingHand.swing, 1e-9));

      await _start(tester, settings: _firstRun.copyWith(reduceMotion: true));

      final rotation = tester.widget<Transform>(
        find.descendant(
          of: find.byType(WavingHand),
          matching: find.byType(Transform),
        ),
      );
      expect(rotation.transform, Matrix4.identity());
    });

    testWidgets('changes the app language from the first step', (tester) async {
      final settings = await _start(tester);

      await tester.tap(find.text('App language'));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageSheet), findsOneWidget);

      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();

      expect(settings.stored.language, AppLanguage.arabic);
      expect(find.text('لنبدأ'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(WelcomeStep))),
        TextDirection.rtl,
      );
    });

    testWidgets('keeps the language when the sheet is closed', (tester) async {
      final settings = await _start(tester);

      await tester.tap(find.text('App language'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(settings.saved, isEmpty);
    });

    testWidgets('walks through every step and stores each choice', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final telemetry = FakeTelemetry();
      final settings = await _start(tester, telemetry: telemetry);

      expect(_progress(tester), 'Step 1 of 5');
      await _getStarted(tester);

      expect(_progress(tester), 'Step 2 of 5');
      expect(find.text('Demo pack'), findsOneWidget);
      expect(find.byType(PlaceholderContentNotice), findsOneWidget);
      await _continue(tester);

      expect(settings.stored.signLanguage, 'demo');
      expect(find.text('Set a daily goal'), findsOneWidget);
      await tester.tap(find.text('15 minutes a day'));
      await tester.pumpAndSettle();
      await _continue(tester);

      expect(settings.stored.dailyGoal, DailyGoal.fifteen);
      expect(find.text('Which hand do you sign with?'), findsOneWidget);
      await tester.tap(find.text('Left hand'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reduce motion'));
      await tester.pumpAndSettle();
      await _continue(tester);

      expect(settings.stored.dominantHand, DominantHand.left);
      expect(settings.stored.reduceMotion, isTrue);
      expect(_progress(tester), 'Step 5 of 5');
      expect(find.text('Skip'), findsNothing);

      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switches.map((tile) => tile.value), [false, false]);

      await tester.tap(find.text('Usage analytics'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crash reports'));
      await tester.pumpAndSettle();

      expect(settings.stored.analyticsConsent, isTrue);
      expect(settings.stored.crashReportsConsent, isTrue);
      expect(settings.stored.onboardingComplete, isFalse);

      await _continue(tester);

      expect(settings.stored.onboardingComplete, isTrue);
      expect(find.byType(WelcomePage), findsOneWidget);
      expect(telemetry.events.single.parameters, {
        'daily_goal_minutes': 15,
        'left_handed': 1,
      });
      handle.dispose();
    });

    testWidgets('preselects the only pack and stores a picked one', (
      tester,
    ) async {
      final settings = await _start(tester);
      await _getStarted(tester);

      final step = tester.widget<SignLanguageStep>(
        find.byType(SignLanguageStep),
      );
      expect(step.selected, 'demo');

      step.onSelected('demo');
      await tester.pumpAndSettle();

      expect(settings.stored.signLanguage, 'demo');
    });

    testWidgets('lets the learner pick between several packs', (tester) async {
      String? picked;
      const other = SignLanguagePack(
        code: 'other',
        name: LocalizedText({'en': 'Other pack'}),
        fingerspelling: FingerspellingStyle.oneHanded,
        isPlaceholder: false,
      );
      await tester.pumpWidget(
        viewUnderTest(
          settings: englishLight,
          child: Scaffold(
            body: SignLanguageStep(
              packs: PacksReady([demoCatalog.pack, other]),
              selected: 'demo',
              onSelected: (code) => picked = code,
              onRetry: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Other pack'));
      await tester.pumpAndSettle();

      expect(picked, 'other');
    });

    testWidgets('opens the privacy policy from the privacy step', (
      tester,
    ) async {
      await _start(tester);
      await _getStarted(tester);
      await _continue(tester);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Privacy policy'));
      await tester.pumpAndSettle();

      expect(
        fakeLinks.launched.single.url,
        'https://gestura-prod.web.app/privacy/en',
      );
    });

    testWidgets('skips the optional steps', (tester) async {
      final settings = await _start(tester);
      await _getStarted(tester);
      await _continue(tester);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Your privacy'), findsOneWidget);
      expect(settings.stored.dailyGoal, DailyGoal.ten);
      expect(settings.stored.dominantHand, DominantHand.right);
    });

    testWidgets('goes back a step with the back button and the system back', (
      tester,
    ) async {
      await _start(tester);
      await _getStarted(tester);
      await _continue(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Which sign language do you want to learn?'),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeStep), findsOneWidget);
    });

    testWidgets('explains packs that fail to load and tries again', (
      tester,
    ) async {
      final content = FakeContentRepository()..failure = const NetworkFailure();
      await _start(tester, content: content);
      await _getStarted(tester);

      expect(find.byType(GErrorView), findsOneWidget);
      expect(
        tester
            .widget<GButton>(find.widgetWithText(GButton, 'Continue'))
            .onPressed,
        isNull,
      );

      content.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Demo pack'), findsOneWidget);
    });

    testWidgets('says packs are coming when none is published', (tester) async {
      final content = FakeContentRepository()
        ..failure = const NoContentFailure();
      final settings = await _start(tester, content: content);
      await _getStarted(tester);

      expect(
        find.text(
          'Sign language packs are on their way. You can continue now, and '
          'they will appear here once they are ready.',
        ),
        findsOneWidget,
      );

      await _continue(tester);

      expect(find.text('Set a daily goal'), findsOneWidget);
      expect(settings.stored.signLanguage, isNull);
    });

    testWidgets('shows a skeleton while the packs load', (tester) async {
      final handle = tester.ensureSemantics();
      final content = FakeContentRepository()..hold = Completer();
      await _start(
        tester,
        content: content,
        settings: _firstRun.copyWith(reduceMotion: true),
      );
      await _getStarted(tester);

      expect(find.byType(GSkeleton), findsOneWidget);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);

      content.hold!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Demo pack'), findsOneWidget);
      handle.dispose();
    });

    for (final settings in [
      _firstRun,
      const AppSettings(
        language: AppLanguage.arabic,
        theme: AppThemePreference.dark,
      ),
    ]) {
      testWidgets('meets the accessibility guidelines on every step in '
          '${settings.language.name}', (tester) async {
        final handle = tester.ensureSemantics();
        await _start(tester, settings: settings);

        for (var step = 0; step < 5; step++) {
          await tester.expectAccessible();
          await tester.tap(find.byType(GButton).last);
          await tester.pumpAndSettle();
        }
        handle.dispose();
      });
    }

    testWidgets('fits at 200% text on a small phone', (tester) async {
      await _start(tester, textScale: 2, surfaceSize: const Size(320, 640));

      for (var step = 0; step < 5; step++) {
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(GButton).last);
        await tester.pumpAndSettle();
      }
    });
  });
}
