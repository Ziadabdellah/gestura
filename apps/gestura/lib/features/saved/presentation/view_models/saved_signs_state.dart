import 'package:equatable/equatable.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura_core/gestura_core.dart';

sealed class SavedSignsState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class SavedSignsLoading extends SavedSignsState {
  const new();
}

final class SavedSignsFailed extends SavedSignsState {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class SavedSignsLoaded extends SavedSignsState {
  const new(this.signs);

  final List<Sign> signs;

  @override
  List<Object?> get props => [signs];
}
