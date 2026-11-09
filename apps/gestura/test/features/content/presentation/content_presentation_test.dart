import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/content/domain/localized_text.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/l10n/l10n.dart';

void main() {
  testWidgets('picks the text for the current locale', (tester) async {
    const text = LocalizedText({'en': 'Family', 'ar': 'العائلة'});
    late String resolved;

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('ar'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(
          builder: (context) {
            resolved = text.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(resolved, 'العائلة');
  });

  test('writes levels the way the CEFR does', () {
    expect(CefrLevel.values.map((level) => level.label), ['A1', 'A2']);
  });
}
