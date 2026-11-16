import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/admin/data/content_store.dart';
import 'package:gestura/features/admin/domain/content_codec.dart';
import 'package:gestura/features/admin/domain/content_doc.dart';
import 'package:gestura/features/admin/domain/content_kind.dart';

enum IdError { format, taken }

enum EditorStatus { editing, saving, saved, failed }

final class EditorState extends Equatable {
  const new({
    required this.id,
    required this.values,
    this.errors = const {},
    this.idError,
    this.status = EditorStatus.editing,
  });

  final String id;
  final Map<String, Object?> values;
  final Map<FieldName, FieldError> errors;
  final IdError? idError;
  final EditorStatus status;

  EditorState copyWith({
    String? id,
    Map<String, Object?>? values,
    Map<FieldName, FieldError>? errors,
    IdError? Function()? idError,
    EditorStatus? status,
  }) => EditorState(
    id: id ?? this.id,
    values: values ?? this.values,
    errors: errors ?? this.errors,
    idError: idError == null ? this.idError : idError(),
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [id, values, errors, idError, status];
}

Object? parseJsonList(String text) {
  try {
    return jsonDecode(text);
  } on FormatException {
    return null;
  }
}

class EditorCubit extends Cubit<EditorState> {
  new(this._store, this.kind, {ContentDoc? existing})
    : isNew = existing == null,
      super(
        EditorState(
          id: existing?.id ?? '',
          values: formValuesOf(kind, existing?.data ?? const {}),
        ),
      );

  final ContentStore _store;
  final ContentKind kind;
  final bool isNew;

  void setId(String id) =>
      emit(state.copyWith(id: id.trim(), idError: () => null));

  void setValue(FieldName field, Object? value) {
    final errors = {...state.errors}..remove(field);
    emit(
      state.copyWith(
        values: {...state.values, field.name: value},
        errors: errors,
        status: EditorStatus.editing,
      ),
    );
  }

  void setPublished({required bool published}) =>
      emit(state.copyWith(values: {...state.values, 'published': published}));

  Future<void> save() async {
    final errors = {
      for (final field in kind.fields)
        if (validateField(field, state.values[field.name.name])
            case final FieldError error)
          field.name: error,
    };
    final idError = isValidId(state.id, kind) ? null : IdError.format;
    emit(state.copyWith(errors: errors, idError: () => idError));
    if (errors.isNotEmpty || idError != null) return;
    emit(state.copyWith(status: EditorStatus.saving));
    try {
      if (isNew && await _store.exists(kind, state.id)) {
        emit(
          state.copyWith(
            idError: () => IdError.taken,
            status: EditorStatus.editing,
          ),
        );
        return;
      }
      await _store.save(kind, state.id, documentOf(kind, state.values));
      emit(state.copyWith(status: EditorStatus.saved));
    } on Exception {
      emit(state.copyWith(status: EditorStatus.failed));
    }
  }
}
