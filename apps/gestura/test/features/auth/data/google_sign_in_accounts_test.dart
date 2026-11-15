import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/auth/data/google_sign_in_accounts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class _MockGoogle extends Mock implements GoogleSignIn;

class _MockAccount extends Mock implements GoogleSignInAccount;

void main() {
  late _MockGoogle google;

  setUp(() {
    google = _MockGoogle();
    when(google.initialize).thenAnswer((_) async {});
    when(google.signOut).thenAnswer((_) async {});
  });

  test('returns the ID token of the chosen account', () async {
    final account = _MockAccount();
    when(() => account.authentication)
        .thenReturn(const GoogleSignInAuthentication(idToken: 'token'));
    when(google.authenticate).thenAnswer((_) async => account);
    final accounts = GoogleSignInAccounts(google);

    expect(await accounts.idToken(), 'token');
    await accounts.signOut();

    verify(google.initialize).called(1);
    verify(google.signOut).called(1);
  });

  test('treats a closed or interrupted sheet as no answer', () async {
    final accounts = GoogleSignInAccounts(google);
    for (final code in [
      GoogleSignInExceptionCode.canceled,
      GoogleSignInExceptionCode.interrupted,
    ]) {
      when(google.authenticate).thenThrow(GoogleSignInException(code: code));
      expect(await accounts.idToken(), isNull);
    }
  });

  test('passes other problems on', () async {
    when(google.authenticate).thenThrow(
      const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
      ),
    );

    await expectLater(
      GoogleSignInAccounts(google).idToken(),
      throwsA(isA<GoogleSignInException>()),
    );
  });
}
