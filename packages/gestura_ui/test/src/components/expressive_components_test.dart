import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../helpers/pump_gestura.dart';

void main() {
  group('GProgressRing', () {
    testWidgets('announces its rounded and clamped value', (tester) async {
      await tester.pumpGestura(
        const GProgressRing(
          value: 1.4,
          semanticLabel: 'Daily goal',
          child: Text('7'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(GProgressRing)),
        isSemantics(label: 'Daily goal', value: '100%'),
      );
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('paints an empty ring and repaints on change', (tester) async {
      await tester.pumpGestura(
        const GProgressRing(value: 0, semanticLabel: 'Goal'),
        disableAnimations: true,
      );
      await tester.pumpGestura(
        const GProgressRing(value: 0.5, semanticLabel: 'Goal'),
        brightness: Brightness.dark,
        disableAnimations: true,
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(GProgressRing)),
        isSemantics(value: '50%'),
      );
    });
  });

  testWidgets('GStatTile reads as one item and is accessible', (tester) async {
    await tester.pumpGestura(
      const GStatTile(
        icon: Icons.local_fire_department_rounded,
        value: '12',
        label: 'Day streak',
      ),
    );

    expect(
      tester.getSemantics(find.byType(GStatTile)),
      isSemantics(label: '12\nDay streak'),
    );
    await tester.expectAccessible();
  });

  testWidgets('repaints the ring when only the theme changes', (tester) async {
    final label = String.fromCharCodes('Goal'.codeUnits);
    final ring = GProgressRing(value: 0.25, semanticLabel: label);
    await tester.pumpGestura(ring, disableAnimations: true);
    await tester.pumpGestura(
      ring,
      brightness: Brightness.dark,
      disableAnimations: true,
    );
    await tester.pumpGestura(
      GProgressRing(value: 0.25, semanticLabel: label, strokeWidth: 4),
      brightness: Brightness.dark,
      disableAnimations: true,
    );

    expect(find.byType(CustomPaint), findsWidgets);
    expect(
      GStatTile(icon: Icons.star, value: label, label: label),
      isA<StatelessWidget>(),
    );
    expect(GAvatar(name: label), isA<StatelessWidget>());
  });

  group('GAvatar', () {
    test('takes up to two initials', () {
      expect(GAvatar.initialsOf('ziad abdellah amr'), 'ZA');
      expect(GAvatar.initialsOf('  sara '), 'S');
      expect(GAvatar.initialsOf(' '), '?');
    });

    testWidgets('is an image labelled with the name', (tester) async {
      await tester.pumpGestura(const GAvatar(name: 'Mona Ali'));

      expect(find.text('MA'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(GAvatar)),
        isSemantics(label: 'Mona Ali', isImage: true),
      );
    });
  });

  testWidgets('GEmptyState shows its action', (tester) async {
    var taps = 0;
    await tester.pumpGestura(
      GEmptyState(
        icon: Icons.forum_outlined,
        title: 'No posts yet',
        message: 'Be the first to share.',
        action: FilledButton(
          onPressed: () => taps++,
          child: const Text('Post'),
        ),
      ),
    );
    await tester.tap(find.text('Post'));

    expect(taps, 1);
    expect(find.text('No posts yet'), findsOneWidget);
    await tester.expectAccessible();
  });

  testWidgets('GEmptyState works without an action', (tester) async {
    await tester.pumpGestura(
      const GEmptyState(icon: Icons.inbox, title: 'Empty', message: 'Nothing'),
    );

    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('GSectionHeader is a header with a trailing widget', (
    tester,
  ) async {
    await tester.pumpGestura(
      GSectionHeader(
        title: 'Your courses',
        trailing: TextButton(onPressed: () {}, child: const Text('All')),
      ),
    );

    expect(
      tester.getSemantics(find.text('Your courses')),
      isSemantics(label: 'Your courses', isHeader: true),
    );
    expect(find.text('All'), findsOneWidget);
  });

  group('GHeroCard', () {
    testWidgets('is a button when tappable', (tester) async {
      var taps = 0;
      await tester.pumpGestura(
        GHeroCard(
          title: 'Keep going',
          subtitle: 'Unit 2 · Greetings',
          leading: const Icon(Icons.waving_hand_rounded),
          trailing: const Icon(Icons.arrow_forward_rounded),
          onTap: () => taps++,
        ),
      );
      await tester.tap(find.text('Keep going'));

      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(GHeroCard)),
        isSemantics(isButton: true, hasTapAction: true),
      );
    });

    testWidgets('is plain without a tap action', (tester) async {
      await tester.pumpGestura(
        const GHeroCard(title: 'Welcome', subtitle: 'Start here'),
      );

      expect(
        tester.getSemantics(find.byType(GHeroCard)),
        isNot(isSemantics(isButton: true)),
      );
    });
  });
}
