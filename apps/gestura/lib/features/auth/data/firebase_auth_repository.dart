import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/auth/domain/google_accounts.dart';
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
  User(:final uid, :final email, :final emailVerified, :final providerData) =>
    MemberUser(
      uid,
      email: email ?? '',
      emailVerified: emailVerified,
      usesPassword: providerData.any(
        (info) => info.providerId == EmailAuthProvider.PROVIDER_ID,
      ),
    ),
};

@LazySingleton(as: AuthRepository)
final class FirebaseAuthRepository implements AuthRepository {
  const new(this._auth, this._google);

  final FirebaseAuth _auth;
  final GoogleAccounts _google;

  @override
  AppUser? get currentUser => appUserOf(_auth.currentUser);

  @override
  Stream<AppUser?> watchUser() => _auth.userChanges().map(appUserOf);

  @override
  Future<Result<void>> continueAsGuest() => _guard(_auth.signInAnonymously);

  @override
  Future<Result<void>> continueWithGoogle() async {
    try {
      final credential = await _googleCredential();
      if (credential == null) {
        return const Err(AuthFailure(AuthProblem.cancelled));
      }
      final guest = _auth.currentUser;
      if (guest != null && guest.isAnonymous) {
        try {
          await guest.linkWithCredential(credential);
          return const Ok(null);
        } on FirebaseAuthException catch (error) {
          if (error.code != 'credential-already-in-use') rethrow;
          await _auth.signInWithCredential(error.credential ?? credential);
          return const Ok(null);
        }
      }
      await _auth.signInWithCredential(credential);
      return const Ok(null);
    } on Object catch (error) {
      return Err(authFailure(error));
    }
  }

  Future<AuthCredential?> _googleCredential() async {
    final token = await _google.idToken();
    return token == null ? null : GoogleAuthProvider.credential(idToken: token);
  }

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
  Future<Result<void>> signOut() => _guard(() async {
    final google = _auth.currentUser?.providerData.any(
      (info) => info.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
    await _auth.signOut();
    if (google ?? false) await _google.signOut();
  });

  @override
  Future<Result<void>> reauthenticate({String? password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous) return const Ok(null);
      final credential = password != null
          ? EmailAuthProvider.credential(
              email: user.email ?? '',
              password: password,
            )
          : await _googleCredential();
      if (credential == null) {
        return const Err(AuthFailure(AuthProblem.cancelled));
      }
      await user.reauthenticateWithCredential(credential);
      return const Ok(null);
    } on Object catch (error) {
      return Err(authFailure(error));
    }
  }

  @override
  Future<Result<void>> deleteAccount() => _guard(() async {
    await _auth.currentUser?.delete();
  });

  Future<Result<void>> _guard(Future<void> Function() body) =>
      Result.guard<void>(() async {
        await body();
      }, onError: (error, _) => authFailure(error));
}
