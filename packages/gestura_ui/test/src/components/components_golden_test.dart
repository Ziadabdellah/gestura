import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../helpers/gestura_test_scope.dart';
import '../../helpers/sample_text.dart';

GoldenTestGroup _matrix(Widget Function(SampleText text) build) =>
    GoldenTestGroup(
      columns: 2,
      children: [
        for (final variant in ltrRtlLightDark)
          GoldenTestScenario(
            name: variant.name,
            child: GesturaTestScope(
              locale: variant.locale,
              brightness: variant.brightness,
              child: build(sampleTextFor(variant.locale)),
            ),
          ),
      ],
    );

const _gap = SizedBox(height: GesturaSpacing.sm);

void main() {
  unawaited(
    goldenTest(
      'GButton variants and states',
      fileName: 'g_button',
      pumpBeforeTest: (tester) => tester.pump(GesturaMotion.long),
      builder: () => _matrix(
        (text) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GButton(label: text.primary, onPressed: () {}),
            _gap,
            GButton(
              label: text.primary,
              onPressed: () {},
              icon: Icons.play_arrow_rounded,
            ),
            _gap,
            GButton.secondary(label: text.secondary, onPressed: () {}),
            _gap,
            GButton.text(label: text.text, onPressed: () {}),
            _gap,
            GButton.destructive(
              label: text.destructive,
              onPressed: () {},
              icon: Icons.delete_outline_rounded,
            ),
            _gap,
            GButton(label: text.primary, onPressed: () {}, isLoading: true),
            _gap,
            GButton(label: text.primary, onPressed: null),
          ],
        ),
      ),
    ),
  );

  unawaited(
    goldenTest(
      'GCard tones',
      fileName: 'g_card',
      builder: () => _matrix(
        (text) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final tone in GCardTone.values) ...[
              GCard(
                tone: tone,
                onTap: () {},
                child: _CardBody(
                  title: text.cardTitle,
                  subtitle: text.cardSubtitle,
                ),
              ),
              _gap,
            ],
          ],
        ),
      ),
    ),
  );

  unawaited(
    goldenTest(
      'GChip states',
      fileName: 'g_chip',
      builder: () => _matrix(
        (text) => Wrap(
          spacing: GesturaSpacing.xs,
          runSpacing: GesturaSpacing.xs,
          children: [
            GChip(label: text.chips[0], selected: true, onSelected: (_) {}),
            GChip(
              label: text.chips[1],
              icon: Icons.restaurant_rounded,
              onSelected: (_) {},
            ),
            GChip(label: text.chips[2], onSelected: (_) {}),
            GChip(label: text.chips[2], onSelected: null),
          ],
        ),
      ),
    ),
  );

  unawaited(
    goldenTest(
      'GSkeleton shapes',
      fileName: 'g_skeleton',
      builder: () => _matrix(
        (_) => const Row(
          children: [
            GSkeleton.circle(size: 48),
            SizedBox(width: GesturaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GSkeleton(width: 180),
                  SizedBox(height: GesturaSpacing.xs),
                  GSkeleton(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  unawaited(
    goldenTest(
      'GErrorView with and without retry',
      fileName: 'g_error_view',
      builder: () => _matrix(
        (text) => Column(
          children: [
            GErrorView(
              title: text.errorTitle,
              message: text.errorMessage,
              action: (label: text.retry, onPressed: () {}),
            ),
            GErrorView(
              title: text.errorTitle,
              message: text.errorMessage,
              icon: Icons.search_off_rounded,
            ),
          ],
        ),
      ),
    ),
  );
}

class _CardBody extends StatelessWidget {
  const new({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: GesturaSpacing.xxs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
