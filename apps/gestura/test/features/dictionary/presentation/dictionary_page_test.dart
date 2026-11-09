import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/core/widgets/placeholder_content_notice.dart';
import 'package:gestura/features/dictionary/presentation/widgets/sign_tile.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/pump_app.dart';

final String _dictionary = const DictionaryRoute().location;

void main() {
  group('Dictionary', () {
    testWidgets('lists the signs by gloss with their meaning', (tester) async {
      await tester.pumpApp(initialLocation: _dictionary);

      final first = tester.widget<SignTile>(find.byType(SignTile).first);

      expect(first.sign.gloss, 'BROTHER');
      expect(find.text('BROTHER'), findsOneWidget);
      expect(find.text('Brother'), findsOneWidget);
      expect(find.byType(PlaceholderContentNotice), findsOneWidget);
    });

    testWidgets('reaches every sign', (tester) async {
      await tester.pumpApp(initialLocation: _dictionary);

      final glosses = [for (final sign in demoCatalog.signs) sign.gloss]
        ..sort();

      for (final gloss in glosses) {
        await tester.scrollUntilVisible(find.text(gloss), 100);
        expect(find.text(gloss), findsOneWidget);
      }
    });

    testWidgets('shows each meaning in the interface language', (tester) async {
      await tester.pumpApp(
        initialLocation: _dictionary,
        settings: englishLight.copyWith(language: AppLanguage.german),
      );

      expect(find.text('Bruder'), findsOneWidget);
    });

    testWidgets('shows the thumbnail of each sign, hidden from screen '
        'readers', (tester) async {
      await tester.pumpApp(initialLocation: _dictionary);

      final image = tester.widget<Image>(
        find.descendant(
          of: find.byType(SignTile).first,
          matching: find.byType(Image),
        ),
      );

      expect(
        (image.image as ResizeImage).imageProvider,
        isA<AssetImage>().having(
          (asset) => asset.assetName,
          'asset',
          'assets/content/demo/media/brother.webp',
        ),
      );
      expect(image.excludeFromSemantics, isTrue);
    });

    testWidgets('keeps the row when a thumbnail is missing', (tester) async {
      await tester.pumpApp(initialLocation: _dictionary);
      final image = tester.widget<Image>(find.byType(Image).first);

      final fallback = image.errorBuilder!(
        tester.element(find.byType(Image).first),
        StateError('missing'),
        null,
      );

      expect(fallback, isA<ColoredBox>());
    });

    testWidgets('explains a failure and tries again', (tester) async {
      final content = FakeContentRepository()..failure = const NetworkFailure();
      await tester.pumpApp(initialLocation: _dictionary, content: content);

      expect(find.byType(GErrorView), findsOneWidget);
      expect(
        find.text("You're offline. Check your connection and try again."),
        findsOneWidget,
      );

      content.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byType(SignTile), findsWidgets);
      expect(content.requests, 2);
    });

    for (final settings in [
      englishLight,
      const AppSettings(
        language: AppLanguage.arabic,
        theme: AppThemePreference.dark,
      ),
    ]) {
      testWidgets('meets the accessibility guidelines in '
          '${settings.language.name} ${settings.theme.name}', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpApp(settings: settings, initialLocation: _dictionary);

        await tester.expectAccessible();
        handle.dispose();
      });
    }

    testWidgets('fits at 200% text on a small phone', (tester) async {
      await tester.pumpApp(
        initialLocation: _dictionary,
        surfaceSize: const Size(320, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
