import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../helpers/pump_gestura.dart';

void main() {
  group('GChip', () {
    testWidgets('reports the toggled value when tapped', (tester) async {
      bool? received;
      await tester.pumpGestura(
        GChip(label: 'Food', onSelected: (value) => received = value),
      );

      await tester.tap(find.text('Food'));

      expect(received, isTrue);
    });

    testWidgets('exposes the selected state to assistive technology', (
      tester,
    ) async {
      await tester.pumpGestura(
        GChip(label: 'Food', selected: true, onSelected: (_) {}),
      );

      expect(
        tester.getSemantics(find.byType(FilterChip)),
        isSemantics(label: 'Food', isSelected: true),
      );
    });

    testWidgets('shows its icon only while unselected', (tester) async {
      await tester.pumpGestura(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GChip(label: 'Food', icon: Icons.restaurant, onSelected: (_) {}),
            GChip(
              label: 'Family',
              icon: Icons.family_restroom,
              selected: true,
              onSelected: (_) {},
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.family_restroom), findsNothing);
    });

    testWidgets('renders its label with the brand font and state color', (
      tester,
    ) async {
      await tester.pumpGestura(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GChip(label: 'Family', selected: true, onSelected: (_) {}),
            GChip(label: 'Food', onSelected: (_) {}),
          ],
        ),
      );

      TextStyle renderedStyle(String label) =>
          tester.renderObject<RenderParagraph>(find.text(label)).text.style!;
      const scheme = GesturaColorSchemes.light;

      expect(renderedStyle('Family').fontFamily, GesturaFonts.family);
      expect(renderedStyle('Family').color, scheme.onPrimaryContainer);
      expect(renderedStyle('Food').fontFamily, GesturaFonts.family);
      expect(renderedStyle('Food').color, scheme.onSurface);
    });

    testWidgets('marks selection with a checkmark, not color alone', (
      tester,
    ) async {
      await tester.pumpGestura(
        GChip(label: 'Food', selected: true, onSelected: (_) {}),
      );

      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      final theme = Theme.of(tester.element(find.byType(FilterChip)));

      expect(chip.showCheckmark ?? theme.chipTheme.showCheckmark, isTrue);
    });

    for (final brightness in Brightness.values) {
      testWidgets('meets the accessibility guidelines in ${brightness.name}', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpGestura(
          Wrap(
            spacing: 8,
            children: [
              GChip(label: 'Family', selected: true, onSelected: (_) {}),
              GChip(label: 'Food', onSelected: (_) {}),
            ],
          ),
          brightness: brightness,
        );

        await tester.expectAccessible();
        handle.dispose();
      });

      test('labels reach 4.5:1 on their fill in ${brightness.name}', () {
        final theme = switch (brightness) {
          Brightness.light => GesturaTheme.light(),
          Brightness.dark => GesturaTheme.dark(),
        };
        final chip = theme.chipTheme;
        final label = chip.labelStyle!;

        for (final states in [
          <WidgetState>{},
          {WidgetState.selected},
        ]) {
          expect(
            WcagContrast.ratio(
              WidgetStateProperty.resolveAs<Color?>(label.color, states)!,
              chip.color!.resolve(states)!,
            ),
            greaterThanOrEqualTo(WcagContrast.normalText),
            reason: '$states',
          );
        }
      });
    }
  });
}
