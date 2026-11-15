import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/app/view/flavor_banner.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/features/learn/presentation/pages/learn_page.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../helpers/fake_remote_progress_store.dart';
import '../helpers/fake_telemetry.dart';
import '../helpers/pump_app.dart';

Finder _navigationLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  group('GesturaApp', () {
    testWidgets('opens on the Learn tab', (tester) async {
      await tester.pumpApp();

      expect(find.byType(LearnPage), findsOneWidget);
    });

    for (final locale in AppLocalizations.supportedLocales) {
      testWidgets('names the tabs in ${locale.languageCode}', (tester) async {
        final l10n = lookupAppLocalizations(locale);
        await tester.pumpApp(
          settings: englishLight.copyWith(
            language: AppLanguage.fromCode(locale.languageCode),
          ),
        );

        for (final label in [
          l10n.tabLearn,
          l10n.tabDictionary,
          l10n.tabProfile,
        ]) {
          expect(_navigationLabel(label), findsOneWidget);
        }
      });
    }

    testWidgets('lays out Arabic right to left', (tester) async {
      await tester.pumpApp(
        settings: englishLight.copyWith(language: AppLanguage.arabic),
      );

      final bar = tester.element(find.byType(NavigationBar));
      final learn = tester.getCenter(_navigationLabel('تعلّم'));
      final profile = tester.getCenter(_navigationLabel('الملف الشخصي'));

      expect(Directionality.of(bar), TextDirection.rtl);
      expect(learn.dx, greaterThan(profile.dx));
    });

    testWidgets('keeps every other language left to right', (tester) async {
      for (final language in [
        AppLanguage.english,
        AppLanguage.russian,
        AppLanguage.spanish,
        AppLanguage.french,
        AppLanguage.german,
      ]) {
        await tester.pumpApp(
          settings: englishLight.copyWith(language: language),
        );

        expect(
          Directionality.of(tester.element(find.byType(NavigationBar))),
          TextDirection.ltr,
          reason: language.name,
        );
      }
    });

    testWidgets('follows the device language when set to system', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('fr')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester.pumpApp(
        settings: const AppSettings(onboardingComplete: true),
      );

      expect(_navigationLabel('Apprendre'), findsOneWidget);
    });

    testWidgets('takes its title from the translations', (tester) async {
      await tester.pumpApp(
        settings: englishLight.copyWith(language: AppLanguage.russian),
      );

      expect(tester.widget<Title>(find.byType(Title)).title, 'Gestura');
    });

    testWidgets('applies the privacy choices to analytics and crash reports', (
      tester,
    ) async {
      final telemetry = FakeTelemetry();
      await tester.pumpApp(
        telemetry: telemetry,
        initialLocation: const SettingsRoute().location,
      );

      expect(telemetry.consents, [(analytics: false, crashReports: false)]);

      final crashes = find.widgetWithText(SwitchListTile, 'Crash reports');
      await tester.scrollUntilVisible(crashes, 100);
      await tester.pumpAndSettle();
      await tester.tap(crashes);
      await tester.pumpAndSettle();

      expect(telemetry.consents.last, (analytics: false, crashReports: true));
    });

    testWidgets('syncs progress when the learner comes back to the app', (
      tester,
    ) async {
      final remote = FakeRemoteProgressStore();
      await tester.pumpApp(remote: remote);

      expect(remote.calls, ['fetch:guest-uid', 'save:guest-uid:0']);

      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(remote.calls, [
        'fetch:guest-uid',
        'save:guest-uid:0',
        'fetch:guest-uid',
        'save:guest-uid:0',
      ]);
    });

    testWidgets('uses the saved theme', (tester) async {
      await tester.pumpApp(
        settings: englishLight.copyWith(theme: AppThemePreference.dark),
      );

      final context = tester.element(find.byType(LearnPage));

      expect(Theme.of(context).brightness, Brightness.dark);
      expect(Theme.of(context).colorScheme, GesturaColorSchemes.dark);
    });

    testWidgets('turns off animations when reduce motion is saved', (
      tester,
    ) async {
      await tester.pumpApp(settings: englishLight.copyWith(reduceMotion: true));

      final context = tester.element(find.byType(LearnPage));

      expect(MediaQuery.disableAnimationsOf(context), isTrue);
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
          .renderObject<RenderParagraph>(find.text('Hello and thank you'))
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

      await tester.expectAccessible();
      expect(
        tester.getSemantics(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('Learn'),
          ),
        ),
        isSemantics(isHeader: true),
      );
      handle.dispose();
    });
  });
}
