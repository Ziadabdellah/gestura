import 'package:equatable/equatable.dart';
import 'package:gestura_core/gestura_core.dart';

sealed class AuthFormState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class AuthFormIdle extends AuthFormState {
  const new();
}

final class AuthFormBusy extends AuthFormState {
  const new();
}

final class AuthFormFailed extends AuthFormState {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class AuthFormDone extends AuthFormState {
  const new();
}
