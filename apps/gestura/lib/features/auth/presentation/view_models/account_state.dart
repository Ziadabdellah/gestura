import 'package:equatable/equatable.dart';

sealed class AccountState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class AccountSignedOut extends AccountState {
  const new();
}

final class AccountDeleting extends AccountState {
  const new();
}

final class AccountGuest extends AccountState {
  const new();
}

final class AccountMember extends AccountState {
  const new({required this.email, required this.emailVerified});

  final String email;
  final bool emailVerified;

  @override
  List<Object?> get props => [email, emailVerified];
}
