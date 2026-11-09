import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../helpers/pump_gestura.dart';

void main() {
  group('GButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpGestura(
        GButton(label: 'Continue', onPressed: () => taps++),
      );

      await tester.tap(find.text('Continue'));

      expect(taps, 1);
    });

    testWidgets('maps each variant to its Material button', (tester) async {
      await tester.pumpGestura(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GButton(label: 'Primary', onPressed: () {}),
            GButton.secondary(label: 'Secondary', onPressed: () {}),
            GButton.text(label: 'Text', onPressed: () {}),
          ],
        ),
      );

      expect(
        find.ancestor(
          of: find.text('Primary'),
          matching: find.byType(FilledButton),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.text('Secondary'),
          matching: find.byType(OutlinedButton),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: find.text('Text'), matching: find.byType(TextButton)),
        findsOneWidget,
      );
    });

    testWidgets('paints destructive buttons with the error colors', (
      tester,
    ) async {
      await tester.pumpGestura(
        GButton.destructive(label: 'Delete pack', onPressed: () {}),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final style = button.style!;

      expect(
        style.backgroundColor!.resolve({}),
        GesturaColorSchemes.light.error,
      );
      expect(
        style.foregroundColor!.resolve({}),
        GesturaColorSchemes.light.onError,
      );
    });

    testWidgets('shows a progress indicator and ignores taps while loading', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpGestura(
        GButton(label: 'Continue', onPressed: () => taps++, isLoading: true),
      );

      await tester.tap(find.text('Continue'), warnIfMissed: false);

      final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      expect(spinner.backgroundColor, Colors.transparent);
      expect(spinner.color, GesturaColorSchemes.light.onPrimary);
      expect(taps, 0);
      expect(
        tester.getSemantics(find.byType(GButton)),
        isSemantics(label: 'Continue', isButton: true, isEnabled: false),
      );
    });

    testWidgets('keeps its colors while loading so it does not look disabled', (
      tester,
    ) async {
      await tester.pumpGestura(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GButton(label: 'Busy', onPressed: () {}, isLoading: true),
            const GButton(label: 'Off', onPressed: null),
          ],
        ),
      );

      Color? background(String label) {
        final button = find.ancestor(
          of: find.text(label),
          matching: find.byType(Material),
        );
        return tester.widget<Material>(button.first).color;
      }

      expect(background('Busy'), GesturaColorSchemes.light.primary);
      expect(background('Off'), isNot(GesturaColorSchemes.light.primary));
    });

    testWidgets('places the icon before the label in LTR', (tester) async {
      await tester.pumpGestura(
        GButton(label: 'Retry', onPressed: () {}, icon: Icons.refresh_rounded),
      );

      final icon = tester.getCenter(find.byIcon(Icons.refresh_rounded));
      final label = tester.getCenter(find.text('Retry'));

      expect(icon.dx, lessThan(label.dx));
    });

    testWidgets('places the icon before the label in RTL', (tester) async {
      await tester.pumpGestura(
        GButton(
          label: 'حاول مرة أخرى',
          onPressed: () {},
          icon: Icons.refresh_rounded,
        ),
        locale: const Locale('ar'),
      );

      final icon = tester.getCenter(find.byIcon(Icons.refresh_rounded));
      final label = tester.getCenter(find.text('حاول مرة أخرى'));

      expect(icon.dx, greaterThan(label.dx));
    });

    testWidgets('fills the available width when expand is set', (tester) async {
      await tester.pumpGestura(
        SizedBox(
          width: 300,
          child: GButton(label: 'Continue', onPressed: () {}, expand: true),
        ),
      );

      expect(tester.getSize(find.byType(FilledButton)).width, 300);
    });

    for (final brightness in Brightness.values) {
      testWidgets('meets the accessibility guidelines in ${brightness.name}', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpGestura(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GButton(label: 'Continue', onPressed: () {}),
              GButton.secondary(label: 'Review mistakes', onPressed: () {}),
              GButton.text(label: 'Skip for now', onPressed: () {}),
              GButton.destructive(label: 'Delete pack', onPressed: () {}),
            ],
          ),
          brightness: brightness,
        );

        await tester.expectAccessible();
        handle.dispose();
      });
    }

    testWidgets('wraps long labels at 200% text without overflow', (
      tester,
    ) async {
      await tester.pumpGestura(
        GButton(
          label: 'Continue to the next lesson in this unit',
          onPressed: () {},
          icon: Icons.play_arrow_rounded,
          expand: true,
        ),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
