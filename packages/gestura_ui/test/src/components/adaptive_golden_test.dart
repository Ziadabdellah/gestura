import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../helpers/gestura_test_scope.dart';
import '../../helpers/sample_text.dart';

const List<double> _phoneWidths = [320, 360, 412, 430];
const List<Locale> _locales = [Locale('en'), Locale('ar')];

void main() {
  unawaited(
    goldenTest(
      'The same screen on four phone widths',
      fileName: 'adaptive_phones',
      pumpBeforeTest: (tester) => tester.pump(GesturaMotion.long),
      builder: () => GoldenTestGroup(
        columns: _phoneWidths.length,
        children: [
          for (final locale in _locales)
            for (final width in _phoneWidths)
              GoldenTestScenario(
                name: '${locale.languageCode} ${width.toInt()}',
                child: GesturaTestScope(
                  locale: locale,
                  width: width - GesturaSpacing.md * 2,
                  scale: GesturaScale.fromSize(Size(width, 800)),
                  child: _SampleScreen(text: sampleTextFor(locale)),
                ),
              ),
        ],
      ),
    ),
  );
}

class _SampleScreen extends StatelessWidget {
  const new({required this.text});

  final SampleText text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text.cardTitle, style: theme.textTheme.headlineSmall),
        SizedBox(height: sizes.xs),
        Text(text.tagline, style: theme.textTheme.bodyLarge),
        SizedBox(height: sizes.md),
        GCard(
          onTap: () {},
          child: Row(
            children: [
              Icon(Icons.play_circle_rounded, color: theme.colorScheme.primary),
              SizedBox(width: sizes.sm),
              Expanded(
                child: Text(
                  text.cardSubtitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: sizes.md),
        Wrap(
          spacing: sizes.xs,
          runSpacing: sizes.xs,
          children: [
            GChip(label: text.chips[0], selected: true, onSelected: (_) {}),
            GChip(label: text.chips[1], onSelected: (_) {}),
          ],
        ),
        SizedBox(height: sizes.md),
        GButton(
          label: text.primary,
          onPressed: () {},
          icon: Icons.play_arrow_rounded,
          expand: true,
        ),
      ],
    );
  }
}
