import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../helpers/pump_gestura.dart';

void main() {
  group('GCardTone', () {
    test('maps every tone to a surface container', () {
      const s = GesturaColorSchemes.light;

      expect(GCardTone.lowest.resolve(s), s.surfaceContainerLowest);
      expect(GCardTone.low.resolve(s), s.surfaceContainerLow);
      expect(GCardTone.container.resolve(s), s.surfaceContainer);
      expect(GCardTone.high.resolve(s), s.surfaceContainerHigh);
    });
  });

  group('GCard', () {
    testWidgets('paints the card with its tone', (tester) async {
      await tester.pumpGestura(
        const GCard(tone: GCardTone.high, child: Text('Unit 2')),
      );

      final card = tester.widget<Card>(find.byType(Card));

      expect(card.color, GesturaColorSchemes.light.surfaceContainerHigh);
    });

    testWidgets('is a plain container when it has no tap action', (
      tester,
    ) async {
      await tester.pumpGestura(const GCard(child: Text('Unit 2')));

      expect(find.byType(InkWell), findsNothing);
      expect(
        tester.getSemantics(find.byType(GCard)),
        isNot(isSemantics(isButton: true)),
      );
    });

    testWidgets('acts as a labelled button when tappable', (tester) async {
      var taps = 0;
      await tester.pumpGestura(
        GCard(
          onTap: () => taps++,
          semanticLabel: 'Continue unit 2',
          child: const SizedBox(width: 200, height: 80),
        ),
      );

      await tester.tap(find.byType(GCard));

      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(GCard)),
        isSemantics(isButton: true, label: 'Continue unit 2'),
      );
    });

    testWidgets('meets the accessibility guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpGestura(
        GCard(
          onTap: () {},
          semanticLabel: 'Continue unit 2',
          child: const Text('Unit 2 · Family'),
        ),
      );

      await tester.expectAccessible();
      handle.dispose();
    });
  });
}
