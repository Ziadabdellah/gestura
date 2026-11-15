import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/saved/domain/saved_signs_repository.dart';
import 'package:gestura/features/saved/presentation/view_models/saved_signs_state.dart';
import 'package:gestura_core/gestura_core.dart';

class SavedSignsViewModel extends Cubit<SavedSignsState> {
  new(this._content, this._saved) : super(const SavedSignsLoading());

  final ContentRepository _content;
  final SavedSignsRepository _saved;
  StreamSubscription<Result<List<SignId>>>? _subscription;
  int _generation = 0;

  void start() {
    unawaited(_subscription?.cancel());
    if (state is! SavedSignsLoading) emit(const SavedSignsLoading());
    _subscription = _saved.watchSaved().listen(
      (result) => unawaited(_show(result)),
    );
  }

  Future<void> _show(Result<List<SignId>> saved) async {
    final generation = ++_generation;
    if (saved case Err(:final failure)) {
      emit(SavedSignsFailed(failure));
      return;
    }
    final ids = saved.valueOrNull!;
    final signs = await _content.searchSigns('');
    if (isClosed || generation != _generation) return;
    switch (signs) {
      case Ok(:final value):
        final byId = {for (final sign in value) sign.id: sign};
        emit(SavedSignsLoaded([for (final id in ids) ?byId[id]]));
      case Err(:final failure):
        emit(SavedSignsFailed(failure));
    }
  }

  @override
  Future<void> close() {
    unawaited(_subscription?.cancel());
    return super.close();
  }
}
