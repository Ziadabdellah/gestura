import 'dart:math' as math;

import 'package:meta/meta.dart';

enum ReviewGrade {
  again(1),
  hard(3),
  good(4),
  easy(5);

  new(this.quality);

  final int quality;
}

@immutable
final class CardState {
  const new({
    required this.repetitions,
    required this.intervalDays,
    required this.ease,
    required this.dueAt,
    this.lapses = 0,
  });

  factory initial(DateTime now) =>
      CardState(repetitions: 0, intervalDays: 0, ease: startEase, dueAt: now);

  static const double startEase = 2.5;
  static const double minEase = 1.3;

  final int repetitions;
  final int intervalDays;
  final double ease;
  final DateTime dueAt;
  final int lapses;

  bool isDue(DateTime now) => !dueAt.isAfter(now);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardState &&
          other.repetitions == repetitions &&
          other.intervalDays == intervalDays &&
          other.ease == ease &&
          other.dueAt == dueAt &&
          other.lapses == lapses;

  @override
  int get hashCode =>
      Object.hash(repetitions, intervalDays, ease, dueAt, lapses);

  @override
  String toString() =>
      'CardState(repetitions: $repetitions, interval: $intervalDays, '
      'ease: $ease, due: $dueAt, lapses: $lapses)';
}

CardState review(CardState state, ReviewGrade grade, DateTime now) {
  final quality = grade.quality;
  final passed = quality >= ReviewGrade.hard.quality;
  final (repetitions, interval) = passed
      ? (
          state.repetitions + 1,
          switch (state.repetitions) {
            0 => 1,
            1 => 6,
            _ => (state.intervalDays * state.ease).round(),
          },
        )
      : (0, 1);
  final miss = 5 - quality;
  final ease = math.max(
    CardState.minEase,
    state.ease + (0.1 - miss * (0.08 + miss * 0.02)),
  );
  return CardState(
    repetitions: repetitions,
    intervalDays: interval,
    ease: ease,
    dueAt: now.add(Duration(days: interval)),
    lapses: state.lapses + (passed ? 0 : 1),
  );
}
