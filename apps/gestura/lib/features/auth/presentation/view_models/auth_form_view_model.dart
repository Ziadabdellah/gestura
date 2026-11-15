import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/auth/domain/credentials.dart';
import 'package:gestura/features/auth/presentation/view_models/auth_form_state.dart';
import 'package:gestura_core/gestura_core.dart';

class AuthFormViewModel extends Cubit<AuthFormState> {
  new(this._auth, this._telemetry) : super(const AuthFormIdle());

  final AuthRepository _auth;
  final Telemetry _telemetry;

  Future<void> continueAsGuest() =>
      _run(_auth.continueAsGuest, const SignedUp(AccountMethod.guest));

  Future<void> signIn({required String email, required String password}) =>
      _run(
        () => _auth.signIn(
          email: Credentials.normalizeEmail(email),
          password: password,
        ),
        const SignedIn(),
      );

  Future<void> createAccount({
    required String email,
    required String password,
    required String languageCode,
  }) => _run(() async {
    final created = await _auth.createAccount(
      email: Credentials.normalizeEmail(email),
      password: password,
    );
    if (created.isOk) {
      await _auth.sendEmailVerification(languageCode: languageCode);
    }
    return created;
  }, const SignedUp(AccountMethod.email));

  Future<void> sendPasswordReset({
    required String email,
    required String languageCode,
  }) => _run(
    () => _auth.sendPasswordReset(
      email: Credentials.normalizeEmail(email),
      languageCode: languageCode,
    ),
  );

  void dismissFailure() {
    if (state is AuthFormFailed) emit(const AuthFormIdle());
  }

  Future<void> _run(
    Future<Result<void>> Function() action, [
    TelemetryEvent? success,
  ]) async {
    if (state is AuthFormBusy) return;
    emit(const AuthFormBusy());
    final result = await action();
    if (result.isOk && success != null) await _telemetry.record(success);
    if (isClosed) return;
    emit(switch (result) {
      Ok() => const AuthFormDone(),
      Err(:final failure) => AuthFormFailed(failure),
    });
  }
}
