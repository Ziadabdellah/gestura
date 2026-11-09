import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/view/flavor_banner.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../helpers/pump_app.dart';

void main() {
  group('GesturaApp', () {
    for (final locale in AppLocalizations.supportedLocales) {
      testWidgets('shows the tagline in ${locale.languageCode}', (
        tester,
      ) async {
        await tester.pumpApp(locale: locale);

        expect(
          find.text(lookupAppLocalizations(locale).tagline),
          findsOneWidget,
        );
      });
    }

    testWidgets('lays out Arabic right to left', (tester) async {
      await tester.pumpApp(locale: const Locale('ar'));

      final tagline = find.text(
        lookupAppLocalizations(const Locale('ar')).tagline,
      );

      expect(Directionality.of(tester.element(tagline)), TextDirection.rtl);
    });

    testWidgets('keeps every other language left to right', (tester) async {
      for (final code in ['en', 'ru', 'es', 'fr', 'de']) {
        final locale = Locale(code);
        await tester.pumpApp(locale: locale);
        final tagline = find.text(lookupAppLocalizations(locale).tagline);

        expect(
          Directionality.of(tester.element(tagline)),
          TextDirection.ltr,
          reason: code,
        );
      }
    });

    testWidgets('takes its title from the translations', (tester) async {
      await tester.pumpApp(locale: const Locale('ru'));

      expect(tester.widget<Title>(find.byType(Title)).title, 'Gestura');
    });

    testWidgets('follows the dark theme', (tester) async {
      await tester.pumpApp(themeMode: ThemeMode.dark);

      final context = tester.element(find.byType(Scaffold));

      expect(Theme.of(context).brightness, Brightness.dark);
      expect(Theme.of(context).colorScheme, GesturaColorSchemes.dark);
    });

    testWidgets('marks dev and staging builds with their flavor', (
      tester,
    ) async {
      for (final flavor in [Flavor.dev, Flavor.staging]) {
        await tester.pumpApp(flavor: flavor);

        final banner = tester.widget<Banner>(find.byType(Banner));

        expect(find.byType(FlavorBanner), findsOneWidget);
        expect(banner.message, flavor.name.toUpperCase());
      }
    });

    testWidgets('shows no banner in production', (tester) async {
      await tester.pumpApp();

      expect(find.byType(FlavorBanner), findsNothing);
      expect(find.byType(Banner), findsNothing);
    });

    testWidgets('scales text up on a large phone', (tester) async {
      await tester.pumpApp(surfaceSize: const Size(430, 932));

      final style = tester
          .renderObject<RenderParagraph>(
            find.text('Sign language, in your hands.'),
          )
          .text
          .style!;

      expect(style.fontSize, closeTo(16 * GesturaScale.maxText, 0.01));
    });

    testWidgets('fits at 200% text on a small phone', (tester) async {
      await tester.pumpApp(surfaceSize: const Size(320, 640), textScale: 2);

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the accessibility guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(
        tester.getSemantics(find.text('Gestura')),
        isSemantics(isHeader: true),
      );
      handle.dispose();
    });
  });
}
