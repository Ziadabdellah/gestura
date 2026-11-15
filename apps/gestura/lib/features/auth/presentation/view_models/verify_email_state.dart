import 'package:equatable/equatable.dart';
import 'package:gestura_core/gestura_core.dart';

enum VerifyEmailNotice { none, sent, notConfirmedYet }

sealed class VerifyEmailState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class VerifyEmailPending extends VerifyEmailState {
  const new({
    required this.email,
    this.busy = false,
    this.notice = VerifyEmailNotice.none,
    this.failure,
  });

  final String email;
  final bool busy;
  final VerifyEmailNotice notice;
  final Failure? failure;

  @override
  List<Object?> get props => [email, busy, notice, failure];
}

final class VerifyEmailConfirmed extends VerifyEmailState {
  const new();
}
