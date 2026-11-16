import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/admin/data/content_store.dart';
import 'package:gestura/features/admin/domain/content_doc.dart';
import 'package:gestura/features/admin/domain/content_kind.dart';

sealed class CollectionState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class CollectionLoading extends CollectionState {
  const new();
}

final class CollectionFailed extends CollectionState {
  const new();
}

final class CollectionReady extends CollectionState {
  const new({required this.all, this.query = ''});

  final List<ContentDoc> all;
  final String query;

  List<ContentDoc> visible(ContentKind kind) {
    final needle = query.trim().toLowerCase();
    final sorted = [...all]..sort((a, b) => a.id.compareTo(b.id));
    if (needle.isEmpty) return sorted;
    return [
      for (final doc in sorted)
        if (doc.id.toLowerCase().contains(needle) ||
            kind.titleOf(doc.data).toLowerCase().contains(needle))
          doc,
    ];
  }

  @override
  List<Object?> get props => [all, query];
}

class CollectionCubit extends Cubit<CollectionState> {
  new(this._store, this.kind) : super(const CollectionLoading());

  final ContentStore _store;
  final ContentKind kind;
  StreamSubscription<List<ContentDoc>>? _subscription;

  void load() {
    unawaited(_subscription?.cancel());
    emit(const CollectionLoading());
    _subscription = _store
        .watch(kind)
        .listen(
          (docs) => emit(
            CollectionReady(
              all: docs,
              query: switch (state) {
                CollectionReady(:final query) => query,
                _ => '',
              },
            ),
          ),
          onError: (Object _) => emit(const CollectionFailed()),
        );
  }

  void search(String query) {
    if (state case final CollectionReady ready) {
      emit(CollectionReady(all: ready.all, query: query));
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _store.delete(kind, id);
      return true;
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
