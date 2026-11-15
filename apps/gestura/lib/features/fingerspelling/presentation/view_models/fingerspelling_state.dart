import 'package:equatable/equatable.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura_core/gestura_core.dart';

sealed class FingerspellingState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class FingerspellingLoading extends FingerspellingState {
  const new();
}

final class FingerspellingFailed extends FingerspellingState {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class FingerspellingEmpty extends FingerspellingState {
  const new();
}

final class FingerspellingReady extends FingerspellingState {
  const new({
    required this.letters,
    required this.selected,
    required this.playback,
    this.word = const [],
  });

  final List<Sign> letters;
  final Sign selected;
  final List<Sign> word;
  final Playback playback;

  FingerspellingReady copyWith({
    Sign? selected,
    List<Sign>? word,
    Playback? playback,
  }) => FingerspellingReady(
    letters: letters,
    selected: selected ?? this.selected,
    word: word ?? this.word,
    playback: playback ?? this.playback,
  );

  @override
  List<Object?> get props => [letters, selected, word, playback];
}
