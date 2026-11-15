import 'package:meta/meta.dart';

@immutable
sealed class Failure {
  const new();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class NetworkFailure extends Failure {
  const new();
}

final class NotFoundFailure extends Failure {
  const new();
}

final class PermissionDeniedFailure extends Failure {
  const new();
}

final class StorageFullFailure extends Failure {
  const new();
}

final class NoContentFailure extends Failure {
  const new();
}

enum AuthProblem {
  invalidEmail,
  wrongCredentials,
  emailInUse,
  weakPassword,
  tooManyRequests,
  accountDisabled,
  unavailable,
  signInAgain,
  cancelled,
}

final class AuthFailure extends Failure {
  const new(this.problem);

  final AuthProblem problem;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthFailure && other.problem == problem;

  @override
  int get hashCode => Object.hash(AuthFailure, problem);

  @override
  String toString() => 'AuthFailure(${problem.name})';
}

final class UnexpectedFailure extends Failure {
  const new(this.error);

  final Object error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnexpectedFailure && other.error == error;

  @override
  int get hashCode => Object.hash(UnexpectedFailure, error);

  @override
  String toString() => 'UnexpectedFailure($error)';
}
