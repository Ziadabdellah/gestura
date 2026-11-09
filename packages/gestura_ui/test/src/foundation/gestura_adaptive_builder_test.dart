import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

void main() {
  group('GesturaAdaptiveBuilder', () {
    late List<GesturaScale> scales;

    Widget subject() => GesturaAdaptiveBuilder(
      builder: (context, scale) {
        scales.add(scale);
        return const SizedBox.shrink();
      },
    );

    setUp(() => scales = []);

    void useScreen(WidgetTester tester, Size size) {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    testWidgets('reads the screen size from the view', (tester) async {
      useScreen(tester, const Size(412, 915));

      await tester.pumpWidget(subject());

      expect(scales.last, GesturaScale.fromSize(const Size(412, 915)));
    });

    testWidgets('uses the MediaQuery above it when there is one', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(320, 640)),
          child: subject(),
        ),
      );

      expect(scales.last, const GesturaScale(size: 0.9));
    });

    testWidgets('rebuilds with a new scale when the screen changes', (
      tester,
    ) async {
      useScreen(tester, const Size(360, 780));
      await tester.pumpWidget(subject());

      useScreen(tester, const Size(800, 1280));
      await tester.pump();

      expect(scales.first, GesturaScale.identity);
      expect(scales.last, GesturaScale.identity);

      useScreen(tester, const Size(430, 932));
      await tester.pump();

      expect(scales.last, GesturaScale.fromSize(const Size(430, 932)));
    });

    testWidgets('does not rebuild when only the keyboard insets change', (
      tester,
    ) async {
      useScreen(tester, const Size(412, 915));
      await tester.pumpWidget(subject());
      final builds = scales.length;

      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

      expect(scales, hasLength(builds));
    });

    testWidgets('lets an app build its themes from the scale', (tester) async {
      useScreen(tester, const Size(412, 915));

      await tester.pumpWidget(
        GesturaAdaptiveBuilder(
          builder: (context, scale) => MaterialApp(
            theme: GesturaTheme.light(scale: scale),
            home: Builder(
              builder: (context) =>
                  Text('Hello', style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ),
      );

      final style = tester.widget<Text>(find.text('Hello')).style!;

      expect(style.fontSize, closeTo(16 * 1.12, 0.001));
    });
  });
}
