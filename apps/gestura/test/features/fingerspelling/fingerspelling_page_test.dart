import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/fingerspelling/presentation/pages/fingerspelling_page.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../helpers/fake_content_repository.dart';
import '../../helpers/pump_app.dart';

const String _alphabet = '/dictionary/alphabet';

void main() {
  testWidgets('opens from the dictionary and plays a chosen letter', (
    tester,
  ) async {
    await tester.pumpApp(initialLocation: '/dictionary');

    await tester.tap(find.byTooltip('Fingerspelling'));
    await tester.pumpAndSettle();
    expect(find.byType(FingerspellingPage), findsOneWidget);

    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Letter Q'),
      100,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Letter Q'));
    await tester.pumpAndSettle();

    expect(fakeVideo.opened.last, endsWith('letter-q.mp4'));
  });

  testWidgets('spells a typed word letter by letter', (tester) async {
    await tester.pumpApp(initialLocation: _alphabet);

    await tester.enterText(find.byType(TextField), 'cab');
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Letter C'), findsNWidgets(2));
    expect(fakeVideo.opened.last, endsWith('letter-c.mp4'));
  });

  testWidgets('retries a failure', (tester) async {
    final content = FakeContentRepository()..failure = const NetworkFailure();
    await tester.pumpApp(initialLocation: _alphabet, content: content);

    content.failure = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Alphabet'), findsOneWidget);
  });

  testWidgets('says when letters are not ready', (tester) async {
    await tester.pumpApp(
      initialLocation: _alphabet,
      content: FakeContentRepository(
        catalog: ContentCatalog(
          pack: demoCatalog.pack,
          categories: demoCatalog.categories,
          courses: demoCatalog.courses,
          signs: demoCatalog.signs,
        ),
      ),
    );
    expect(
      find.text('Letters for this sign language are on their way.'),
      findsOneWidget,
    );
  });

  testWidgets('changes speed, loop and mirror', (tester) async {
    await tester.pumpApp(initialLocation: _alphabet);

    await tester.tap(find.text('0.5×'));
    await tester.tap(find.byTooltip('Loop'));
    await tester.tap(find.byTooltip('Mirror'));
    await tester.pumpAndSettle();

    expect(fakeVideo.calls, contains('speed 0.5'));
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
      await tester.pumpApp(initialLocation: _alphabet, settings: settings);

      await tester.expectAccessible();
      handle.dispose();
    });
  }

  testWidgets('fits at 200% text on a small phone', (tester) async {
    await tester.pumpApp(
      initialLocation: _alphabet,
      surfaceSize: const Size(320, 640),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
  });
}
