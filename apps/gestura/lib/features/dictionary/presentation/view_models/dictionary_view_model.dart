import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/dictionary/presentation/view_models/dictionary_state.dart';
import 'package:gestura_core/gestura_core.dart';

class DictionaryViewModel extends Cubit<DictionaryState> {
  new(this._content, {this.debounce = searchDebounce})
    : super(const DictionaryLoading());

  static const Duration searchDebounce = Duration(milliseconds: 250);

  final ContentRepository _content;
  final Duration debounce;
  Timer? _pending;
  String _query = '';
  CategoryId? _category;
  List<SignCategory> _categories = const [];
  int _request = 0;

  Future<void> load() async {
    if (state is! DictionaryLoading) emit(const DictionaryLoading());
    final request = ++_request;
    final (categories, results) = await (
      _content.categories(),
      _content.searchSigns(_query),
    ).wait;
    if (isClosed || request != _request) return;
    switch ((categories, results)) {
      case (Ok(value: final categories), Ok(value: final signs)):
        _categories = categories;
        emit(_loaded(signs));
      case (Err(:final failure), _) || (_, Err(:final failure)):
        emit(DictionaryFailed(failure));
    }
  }

  void search(String query) {
    if (query == _query) return;
    _query = query;
    _pending?.cancel();
    _pending = Timer(debounce, () => unawaited(_refresh()));
  }

  Future<void> clearSearch() {
    _pending?.cancel();
    _query = '';
    return _refresh();
  }

  Future<void> selectCategory(CategoryId? category) {
    if (category == _category) return Future.value();
    _category = category;
    return _refresh();
  }

  Future<void> _refresh() async {
    if (state is! DictionaryLoaded) {
      await load();
      return;
    }
    final request = ++_request;
    final result = await _content.searchSigns(_query);
    if (isClosed || request != _request) return;
    emit(switch (result) {
      Ok(value: final signs) => _loaded(signs),
      Err(:final failure) => DictionaryFailed(failure),
    });
  }

  DictionaryLoaded _loaded(List<Sign> signs) => DictionaryLoaded(
    categories: _categories,
    results: [
      for (final sign in signs)
        if (_category == null || sign.category == _category) sign,
    ],
    query: _query,
    category: _category,
  );

  @override
  Future<void> close() {
    _pending?.cancel();
    return super.close();
  }
}
