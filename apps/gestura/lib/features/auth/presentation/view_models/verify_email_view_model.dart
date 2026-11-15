import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/auth/presentation/view_models/verify_email_state.dart';
import 'package:gestura_core/gestura_core.dart';

class VerifyEmailViewModel extends Cubit<VerifyEmailState> {
  new(this._auth) : super(_initial(_auth.currentUser));

  final AuthRepository _auth;

  static VerifyEmailState _initial(AppUser? user) => switch (user) {
    MemberUser(emailVerified: true) => const VerifyEmailConfirmed(),
    MemberUser(:final email) => VerifyEmailPending(email: email),
    GuestUser() || null => const VerifyEmailPending(email: ''),
  };

  Future<void> check() async {
    if (state case final VerifyEmailPending pending when !pending.busy) {
      emit(VerifyEmailPending(email: pending.email, busy: true));
      final result = await _auth.refreshUser();
      if (isClosed) return;
      emit(switch (result) {
        Ok(value: MemberUser(emailVerified: true)) =>
          const VerifyEmailConfirmed(),
        Ok() => VerifyEmailPending(
          email: pending.email,
          notice: VerifyEmailNotice.notConfirmedYet,
        ),
        Err(:final failure) => VerifyEmailPending(
          email: pending.email,
          failure: failure,
        ),
      });
    }
  }

  Future<void> resend({required String languageCode}) async {
    if (state case final VerifyEmailPending pending when !pending.busy) {
      emit(VerifyEmailPending(email: pending.email, busy: true));
      final result = await _auth.sendEmailVerification(
        languageCode: languageCode,
      );
      if (isClosed) return;
      emit(switch (result) {
        Ok() => VerifyEmailPending(
          email: pending.email,
          notice: VerifyEmailNotice.sent,
        ),
        Err(:final failure) => VerifyEmailPending(
          email: pending.email,
          failure: failure,
        ),
      });
    }
  }
}
