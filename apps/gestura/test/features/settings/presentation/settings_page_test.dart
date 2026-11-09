import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/features/profile/presentation/pages/profile_page.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/presentation/pages/settings_page.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../../helpers/pump_app.dart';

final String _settings = const SettingsRoute().location;

void main() {
  group('Settings', () {
    testWidgets('opens from the profile and goes back', (tester) async {
      await tester.pumpApp();

      await tester.tapDestination('Profile');
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('lists every language by its own name', (tester) async {
      await tester.pumpApp(initialLocation: _settings);

      for (final name in [
        'Device language',
        'English',
        'العربية',
        'Русский',
        'Español',
        'Français',
        'Deutsch',
      ]) {
        await tester.scrollUntilVisible(find.text(name), 100);
        expect(find.text(name), findsOneWidget);
      }
    });

    testWidgets('switches the whole app to the chosen language', (
      tester,
    ) async {
      final repository = await tester.pumpApp(initialLocation: _settings);

      await tester.scrollUntilVisible(find.text('العربية'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();

      expect(find.text('الإعدادات'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('الإعدادات'))),
        TextDirection.rtl,
      );
      expect(repository.stored.language, AppLanguage.arabic);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('الملف الشخصي'), findsWidgets);
    });

    testWidgets('switches the theme right away', (tester) async {
      final repository = await tester.pumpApp(initialLocation: _settings);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SettingsPage));

      expect(Theme.of(context).brightness, Brightness.dark);
      expect(repository.stored.theme, AppThemePreference.dark);
    });

    testWidgets('turns reduce motion on for the whole app', (tester) async {
      final repository = await tester.pumpApp(initialLocation: _settings);

      await tester.scrollUntilVisible(find.byType(SwitchListTile), 100);
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SettingsPage));

      expect(MediaQuery.disableAnimationsOf(context), isTrue);
      expect(repository.stored.reduceMotion, isTrue);
    });

    testWidgets('tells the user and keeps the old choice when saving fails', (
      tester,
    ) async {
      final repository = await tester.pumpApp(initialLocation: _settings);
      repository.failure = const UnexpectedFailure('disk');

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SettingsPage));

      expect(
        find.text("Couldn't save your settings. Please try again."),
        findsOneWidget,
      );
      expect(Theme.of(context).brightness, Brightness.light);
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
        await tester.pumpApp(settings: settings, initialLocation: _settings);

        await tester.expectAccessible();
        handle.dispose();
      });
    }

    testWidgets('fits at 200% text on a small phone', (tester) async {
      await tester.pumpApp(
        initialLocation: _settings,
        surfaceSize: const Size(320, 640),
        textScale: 2,
      );

      await tester.scrollUntilVisible(find.text('Reduce motion'), 200);

      expect(tester.takeException(), isNull);
    });
  });
}
