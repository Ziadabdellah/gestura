import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/saved/domain/saved_signs_repository.dart';
import 'package:gestura/features/sign_detail/presentation/view_models/sign_detail_state.dart';
import 'package:gestura_core/gestura_core.dart';

class SignDetailViewModel extends Cubit<SignDetailState> {
  new(this._content, this._saved, {this._playback = const Playback()})
    : super(const SignDetailLoading());

  final ContentRepository _content;
  final SavedSignsRepository _saved;
  Playback _playback;

  Future<void> load(SignId id) async {
    if (state is! SignDetailLoading) emit(const SignDetailLoading());
    final (sign, categories, signs, saved) = await (
      _content.sign(id),
      _content.categories(),
      _content.searchSigns(''),
      _saved.isSaved(id),
    ).wait;
    if (isClosed) return;
    switch ((sign, categories, signs)) {
      case (
        Ok(value: final sign),
        Ok(value: final categories),
        Ok(value: final signs),
      ):
        emit(
          SignDetailLoaded(
            sign: sign,
            category: categories
                .where((category) => category.id == sign.category)
                .firstOrNull,
            related: [
              for (final other in signs)
                if (other.category == sign.category && other != sign) other,
            ],
            playback: _playback,
            saved: saved.valueOrNull ?? false,
          ),
        );
      case (Err(:final failure), _, _) ||
          (_, Err(:final failure), _) ||
          (_, _, Err(:final failure)):
        emit(SignDetailFailed(failure));
    }
  }

  Future<Result<void>> toggleSaved() async {
    if (state case final SignDetailLoaded loaded) {
      final saved = !loaded.saved;
      final result = await _saved.setSaved(loaded.sign.id, saved: saved);
      if (result case Ok() when !isClosed) {
        if (state case final SignDetailLoaded current) {
          emit(current.copyWith(saved: saved));
        }
      }
      return result;
    }
    return const Ok(null);
  }

  void setSpeed(PlaybackSpeed speed) =>
      _change(_playback.copyWith(speed: speed));

  void setLooping({required bool looping}) =>
      _change(_playback.copyWith(looping: looping));

  void setMirrored({required bool mirrored}) =>
      _change(_playback.copyWith(mirrored: mirrored));

  void _change(Playback playback) {
    _playback = playback;
    if (state case final SignDetailLoaded loaded) {
      emit(loaded.copyWith(playback: playback));
    }
  }
}
