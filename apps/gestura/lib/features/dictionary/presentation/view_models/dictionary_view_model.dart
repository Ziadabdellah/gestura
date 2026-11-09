import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/dictionary/presentation/view_models/dictionary_state.dart';
import 'package:gestura_core/gestura_core.dart';

class DictionaryViewModel extends Cubit<DictionaryState> {
  new(this._content) : super(const DictionaryLoading());

  final ContentRepository _content;

  Future<void> load() async {
    if (state is! DictionaryLoading) emit(const DictionaryLoading());
    final result = await _content.searchSigns('');
    if (isClosed) return;
    emit(switch (result) {
      Ok(value: final signs) => DictionaryLoaded(signs),
      Err(:final failure) => DictionaryFailed(failure),
    });
  }
}
