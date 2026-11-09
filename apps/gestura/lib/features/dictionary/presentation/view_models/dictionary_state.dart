import 'package:equatable/equatable.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura_core/gestura_core.dart';

sealed class DictionaryState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class DictionaryLoading extends DictionaryState {
  const new();
}

final class DictionaryLoaded extends DictionaryState {
  const new(this.signs);

  final List<Sign> signs;

  bool get hasPlaceholders => signs.any((sign) => sign.isPlaceholder);

  @override
  List<Object?> get props => [signs];
}

final class DictionaryFailed extends DictionaryState {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
