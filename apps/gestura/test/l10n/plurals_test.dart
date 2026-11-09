import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/l10n/l10n.dart';

AppLocalizations _l10n(String language) =>
    lookupAppLocalizations(Locale(language));

void main() {
  test('Arabic uses all six plural forms', () {
    final ar = _l10n('ar');

    expect(
      {
        for (final n in [0, 1, 2, 3, 10, 11, 99, 100]) n: ar.streakDays(n),
      },
      {
        0: 'لا توجد سلسلة بعد',
        1: 'سلسلة يوم واحد',
        2: 'سلسلة يومين',
        3: 'سلسلة 3 أيام',
        10: 'سلسلة 10 أيام',
        11: 'سلسلة 11 يومًا',
        99: 'سلسلة 99 يومًا',
        100: 'سلسلة 100 يوم',
      },
    );
    expect(ar.signsToReview(2), 'إشارتان للمراجعة');
    expect(ar.signsToReview(5), '5 إشارات للمراجعة');
    expect(ar.signsToReview(20), '20 إشارة للمراجعة');
  });

  test('Russian uses one, few and many by the last digits', () {
    final ru = _l10n('ru');

    expect(
      {
        for (final n in [1, 2, 5, 11, 21, 22, 25]) n: ru.streakDays(n),
      },
      {
        1: 'Серия 1 день',
        2: 'Серия 2 дня',
        5: 'Серия 5 дней',
        11: 'Серия 11 дней',
        21: 'Серия 21 день',
        22: 'Серия 22 дня',
        25: 'Серия 25 дней',
      },
    );
    expect(ru.signsToReview(0), 'Нечего повторять');
    expect(ru.signsToReview(3), '3 жеста для повторения');
  });

  test('English, Spanish, French and German use one and other', () {
    expect(_l10n('en').streakDays(1), '1-day streak');
    expect(_l10n('en').streakDays(7), '7-day streak');
    expect(_l10n('es').streakDays(1), 'Racha de 1 día');
    expect(_l10n('es').streakDays(4), 'Racha de 4 días');
    expect(_l10n('fr').streakDays(1), 'Série de 1 jour');
    expect(_l10n('fr').streakDays(2), 'Série de 2 jours');
    expect(_l10n('de').streakDays(1), '1 Tag in Folge');
    expect(_l10n('de').streakDays(3), '3 Tage in Folge');
  });

  test('every language has its own message for zero', () {
    for (final language in ['en', 'ar', 'ru', 'es', 'fr', 'de']) {
      final l10n = _l10n(language);

      expect(l10n.streakDays(0), isNot(contains('0')), reason: language);
      expect(l10n.signsToReview(0), isNot(contains('0')), reason: language);
    }
  });
}
