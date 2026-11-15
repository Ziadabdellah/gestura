import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/share/link_sharer.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/saved/presentation/pages/saved_signs_page.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/sign_detail/presentation/pages/sign_detail_page.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../helpers/fake_content_repository.dart';
import '../../helpers/fake_link_sharer.dart';
import '../../helpers/fake_saved_signs_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('Saved signs', () {
    testWidgets('a heart on a sign keeps it in the saved list', (tester) async {
      final saved = FakeSavedSignsRepository();
      await tester.pumpApp(
        initialLocation: '/dictionary/sign/hello',
        saved: saved,
      );

      await tester.tap(find.byTooltip('Save sign'));
      await tester.pumpAndSettle();

      expect(saved.saved, [const SignId('hello')]);
      expect(find.byTooltip('Remove from saved'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      await tester.tap(find.byTooltip('Remove from saved'));
      await tester.pumpAndSettle();

      expect(saved.saved, isEmpty);
    });

    testWidgets('shares the public link of a sign', (tester) async {
      await tester.pumpApp(initialLocation: '/dictionary/sign/hello');

      await tester.tap(find.byTooltip('Share sign'));
      await tester.pumpAndSettle();

      final sharer = getIt<LinkSharer>() as FakeLinkSharer;
      final (link, subject, origin) = sharer.shared.single;
      expect(link.toString(), 'https://gestura-prod.web.app/sign/hello');
      expect(subject, 'HELLO');
      expect(origin, isNotNull);
    });

    testWidgets('opens from the dictionary and opens a saved sign', (
      tester,
    ) async {
      await tester.pumpApp(
        initialLocation: '/dictionary',
        saved: FakeSavedSignsRepository([const SignId('yes')]),
      );

      await tester.tap(find.byTooltip('Saved signs'));
      await tester.pumpAndSettle();

      expect(find.byType(SavedSignsPage), findsOneWidget);
      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();

      expect(find.byType(SignDetailPage), findsOneWidget);
    });

    testWidgets('explains how to save when nothing is saved', (tester) async {
      await tester.pumpApp(initialLocation: '/dictionary/saved');

      expect(find.text('No saved signs yet'), findsOneWidget);
    });

    testWidgets('tries again after a failure', (tester) async {
      final content = FakeContentRepository()..failure = const NetworkFailure();
      await tester.pumpApp(
        initialLocation: '/dictionary/saved',
        content: content,
        saved: FakeSavedSignsRepository([const SignId('yes')]),
      );

      content.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('YES'), findsOneWidget);
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
          initialLocation: '/dictionary/saved',
          settings: settings,
          saved: FakeSavedSignsRepository([const SignId('yes')]),
        );

        await tester.expectAccessible();
        handle.dispose();
      });
    }

    testWidgets('fits at 200% text on a small phone', (tester) async {
      await tester.pumpApp(
        initialLocation: '/dictionary/saved',
        surfaceSize: const Size(320, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
