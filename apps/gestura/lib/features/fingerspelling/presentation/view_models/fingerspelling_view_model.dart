import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/fingerspelling/presentation/view_models/fingerspelling_state.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura_core/gestura_core.dart';

class FingerspellingViewModel extends Cubit<FingerspellingState> {
  new(this._content, {this._playback = const Playback()})
    : super(const FingerspellingLoading());

  final ContentRepository _content;
  Playback _playback;

  Future<void> load() async {
    if (state is! FingerspellingLoading) emit(const FingerspellingLoading());
    final letters = await _content.alphabet();
    if (isClosed) return;
    emit(switch (letters) {
      Ok(value: []) => const FingerspellingEmpty(),
      Ok(value: final letters) => FingerspellingReady(
        letters: letters,
        selected: letters.first,
        playback: _playback,
      ),
      Err(:final failure) => FingerspellingFailed(failure),
    });
  }

  void select(Sign letter) {
    if (state case final FingerspellingReady ready) {
      emit(ready.copyWith(selected: letter));
    }
  }

  void spell(String text) {
    if (state case final FingerspellingReady ready) {
      final byLetter = {
        for (final letter in ready.letters) letter.gloss.toUpperCase(): letter,
      };
      final word = [
        for (final character in text.toUpperCase().split(''))
          ?byLetter[character],
      ];
      emit(
        ready.copyWith(
          word: word,
          selected: word.isEmpty ? ready.selected : word.first,
        ),
      );
    }
  }

  void setSpeed(PlaybackSpeed speed) =>
      _change(_playback.copyWith(speed: speed));

  void setLooping({required bool looping}) =>
      _change(_playback.copyWith(looping: looping));

  void setMirrored({required bool mirrored}) =>
      _change(_playback.copyWith(mirrored: mirrored));

  void _change(Playback playback) {
    _playback = playback;
    if (state case final FingerspellingReady ready) {
      emit(ready.copyWith(playback: playback));
    }
  }
}
