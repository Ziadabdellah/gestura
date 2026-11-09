import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../helpers/pump_gestura.dart';

void main() {
  group('GSkeleton', () {
    testWidgets('uses the given box size', (tester) async {
      await tester.pumpGestura(
        const GSkeleton(width: 120),
        disableAnimations: true,
      );

      expect(tester.getSize(find.byType(GSkeleton)), const Size(120, 16));
    });

    testWidgets('accepts sizes computed at runtime', (tester) async {
      final sizes = [96.0, 24.0];
      await tester.pumpGestura(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GSkeleton.circle(size: sizes.last),
            GSkeleton(width: sizes.first, height: sizes.last),
          ],
        ),
        disableAnimations: true,
      );

      final boxes = tester.getSize(find.byType(GSkeleton).last);

      expect(tester.getSize(find.byType(GSkeleton).first), const Size(24, 24));
      expect(boxes, const Size(96, 24));
    });

    testWidgets('draws a circle with equal sides', (tester) async {
      await tester.pumpGestura(
        const GSkeleton.circle(size: 40),
        disableAnimations: true,
      );

      final box = tester.widget<Container>(
        find.descendant(
          of: find.byType(GSkeleton),
          matching: find.byType(Container),
        ),
      );
      final decoration = box.decoration! as BoxDecoration;

      expect(tester.getSize(find.byType(GSkeleton)), const Size(40, 40));
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('pulses while motion is allowed', (tester) async {
      await tester.pumpGestura(const GSkeleton(width: 120));
      await tester.pump(GSkeleton.pulseDuration ~/ 2);

      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('stays still when reduce motion is on', (tester) async {
      await tester.pumpGestura(
        const GSkeleton(width: 120),
        disableAnimations: true,
      );
      await tester.pump(GSkeleton.pulseDuration);

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('stops pulsing when reduce motion turns on', (tester) async {
      await tester.pumpGestura(const GSkeleton(width: 120));
      await tester.pumpGestura(
        const GSkeleton(width: 120),
        disableAnimations: true,
      );
      await tester.pump(GSkeleton.pulseDuration);

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('is hidden from assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpGestura(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [GSkeleton(width: 120), GSkeleton.circle(size: 40)],
        ),
        disableAnimations: true,
      );

      expect(
        find.descendant(
          of: find.byType(GSkeleton).first,
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
