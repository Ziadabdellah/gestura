import 'dart:async';

import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura_core/gestura_core.dart';

const GuestUser testGuest = GuestUser('guest-uid');

const MemberUser testMember = MemberUser(
  'member-uid',
  email: 'learner@example.com',
  emailVerified: true,
);

class FakeAuthRepository implements AuthRepository {
  new([this._user = testGuest]);

  AppUser? _user;
  Failure? failure;
  Completer<void>? hold;
  bool verifyOnRefresh = false;
  final List<String> calls = [];
  final StreamController<AppUser?> _changes = StreamController.broadcast();

  AppUser? get user => _user;

  set user(AppUser? value) {
    _user = value;
    _changes.add(value);
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> watchUser() => Stream.multi((controller) {
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  Future<Result<T>> _answer<T>(String call, T Function() change) async {
    calls.add(call);
    if (hold case final Completer<void> hold) await hold.future;
    if (failure case final Failure failure) return Err(failure);
    return Ok(change());
  }

  @override
  Future<Result<void>> continueAsGuest() =>
      _answer('guest', () => user = testGuest);

  @override
  Future<Result<void>> continueWithGoogle() => _answer(
    'google',
    () => user = const MemberUser(
      'member-uid',
      email: 'learner@gmail.com',
      emailVerified: true,
      usesPassword: false,
    ),
  );

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) => _answer(
    'signIn:$email',
    () => user = MemberUser('member-uid', email: email, emailVerified: true),
  );

  @override
  Future<Result<void>> createAccount({
    required String email,
    required String password,
  }) => _answer(
    'create:$email',
    () => user = MemberUser(
      _user?.id ?? 'member-uid',
      email: email,
      emailVerified: false,
    ),
  );

  @override
  Future<Result<void>> sendPasswordReset({
    required String email,
    required String languageCode,
  }) => _answer('reset:$email:$languageCode', () {});

  @override
  Future<Result<void>> sendEmailVerification({required String languageCode}) =>
      _answer('verify:$languageCode', () {});

  @override
  Future<Result<AppUser?>> refreshUser() => _answer('refresh', () {
    if (_user case MemberUser(:final id, :final email) when verifyOnRefresh) {
      user = MemberUser(id, email: email, emailVerified: true);
    }
    return _user;
  });

  @override
  Future<Result<void>> signOut() => _answer('signOut', () => user = null);

  @override
  Future<Result<void>> reauthenticate({String? password}) =>
      _answer('reauth:${password ?? 'google'}', () {});

  @override
  Future<Result<void>> deleteAccount() => _answer('delete', () => user = null);
}
