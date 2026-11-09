import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

void main() {
  group('WindowSizeClass', () {
    test('uses the Material 3 breakpoints', () {
      expect(WindowSizeClass.fromWidth(0), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(599.9), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(839.9), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
      expect(WindowSizeClass.fromWidth(1600), WindowSizeClass.expanded);
    });

    test('pads phones with 16 and larger windows with 24', () {
      expect(WindowSizeClass.compact.screenPadding, 16);
      expect(WindowSizeClass.medium.screenPadding, 24);
      expect(WindowSizeClass.expanded.screenPadding, 24);
    });

    test('switches to a navigation rail from medium width', () {
      expect(WindowSizeClass.compact.usesNavigationRail, isFalse);
      expect(WindowSizeClass.medium.usesNavigationRail, isTrue);
      expect(WindowSizeClass.expanded.usesNavigationRail, isTrue);
    });

    testWidgets('reads the width from the context', (tester) async {
      late WindowSizeClass fromContext;
      late WindowSizeClass fromExtension;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 1000)),
          child: Builder(
            builder: (context) {
              fromContext = WindowSizeClass.of(context);
              fromExtension = context.windowSizeClass;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(fromContext, WindowSizeClass.medium);
      expect(fromExtension, WindowSizeClass.medium);
    });
  });

  group('GesturaMotion.adaptive', () {
    Future<Duration> resolve(
      WidgetTester tester, {
      required bool reduce,
    }) async {
      late Duration duration;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: Builder(
            builder: (context) {
              duration = GesturaMotion.adaptive(context, GesturaMotion.medium);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return duration;
    }

    testWidgets('keeps the duration when motion is allowed', (tester) async {
      expect(await resolve(tester, reduce: false), GesturaMotion.medium);
    });

    testWidgets('returns zero when reduce motion is on', (tester) async {
      expect(await resolve(tester, reduce: true), Duration.zero);
    });
  });

  test('spacing, radius and motion tokens match the blueprint', () {
    expect(
      [
        GesturaSpacing.xxs,
        GesturaSpacing.xs,
        GesturaSpacing.sm,
        GesturaSpacing.md,
        GesturaSpacing.lg,
        GesturaSpacing.xl,
        GesturaSpacing.xxl,
      ],
      [4, 8, 12, 16, 24, 32, 48],
    );
    expect(
      [GesturaRadius.sm, GesturaRadius.md, GesturaRadius.lg, GesturaRadius.xl],
      [8, 12, 20, 28],
    );
    expect(
      [GesturaMotion.short, GesturaMotion.medium, GesturaMotion.long],
      const [
        Duration(milliseconds: 120),
        Duration(milliseconds: 240),
        Duration(milliseconds: 400),
      ],
    );
    expect(GesturaMotion.enter, Curves.easeOutCubic);
    expect(GesturaMotion.exit, Curves.easeInCubic);
  });
}
