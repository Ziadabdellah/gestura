import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/app/view/app_destination.dart';
import 'package:gestura/app/view/app_shell.dart';
import 'package:gestura/features/dictionary/presentation/pages/dictionary_page.dart';
import 'package:gestura/features/learn/presentation/pages/learn_page.dart';
import 'package:gestura/features/profile/presentation/pages/profile_page.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/presentation/pages/settings_page.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/pump_app.dart';

const AppSettings _arabicDark = AppSettings(
  language: AppLanguage.arabic,
  theme: AppThemePreference.dark,
);

int _selectedIndex(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  group('AppShell', () {
    testWidgets('has one destination for every branch', (tester) async {
      await tester.pumpApp();

      final shell = tester.widget<AppShell>(find.byType(AppShell));

      expect(
        shell.navigationShell.route.branches,
        hasLength(AppDestination.values.length),
      );
    });

    testWidgets('uses a bottom navigation bar on phones', (tester) async {
      await tester.pumpApp();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(_selectedIndex(tester), AppDestination.learn.index);
    });

    testWidgets('uses a navigation rail from 600 dp', (tester) async {
      await tester.pumpApp(surfaceSize: const Size(600, 960));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('puts the rail on the leading side', (tester) async {
      await tester.pumpApp(surfaceSize: tabletSize);
      final leftToRight = tester.getRect(find.byType(NavigationRail));

      await tester.pumpApp(surfaceSize: tabletSize, settings: _arabicDark);
      final rightToLeft = tester.getRect(find.byType(NavigationRail));

      expect(leftToRight.left, 0);
      expect(rightToLeft.right, tabletSize.width);
    });

    testWidgets('switches tabs from the rail', (tester) async {
      await tester.pumpApp(surfaceSize: tabletSize);

      await tester.tapDestination('Dictionary');

      expect(find.byType(DictionaryPage), findsOneWidget);
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        AppDestination.dictionary.index,
      );
    });

    testWidgets('opens each tab', (tester) async {
      await tester.pumpApp();

      await tester.tapDestination('Dictionary');
      expect(find.byType(DictionaryPage), findsOneWidget);
      expect(_selectedIndex(tester), AppDestination.dictionary.index);

      await tester.tapDestination('Profile');
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(_selectedIndex(tester), AppDestination.profile.index);

      await tester.tapDestination('Learn');
      expect(find.byType(LearnPage), findsOneWidget);
      expect(_selectedIndex(tester), AppDestination.learn.index);
    });

    testWidgets('keeps the place in each tab', (tester) async {
      await tester.pumpApp(initialLocation: const SettingsRoute().location);

      await tester.tapDestination('Learn');
      await tester.tapDestination('Profile');

      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('goes back to the start of a tab when it is tapped again', (
      tester,
    ) async {
      await tester.pumpApp(initialLocation: const SettingsRoute().location);

      await tester.tapDestination('Profile');

      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('sends the root address to Learn', (tester) async {
      await tester.pumpApp();

      final router = GoRouter.of(tester.element(find.byType(LearnPage)));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        const LearnRoute().location,
      );
    });

    for (final (name, size) in [('phone', phoneSize), ('tablet', tabletSize)]) {
      for (final settings in [englishLight, _arabicDark]) {
        testWidgets('meets the accessibility guidelines on a $name in '
            '${settings.language.name}', (tester) async {
          final handle = tester.ensureSemantics();
          await tester.pumpApp(settings: settings, surfaceSize: size);

          await tester.expectAccessible();
          handle.dispose();
        });
      }
    }
  });
}
