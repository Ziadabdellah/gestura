import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../helpers/pump_gestura.dart';

const _smallPhone = Size(320, 640);
const _largePhone = Size(430, 932);
const _tablet = Size(800, 1280);

Widget _sampleScreen() => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    GCard(
      onTap: () {},
      semanticLabel: 'Continue unit 2',
      child: const Text('Unit 2 · Family'),
    ),
    Wrap(
      spacing: 8,
      children: [
        GChip(label: 'Family', selected: true, onSelected: (_) {}),
        GChip(label: 'Food', onSelected: (_) {}),
      ],
    ),
    GButton(
      label: 'Continue',
      onPressed: () {},
      icon: Icons.play_arrow_rounded,
      expand: true,
    ),
    GButton.text(label: 'Skip for now', onPressed: () {}),
  ],
);

void main() {
  for (final (name, screen) in [
    ('small phone', _smallPhone),
    ('large phone', _largePhone),
    ('tablet', _tablet),
  ]) {
    testWidgets('meets the accessibility guidelines on a $name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpGestura(_sampleScreen(), surfaceSize: screen);

      expect(tester.takeException(), isNull);
      await tester.expectAccessible();
      handle.dispose();
    });

    testWidgets('fits at 200% text on a $name', (tester) async {
      await tester.pumpGestura(
        SingleChildScrollView(child: _sampleScreen()),
        surfaceSize: screen,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('grows text and icons on a large phone', (tester) async {
    await tester.pumpGestura(_sampleScreen(), surfaceSize: _largePhone);

    final scale = GesturaScale.fromSize(_largePhone);
    final icon = tester.getSize(find.byIcon(Icons.play_arrow_rounded));
    final label = tester
        .renderObject<RenderParagraph>(find.text('Continue'))
        .text
        .style!;

    expect(icon.width, closeTo(GButton.iconSize * scale.text, 0.01));
    expect(label.fontSize, closeTo(14 * scale.text, 0.01));
  });

  testWidgets('keeps the button at 48 or more on a small phone', (
    tester,
  ) async {
    await tester.pumpGestura(_sampleScreen(), surfaceSize: _smallPhone);

    final button = tester.getSize(find.byType(FilledButton));

    expect(button.height, greaterThanOrEqualTo(48));
  });

  testWidgets('tightens card padding on a small phone', (tester) async {
    const content = Key('content');
    await tester.pumpGestura(
      const GCard(child: SizedBox(key: content, width: 100, height: 20)),
      surfaceSize: _smallPhone,
    );

    final padding = tester.widget<Padding>(
      find
          .ancestor(of: find.byKey(content), matching: find.byType(Padding))
          .first,
    );

    expect(
      padding.padding,
      const EdgeInsetsDirectional.all(GesturaSpacing.md * 0.9),
    );
  });

  testWidgets('scales the default skeleton height', (tester) async {
    await tester.pumpGestura(
      const GSkeleton(width: 100),
      surfaceSize: _largePhone,
      disableAnimations: true,
    );

    final scale = GesturaScale.fromSize(_largePhone);

    expect(
      tester.getSize(find.byType(GSkeleton)).height,
      closeTo(GSkeleton.defaultHeight * scale.size, 0.01),
    );
  });

  testWidgets('keeps design sizes on a tablet', (tester) async {
    await tester.pumpGestura(_sampleScreen(), surfaceSize: _tablet);

    final label = tester
        .renderObject<RenderParagraph>(find.text('Continue'))
        .text
        .style!;

    expect(label.fontSize, 14);
  });
}
