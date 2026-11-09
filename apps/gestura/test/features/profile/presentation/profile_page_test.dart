import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/presentation/pages/settings_page.dart';

import '../../../helpers/pump_app.dart';

final String _profile = const ProfileRoute().location;

void main() {
  group('Profile', () {
    testWidgets('shows the app version', (tester) async {
      await tester.pumpApp(initialLocation: _profile);

      expect(find.text('About Gestura'), findsOneWidget);
      expect(find.text('Version 1.0.0 (7)'), findsOneWidget);
    });

    testWidgets('opens settings inside the Profile tab', (tester) async {
      await tester.pumpApp(initialLocation: _profile);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('opens the about page with the open-source licenses', (
      tester,
    ) async {
      await tester.pumpApp(initialLocation: _profile);

      await tester.tap(find.text('About Gestura'));
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
      expect(find.text('Gestura'), findsWidgets);
      expect(find.text('1.0.0 (7)'), findsOneWidget);
      expect(
        find.text(
          'A learning companion, not a replacement for Deaf teachers and '
          'communities.',
        ),
        findsOneWidget,
      );
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
        await tester.pumpApp(settings: settings, initialLocation: _profile);

        await tester.expectAccessible();
        handle.dispose();
      });
    }

    testWidgets('fits at 200% text on a small phone', (tester) async {
      await tester.pumpApp(
        initialLocation: _profile,
        surfaceSize: const Size(320, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
