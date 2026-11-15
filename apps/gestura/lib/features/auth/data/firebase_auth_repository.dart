import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:injectable/injectable.dart';

Failure authFailure(Object error) => switch (error) {
  FirebaseAuthException(:final code) => switch (code) {
    'invalid-email' => const AuthFailure(AuthProblem.invalidEmail),
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'INVALID_LOGIN_CREDENTIALS' => const AuthFailure(
      AuthProblem.wrongCredentials,
    ),
    'email-already-in-use' ||
    'credential-already-in-use' => const AuthFailure(AuthProblem.emailInUse),
    'weak-password' => const AuthFailure(AuthProblem.weakPassword),
    'too-many-requests' => const AuthFailure(AuthProblem.tooManyRequests),
    'user-disabled' => const AuthFailure(AuthProblem.accountDisabled),
    'operation-not-allowed' ||
    'admin-restricted-operation' => const AuthFailure(AuthProblem.unavailable),
    'requires-recent-login' ||
    'user-mismatch' => const AuthFailure(AuthProblem.signInAgain),
    'network-request-failed' => const NetworkFailure(),
    _ => UnexpectedFailure(error),
  },
  _ => UnexpectedFailure(error),
};

AppUser? appUserOf(User? user) => switch (user) {
  null => null,
  User(isAnonymous: true, :final uid) => GuestUser(uid),
  User(:final uid, :final email, :final emailVerified) => MemberUser(
    uid,
    email: email ?? '',
    emailVerified: emailVerified,
  ),
};

@LazySingleton(as: AuthRepository)
final class FirebaseAuthRepository implements AuthRepository {
  const new(this._auth);

  final FirebaseAuth _auth;

  @override
  AppUser? get currentUser => appUserOf(_auth.currentUser);

  @override
  Stream<AppUser?> watchUser() => _auth.userChanges().map(appUserOf);

  @override
  Future<Result<void>> continueAsGuest() => _guard(_auth.signInAnonymously);

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) => _guard(
    () => _auth.signInWithEmailAndPassword(email: email, password: password),
  );

  @override
  Future<Result<void>> createAccount({
    required String email,
    required String password,
  }) => _guard(() async {
    final guest = _auth.currentUser;
    if (guest != null && guest.isAnonymous) {
      await guest.linkWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } else {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  });

  @override
  Future<Result<void>> sendPasswordReset({
    required String email,
    required String languageCode,
  }) => _guard(() async {
    await _auth.setLanguageCode(languageCode);
    await _auth.sendPasswordResetEmail(email: email);
  });

  @override
  Future<Result<void>> sendEmailVerification({required String languageCode}) =>
      _guard(() async {
        await _auth.setLanguageCode(languageCode);
        await _auth.currentUser?.sendEmailVerification();
      });

  @override
  Future<Result<AppUser?>> refreshUser() => Result.guard(() async {
    await _auth.currentUser?.reload();
    return currentUser;
  }, onError: (error, _) => authFailure(error));

  @override
  Future<Result<void>> signOut() => _guard(_auth.signOut);

  @override
  Future<Result<void>> reauthenticate({required String password}) =>
      _guard(() async {
        final user = _auth.currentUser;
        if (user == null || user.isAnonymous) return;
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: user.email ?? '',
            password: password,
          ),
        );
      });

  @override
  Future<Result<void>> deleteAccount() => _guard(() async {
    await _auth.currentUser?.delete();
  });

  Future<Result<void>> _guard(Future<void> Function() body) =>
      Result.guard<void>(() async {
        await body();
      }, onError: (error, _) => authFailure(error));
}
