import 'package:equatable/equatable.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura_core/gestura_core.dart';

sealed class ReviewState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class ReviewLoading extends ReviewState {
  const new();
}

final class ReviewFailed extends ReviewState {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class ReviewNothingDue extends ReviewState {
  const new();
}

final class ReviewInProgress extends ReviewState {
  const new({
    required this.cards,
    required this.signs,
    required this.now,
    this.index = 0,
    this.revealed = false,
    this.remembered = 0,
    this.playback = const Playback(),
  });

  final List<ReviewCard> cards;
  final Map<SignId, Sign> signs;
  final DateTime now;
  final int index;
  final bool revealed;
  final int remembered;
  final Playback playback;

  ReviewCard get card => cards[index];

  Sign get sign => signs[card.signId]!;

  int daysAfter(ReviewGrade grade) =>
      review(card.state, grade, now).intervalDays;

  ReviewInProgress copyWith({
    int? index,
    bool? revealed,
    int? remembered,
    Playback? playback,
  }) => ReviewInProgress(
    cards: cards,
    signs: signs,
    now: now,
    index: index ?? this.index,
    revealed: revealed ?? this.revealed,
    remembered: remembered ?? this.remembered,
    playback: playback ?? this.playback,
  );

  @override
  List<Object?> get props => [
    cards,
    signs,
    now,
    index,
    revealed,
    remembered,
    playback,
  ];
}

final class ReviewFinished extends ReviewState {
  const new({required this.reviewed, required this.remembered});

  final int reviewed;
  final int remembered;

  @override
  List<Object?> get props => [reviewed, remembered];
}
