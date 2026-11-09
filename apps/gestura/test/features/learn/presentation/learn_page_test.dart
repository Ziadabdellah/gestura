import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/widgets/list_skeleton.dart';
import 'package:gestura/core/widgets/placeholder_content_notice.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('Learn', () {
    testWidgets('shows the course with its level and pack', (tester) async {
      await tester.pumpApp();

      expect(find.text('First signs'), findsOneWidget);
      expect(find.text('Level A1'), findsOneWidget);
      expect(find.text('Demo pack'), findsOneWidget);
    });

    testWidgets('lists every unit with its lessons in order', (tester) async {
      await tester.pumpApp(surfaceSize: const Size(360, 1200));

      expect(find.text('Greetings'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
      expect(find.text('2 lessons'), findsNWidgets(2));
      final titles = [
        'Hello and thank you',
        'Yes, no and sorry',
        'Parents',
        'Brothers, sisters and friends',
      ];
      final tops = [
        for (final title in titles) tester.getTopLeft(find.text(title)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
    });

    testWidgets('numbers the lessons inside each unit', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp();

      expect(
        tester.getSemantics(find.text('Hello and thank you')),
        isSemantics(label: '1\nHello and thank you'),
      );
      expect(
        tester.getSemantics(find.text('Greetings')),
        isSemantics(label: 'Greetings\n2 lessons', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('speaks the language of the interface', (tester) async {
      await tester.pumpApp(
        settings: englishLight.copyWith(language: AppLanguage.arabic),
      );

      expect(find.text('أولى الإشارات'), findsOneWidget);
      expect(find.text('المستوى A1'), findsOneWidget);
      expect(find.text('التحيات'), findsOneWidget);
      expect(find.text('درسان'), findsWidgets);
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

    testWidgets('fits at 200% text on a small phone', (tester) async {
      await tester.pumpApp(surfaceSize: const Size(320, 640), textScale: 2);

      await tester.scrollUntilVisible(
        find.text('Brothers, sisters and friends'),
        200,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
