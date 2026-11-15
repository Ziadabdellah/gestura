import 'package:gestura/features/auth/domain/google_accounts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: GoogleAccounts)
final class GoogleSignInAccounts implements GoogleAccounts {
  new(this._google);

  final GoogleSignIn _google;
  Future<void>? _ready;

  Future<void> _prepare() => _ready ??= _google.initialize();

  @override
  Future<String?> idToken() async {
    await _prepare();
    try {
      final account = await _google.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _prepare();
    await _google.signOut();
  }
}
