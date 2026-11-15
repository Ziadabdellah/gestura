import 'package:gestura_core/gestura_core.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026);

  test('a new card is due right away with the starting ease', () {
    final card = CardState.initial(now);

    expect(card.isDue(now), isTrue);
    expect(card.ease, 2.5);
    expect(card.repetitions, 0);
  });

  test('the first good review is due tomorrow, the second in six days', () {
    final first = review(CardState.initial(now), ReviewGrade.good, now);
    final second = review(first, ReviewGrade.good, now);

    expect(first.intervalDays, 1);
    expect(first.dueAt, DateTime.utc(2026, 1, 2));
    expect(first.isDue(now), isFalse);
    expect(second.intervalDays, 6);
  });

  test('later intervals grow with the ease', () {
    var card = CardState.initial(now);
    for (var i = 0; i < 3; i++) {
      card = review(card, ReviewGrade.good, now);
    }

    expect(card.intervalDays, 15);
  });

  test('easy raises the ease and hard lowers it but still passes', () {
    final easy = review(CardState.initial(now), ReviewGrade.easy, now);
    final hard = review(CardState.initial(now), ReviewGrade.hard, now);

    expect(easy.ease, closeTo(2.6, 1e-9));
    expect(hard.ease, closeTo(2.36, 1e-9));
    expect(hard.repetitions, 1);
  });

  test('again starts over, counts a lapse and never drops below 1.3', () {
    var card = review(CardState.initial(now), ReviewGrade.good, now);
    for (var i = 0; i < 10; i++) {
      card = review(card, ReviewGrade.again, now);
    }

    expect(card.repetitions, 0);
    expect(card.intervalDays, 1);
    expect(card.ease, 1.3);
    expect(card.lapses, 10);
  });

  test('cards compare by value', () {
    final card = review(CardState.initial(now), ReviewGrade.good, now);

    expect(card, review(CardState.initial(now), ReviewGrade.good, now));
    expect(
      card.hashCode,
      review(CardState.initial(now), ReviewGrade.good, now).hashCode,
    );
    expect(card, isNot(CardState.initial(now)));
    expect(card.toString(), contains('interval: 1'));
  });
}
