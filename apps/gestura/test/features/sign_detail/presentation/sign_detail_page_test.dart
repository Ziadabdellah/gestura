import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/core/widgets/placeholder_content_notice.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/lesson/presentation/widgets/sign_video_stage.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/sign_detail/presentation/pages/sign_detail_page.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/pump_app.dart';

final String _hello = const SignRoute(signId: 'hello').location;

SignVideoStage _stage(WidgetTester tester) =>
    tester.widget<SignVideoStage>(find.byType(SignVideoStage));

ContentCatalog _withRealSource() => ContentCatalog(
  pack: demoCatalog.pack,
  categories: demoCatalog.categories,
  courses: demoCatalog.courses,
  signs: [
    for (final sign in demoCatalog.signs)
      Sign(
        id: sign.id,
        gloss: sign.gloss,
        meaning: sign.meaning,
        category: sign.category,
        media: sign.media,
        source: const ContentSource(name: 'Deaf Archive', license: 'CC BY 4.0'),
      ),
  ],
);

void main() {
  group('Sign detail', () {
    testWidgets('shows the sign, its category and how to sign it', (
      tester,
    ) async {
      await tester.pumpApp(initialLocation: _hello);

      expect(find.byType(SignDetailPage), findsOneWidget);
      expect(_stage(tester).sign?.gloss, 'HELLO');
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('HELLO'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Greetings'), findsOneWidget);
      expect(find.text('How to sign'), findsOneWidget);
      expect(
        find.text(
          'A description of how to make this sign comes with the recorded '
          'video.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('links the other signs of the same category', (tester) async {
      await tester.pumpApp(initialLocation: _hello);

      await tester.scrollUntilVisible(find.text('Related signs'), 100);
      final related = [
        for (final chip in tester.widgetList<ActionChip>(
          find.byType(ActionChip),
        ))
          (chip.label as Text).data,
      ];

      expect(related, ['No', 'Please', 'Sorry', 'Thank you', 'Yes']);

      await tester.ensureVisible(find.widgetWithText(ActionChip, 'Please'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'Please'));
      await tester.pumpAndSettle();

      expect(_stage(tester).sign?.gloss, 'PLEASE');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(_stage(tester).sign?.gloss, 'HELLO');
    });

    testWidgets('marks demo content', (tester) async {
      await tester.pumpApp(initialLocation: _hello);
      await tester.scrollUntilVisible(
        find.byType(PlaceholderContentNotice),
        100,
      );

      expect(find.byType(PlaceholderContentNotice), findsOneWidget);
      expect(find.textContaining('Source:'), findsNothing);
    });

    testWidgets('names the source of a recorded sign', (tester) async {
      await tester.pumpApp(
        initialLocation: _hello,
        content: FakeContentRepository(catalog: _withRealSource()),
      );
      await tester.scrollUntilVisible(find.textContaining('Source:'), 100);

      expect(
        find.text('Source: Deaf Archive · License: CC BY 4.0'),
        findsOneWidget,
      );
      expect(find.byType(PlaceholderContentNotice), findsNothing);
    });

    testWidgets('starts mirrored for a left-handed signer', (tester) async {
      await tester.pumpApp(
        initialLocation: _hello,
        settings: englishLight.copyWith(dominantHand: DominantHand.left),
      );

      expect(_stage(tester).playback.mirrored, isTrue);
    });

    testWidgets('changes the playback from the controls', (tester) async {
      await tester.pumpApp(initialLocation: _hello);

      await tester.tap(find.text('0.5×'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Loop'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mirror'));
      await tester.pumpAndSettle();

      expect(
        _stage(tester).playback,
        const Playback(
          speed: PlaybackSpeed.half,
          looping: false,
          mirrored: true,
        ),
      );
    });

    testWidgets('shows a skeleton while the sign loads', (tester) async {
      final content = FakeContentRepository()..hold = Completer();
      await tester.pumpApp(
        initialLocation: _hello,
        content: content,
        settings: englishLight.copyWith(reduceMotion: true),
      );

      expect(find.byType(GSkeleton), findsWidgets);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);

      content.hold!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(GSkeleton), findsNothing);
    });

    testWidgets('explains a failure and tries again', (tester) async {
      final content = FakeContentRepository()..failure = const NetworkFailure();
      await tester.pumpApp(initialLocation: _hello, content: content);

      expect(find.byType(GErrorView), findsOneWidget);

      content.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(_stage(tester).sign?.gloss, 'HELLO');
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
          '${settings.language.name} ${settings.theme.name}', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpApp(settings: settings, initialLocation: _hello);

        await tester.expectAccessible();
        handle.dispose();
      });
    }

    testWidgets('fits at 200% text on a small phone', (tester) async {
      await tester.pumpApp(
        initialLocation: _hello,
        surfaceSize: const Size(320, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
