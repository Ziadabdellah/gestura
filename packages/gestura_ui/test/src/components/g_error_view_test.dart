import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../helpers/pump_gestura.dart';

void main() {
  group('GErrorView', () {
    testWidgets('shows the title and the message', (tester) async {
      await tester.pumpGestura(
        const GErrorView(
          title: 'Something went wrong',
          message: 'Check your connection and try again.',
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Check your connection and try again.'), findsOneWidget);
      expect(find.byType(GButton), findsNothing);
    });

    testWidgets('offers a retry button that calls the action', (tester) async {
      var retries = 0;
      await tester.pumpGestura(
        GErrorView(
          title: 'Something went wrong',
          message: 'Check your connection and try again.',
          action: (label: 'Try again', onPressed: () => retries++),
        ),
      );

      await tester.tap(find.text('Try again'));

      expect(retries, 1);
    });

    testWidgets('announces the error as a live region', (tester) async {
      await tester.pumpGestura(
        const GErrorView(title: 'Offline', message: 'No connection.'),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && (widget.properties.liveRegion ?? false),
        ),
        findsOneWidget,
      );
    });

    testWidgets('scrolls instead of overflowing at 200% text', (tester) async {
      await tester.pumpGestura(
        GErrorView(
          title: 'Something went wrong while loading this lesson',
          message:
              'Check your connection and try again. Your progress is saved '
              'on this device and will sync later.',
          action: (label: 'Try again', onPressed: () {}),
        ),
        textScale: 2,
        surfaceSize: const Size(320, 400),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('lays out inside an unbounded column', (tester) async {
      await tester.pumpGestura(
        const SingleChildScrollView(
          child: GErrorView(title: 'Offline', message: 'No connection.'),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('supports parents that measure intrinsic size', (tester) async {
      await tester.pumpGestura(
        IntrinsicHeight(
          child: GErrorView(
            title: 'Offline',
            message: 'No connection.',
            action: (label: 'Try again', onPressed: () {}),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Try again'), findsOneWidget);
    });

    for (final brightness in Brightness.values) {
      testWidgets('meets the accessibility guidelines in ${brightness.name}', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpGestura(
          GErrorView(
            title: 'Something went wrong',
            message: 'Check your connection and try again.',
            action: (label: 'Try again', onPressed: () {}),
          ),
          brightness: brightness,
        );

        await tester.expectAccessible();
        handle.dispose();
      });
    }
  });
}
