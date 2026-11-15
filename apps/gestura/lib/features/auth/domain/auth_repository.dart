import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura_core/gestura_core.dart';

abstract interface class AuthRepository {
  AppUser? get currentUser;

  Stream<AppUser?> watchUser();

  Future<Result<void>> continueAsGuest();

  Future<Result<void>> continueWithGoogle();

  Future<Result<void>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> createAccount({
    required String email,
    required String password,
  });

  Future<Result<void>> sendPasswordReset({
    required String email,
    required String languageCode,
  });

  Future<Result<void>> sendEmailVerification({required String languageCode});

  Future<Result<AppUser?>> refreshUser();

  Future<Result<void>> signOut();

  Future<Result<void>> reauthenticate({String? password});

  Future<Result<void>> deleteAccount();
}
