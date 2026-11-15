import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/auth/data/firebase_auth_repository.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

class _MockCredential extends Mock implements UserCredential;

class _AuthError extends FirebaseAuthException {
  new(String code) : super(code: code);
}

_MockUser _user({
  bool anonymous = false,
  String? email = 'learner@example.com',
  bool verified = false,
}) {
  final user = _MockUser();
  when(() => user.uid).thenReturn('uid');
  when(() => user.isAnonymous).thenReturn(anonymous);
  when(() => user.email).thenReturn(email);
  when(() => user.emailVerified).thenReturn(verified);
  return user;
}

void main() {
  late _MockAuth auth;
  late FirebaseAuthRepository repository;

  setUpAll(
    () => registerFallbackValue(
      EmailAuthProvider.credential(email: 'x@y.z', password: 'p'),
    ),
  );

  setUp(() {
    auth = _MockAuth();
    repository = FirebaseAuthRepository(auth);
    when(() => auth.setLanguageCode(any())).thenAnswer((_) async {});
  });

  group('appUserOf', () {
    test('turns Firebase users into guests and members', () {
      expect(appUserOf(null), isNull);
      expect(appUserOf(_user(anonymous: true)), const GuestUser('uid'));
      expect(
        appUserOf(_user(verified: true)),
        const MemberUser(
          'uid',
          email: 'learner@example.com',
          emailVerified: true,
        ),
      );
      expect(
        appUserOf(_user(email: null)),
        const MemberUser('uid', email: '', emailVerified: false),
      );
    });
  });

  group('authFailure', () {
    test('turns Firebase codes into failures the learner understands', () {
      const expected = {
        'invalid-email': AuthFailure(AuthProblem.invalidEmail),
        'invalid-credential': AuthFailure(AuthProblem.wrongCredentials),
        'wrong-password': AuthFailure(AuthProblem.wrongCredentials),
        'user-not-found': AuthFailure(AuthProblem.wrongCredentials),
        'INVALID_LOGIN_CREDENTIALS': AuthFailure(AuthProblem.wrongCredentials),
        'email-already-in-use': AuthFailure(AuthProblem.emailInUse),
        'credential-already-in-use': AuthFailure(AuthProblem.emailInUse),
        'weak-password': AuthFailure(AuthProblem.weakPassword),
        'too-many-requests': AuthFailure(AuthProblem.tooManyRequests),
        'user-disabled': AuthFailure(AuthProblem.accountDisabled),
        'operation-not-allowed': AuthFailure(AuthProblem.unavailable),
        'admin-restricted-operation': AuthFailure(AuthProblem.unavailable),
        'requires-recent-login': AuthFailure(AuthProblem.signInAgain),
        'user-mismatch': AuthFailure(AuthProblem.signInAgain),
        'network-request-failed': NetworkFailure(),
      };

      for (final MapEntry(key: code, value: failure) in expected.entries) {
        expect(authFailure(_AuthError(code)), failure, reason: code);
      }
    });

    test('keeps anything else as an unexpected failure', () {
      final unknown = _AuthError('internal-error');
      final other = StateError('broken');

      expect(authFailure(unknown), UnexpectedFailure(unknown));
      expect(authFailure(other), UnexpectedFailure(other));
    });
  });

  test('reads the current user and follows changes', () async {
    final changes = StreamController<User?>();
    addTearDown(changes.close);
    final guest = _user(anonymous: true);
    final member = _user(verified: true);
    when(() => auth.currentUser).thenReturn(guest);
    when(auth.userChanges).thenAnswer((_) => changes.stream);

    expect(repository.currentUser, const GuestUser('uid'));

    final users = repository.watchUser().take(2).toList();
    changes
      ..add(member)
      ..add(null);

    expect(await users, [
      const MemberUser(
        'uid',
        email: 'learner@example.com',
        emailVerified: true,
      ),
      null,
    ]);
  });

  test('signs in as a guest', () async {
    when(auth.signInAnonymously).thenAnswer((_) async => _MockCredential());

    expect(await repository.continueAsGuest(), const Ok<void>(null));
  });

  test('signs in with email and password', () async {
    when(
      () => auth.signInWithEmailAndPassword(
        email: 'learner@example.com',
        password: 'secret123',
      ),
    ).thenAnswer((_) async => _MockCredential());

    final result = await repository.signIn(
      email: 'learner@example.com',
      password: 'secret123',
    );

    expect(result, const Ok<void>(null));
  });

  test('reports a wrong password', () async {
    when(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(_AuthError('invalid-credential'));

    final result = await repository.signIn(email: 'a@b.co', password: 'x');

    expect(result, const Err<void>(AuthFailure(AuthProblem.wrongCredentials)));
  });

  test('links a guest to the new email account', () async {
    final guest = _user(anonymous: true);
    when(() => auth.currentUser).thenReturn(guest);
    when(() => guest.linkWithCredential(any()))
        .thenAnswer((_) async => _MockCredential());

    final result = await repository.createAccount(
      email: 'learner@example.com',
      password: 'secret123',
    );

    expect(result, const Ok<void>(null));
    final credential =
        verify(() => guest.linkWithCredential(captureAny())).captured.single
            as EmailAuthCredential;
    expect(credential.email, 'learner@example.com');
    verifyNever(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  test('creates a new account when nobody is signed in', () async {
    when(() => auth.currentUser).thenReturn(null);
    when(
      () => auth.createUserWithEmailAndPassword(
        email: 'learner@example.com',
        password: 'secret123',
      ),
    ).thenAnswer((_) async => _MockCredential());

    final result = await repository.createAccount(
      email: 'learner@example.com',
      password: 'secret123',
    );

    expect(result, const Ok<void>(null));
  });

  test('creates a new account next to a member who is signed in', () async {
    final member = _user();
    when(() => auth.currentUser).thenReturn(member);
    when(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(_AuthError('email-already-in-use'));

    final result = await repository.createAccount(
      email: 'learner@example.com',
      password: 'secret123',
    );

    expect(result, const Err<void>(AuthFailure(AuthProblem.emailInUse)));
  });

  test('sends the reset link in the interface language', () async {
    when(() => auth.sendPasswordResetEmail(email: 'learner@example.com'))
        .thenAnswer((_) async {});

    final result = await repository.sendPasswordReset(
      email: 'learner@example.com',
      languageCode: 'de',
    );

    expect(result, const Ok<void>(null));
    verifyInOrder([
      () => auth.setLanguageCode('de'),
      () => auth.sendPasswordResetEmail(email: 'learner@example.com'),
    ]);
  });

  test('sends the confirmation email in the interface language', () async {
    final member = _user();
    when(() => auth.currentUser).thenReturn(member);
    when(member.sendEmailVerification).thenAnswer((_) async {});

    final result = await repository.sendEmailVerification(languageCode: 'ar');

    expect(result, const Ok<void>(null));
    verifyInOrder([
      () => auth.setLanguageCode('ar'),
      member.sendEmailVerification,
    ]);
  });

  test('sends no confirmation when nobody is signed in', () async {
    when(() => auth.currentUser).thenReturn(null);

    expect(
      await repository.sendEmailVerification(languageCode: 'en'),
      const Ok<void>(null),
    );
  });

  test('reloads the user to see a confirmed email', () async {
    final member = _user(verified: true);
    when(() => auth.currentUser).thenReturn(member);
    when(member.reload).thenAnswer((_) async {});

    expect(
      await repository.refreshUser(),
      const Ok<AppUser?>(
        MemberUser('uid', email: 'learner@example.com', emailVerified: true),
      ),
    );
    verify(member.reload).called(1);
  });

  test('reports a reload that fails', () async {
    final member = _user();
    when(() => auth.currentUser).thenReturn(member);
    when(member.reload).thenThrow(_AuthError('network-request-failed'));

    expect(
      await repository.refreshUser(),
      const Err<AppUser?>(NetworkFailure()),
    );
  });

  test('deletes the signed-in user', () async {
    final guest = _user(anonymous: true);
    when(() => auth.currentUser).thenReturn(guest);
    when(guest.delete).thenAnswer((_) async {});

    expect(await repository.deleteAccount(), const Ok<void>(null));
    verify(guest.delete).called(1);
  });

  test('has nothing to delete when nobody is signed in', () async {
    when(() => auth.currentUser).thenReturn(null);

    expect(await repository.deleteAccount(), const Ok<void>(null));
  });

  test('confirms the password of a member', () async {
    final member = _user();
    when(() => auth.currentUser).thenReturn(member);
    when(() => member.reauthenticateWithCredential(any()))
        .thenAnswer((_) async => _MockCredential());

    final result = await repository.reauthenticate(password: 'secret123');

    expect(result, const Ok<void>(null));
    final credential =
        verify(() => member.reauthenticateWithCredential(captureAny()))
                .captured
                .single
            as EmailAuthCredential;
    expect(credential.email, 'learner@example.com');
  });

  test('uses an empty email for a member without one', () async {
    final member = _user(email: null);
    when(() => auth.currentUser).thenReturn(member);
    when(() => member.reauthenticateWithCredential(any()))
        .thenThrow(_AuthError('user-mismatch'));

    expect(
      await repository.reauthenticate(password: 'secret123'),
      const Err<void>(AuthFailure(AuthProblem.signInAgain)),
    );
  });

  test('has nobody to confirm for a guest or nobody', () async {
    final guest = _user(anonymous: true);
    when(() => auth.currentUser).thenReturn(guest);

    expect(
      await repository.reauthenticate(password: 'x'),
      const Ok<void>(null),
    );
    verifyNever(() => guest.reauthenticateWithCredential(any()));

    when(() => auth.currentUser).thenReturn(null);
    expect(
      await repository.reauthenticate(password: 'x'),
      const Ok<void>(null),
    );
  });

  test('signs out', () async {
    when(auth.signOut).thenAnswer((_) async {});

    expect(await repository.signOut(), const Ok<void>(null));
    verify(auth.signOut).called(1);
  });
}
