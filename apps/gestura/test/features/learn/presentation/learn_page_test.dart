import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/widgets/list_skeleton.dart';
import 'package:gestura/core/widgets/placeholder_content_notice.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/learn/presentation/widgets/unit_progress_ring.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/fake_progress_repository.dart';
import '../../../helpers/pump_app.dart';

const AppSettings _arabicDark = AppSettings(
  language: AppLanguage.arabic,
  theme: AppThemePreference.dark,
  onboardingComplete: true,
);

FakeProgressRepository _firstDone() =>
    FakeProgressRepository([completed('demo-a1-1')]);

Future<void> _openUnit(WidgetTester tester, String title) async {
  await tester.ensureVisible(find.text(title));
  await tester.pumpAndSettle();
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
  group('Learn', () {
    testWidgets('shows the course with its level and pack', (tester) async {
      await tester.pumpApp();

      expect(find.text('First signs'), findsOneWidget);
      expect(find.text('Level A1'), findsOneWidget);
      expect(find.text('Demo pack'), findsOneWidget);
    });

    testWidgets('starts with only the first lesson open', (tester) async {
      await tester.pumpApp();

      expect(find.text('0 of 4 done'), findsOneWidget);
      expect(find.text('2 lessons · 0 of 2 done'), findsNWidgets(2));
      expect(find.text('Up next'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
    });

    testWidgets('shows finished lessons with their best score', (tester) async {
      await tester.pumpApp(progress: _firstDone());

      expect(find.text('1 of 4 done'), findsOneWidget);
      expect(find.text('2 lessons · 1 of 2 done'), findsOneWidget);
      expect(find.text('Completed · Best score 90%'), findsOneWidget);
      expect(find.text('Up next'), findsOneWidget);
    });

    testWidgets('opens the unit with the next lesson and folds the others', (
      tester,
    ) async {
      await tester.pumpApp(progress: _firstDone());

      expect(find.text('Hello and thank you'), findsOneWidget);
      expect(find.text('Parents'), findsNothing);

      await _openUnit(tester, 'Family');

      expect(find.text('Parents'), findsOneWidget);
      expect(find.text('Brothers, sisters and friends'), findsOneWidget);
      expect(find.text('Locked'), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.text('Parents')).dy,
        lessThan(
          tester.getTopLeft(find.text('Brothers, sisters and friends')).dy,
        ),
      );
    });

    testWidgets('updates as soon as a lesson is finished', (tester) async {
      final progress = _firstDone();
      await tester.pumpApp(progress: progress);

      await progress.recordCompletion(const LessonId('demo-a1-2'), score: 75);
      await tester.pumpAndSettle();

      expect(find.text('2 of 4 done'), findsOneWidget);
      expect(find.text('Completed · Best score 75%'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(UnitProgressRing),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('reads each lesson as one item to screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(progress: _firstDone());

      expect(
        tester.getSemantics(find.text('Hello and thank you')),
        isSemantics(
          label: 'Lesson 1\nHello and thank you\nCompleted · Best score 90%',
        ),
      );
      expect(
        tester.getSemantics(find.text('Yes, no and sorry')),
        isSemantics(label: 'Lesson 2\nYes, no and sorry\nUp next'),
      );
      expect(
        tester.getSemantics(find.text('Family')),
        isSemantics(
          label: 'Family\n2 lessons · 0 of 2 done',
          hint: 'Collapsed',
          isHeader: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('folds and unfolds without animation under reduce motion', (
      tester,
    ) async {
      await tester.pumpApp(settings: englishLight.copyWith(reduceMotion: true));

      final tiles = tester.widgetList<ExpansionTile>(
        find.byType(ExpansionTile),
      );

      expect(
        tiles.map((tile) => tile.expansionAnimationStyle),
        everyElement(AnimationStyle.noAnimation),
      );
    });

    testWidgets('speaks the language of the interface', (tester) async {
      await tester.pumpApp(
        settings: englishLight.copyWith(language: AppLanguage.arabic),
        progress: _firstDone(),
      );

      expect(find.text('أولى الإشارات'), findsOneWidget);
      expect(find.text('المستوى A1'), findsOneWidget);
      expect(find.text('أنجزت 1 من 4'), findsOneWidget);
      expect(find.text('درسان · أنجزت 1 من 2'), findsOneWidget);
      expect(find.text('مكتمل · أفضل نتيجة 90%'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);
    });

    testWidgets('says when the content is a placeholder', (tester) async {
      await tester.pumpApp();

      expect(find.byType(PlaceholderContentNotice), findsOneWidget);
      expect(
        find.text('Demo content: real sign videos are on their way.'),
        findsOneWidget,
      );
    });

    testWidgets('hides the notice for real content', (tester) async {
      final real = ContentCatalog(
        pack: SignLanguagePack(
          code: 'real',
          name: demoCatalog.pack.name,
          fingerspelling: demoCatalog.pack.fingerspelling,
          isPlaceholder: false,
        ),
        categories: demoCatalog.categories,
        courses: demoCatalog.courses,
        signs: demoCatalog.signs,
      );
      await tester.pumpApp(content: FakeContentRepository(catalog: real));

      expect(find.byType(PlaceholderContentNotice), findsNothing);
    });

    testWidgets('shows a labelled skeleton while loading', (tester) async {
      final handle = tester.ensureSemantics();
      final content = FakeContentRepository()..hold = Completer<void>();
      await tester.pumpApp(
        settings: englishLight.copyWith(reduceMotion: true),
        content: content,
      );

      expect(find.byType(ListSkeleton), findsOneWidget);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);

      content.hold!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(ListSkeleton), findsNothing);
      expect(find.text('First signs'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('explains a failure and tries again', (tester) async {
      final content = FakeContentRepository()
        ..failure = const StorageFullFailure();
      await tester.pumpApp(content: content);

      expect(find.byType(GErrorView), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(
        find.text('Your device is out of space. Free some up and try again.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.sd_card_alert_outlined), findsOneWidget);

      content.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byType(GErrorView), findsNothing);
      expect(find.text('First signs'), findsOneWidget);
    });

    testWidgets('explains progress that cannot be read', (tester) async {
      final progress = FakeProgressRepository()
        ..watchFailure = const UnexpectedFailure('locked database');
      await tester.pumpApp(progress: progress);

      expect(
        find.text('Something unexpected happened. Please try again.'),
        findsOneWidget,
      );

      progress.watchFailure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('0 of 4 done'), findsOneWidget);
    });

    testWidgets('keeps lines short enough to read on a tablet', (tester) async {
      const landscape = Size(1280, 800);
      await tester.pumpApp(surfaceSize: landscape);

      final card = tester.getRect(find.byType(GCard).first);
      final rail = tester.getRect(find.byType(NavigationRail));

      expect(card.width, ReadableInset.maxContentWidth);
      expect(
        card.left - rail.right,
        closeTo(landscape.width - card.right, 0.01),
      );
    });

    for (final settings in [englishLight, _arabicDark]) {
      testWidgets('meets the accessibility guidelines with progress in '
          '${settings.language.name} ${settings.theme.name}', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpApp(settings: settings, progress: _firstDone());
        await _openUnit(
          tester,
          settings.language == AppLanguage.arabic ? 'العائلة' : 'Family',
        );

        await tester.expectAccessible();
        handle.dispose();
      });
    }

    testWidgets('fits at 200% text on a small phone', (tester) async {
      await tester.pumpApp(
        surfaceSize: const Size(320, 640),
        textScale: 2,
        progress: _firstDone(),
      );

      await tester.scrollUntilVisible(find.text('Family'), 200);
      await _openUnit(tester, 'Family');
      await tester.scrollUntilVisible(
        find.text('Brothers, sisters and friends'),
        200,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
