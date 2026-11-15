import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/auth/presentation/view_models/account_state.dart';
import 'package:gestura/features/auth/presentation/view_models/account_view_model.dart';
import 'package:gestura/features/auth/presentation/view_models/auth_form_state.dart';
import 'package:gestura/features/auth/presentation/view_models/auth_form_view_model.dart';
import 'package:gestura/features/auth/presentation/view_models/verify_email_state.dart';
import 'package:gestura/features/auth/presentation/view_models/verify_email_view_model.dart';
import 'package:gestura/features/learner/learner_data.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../../helpers/fake_activity_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_learner_cloud.dart';
import '../../../helpers/fake_progress_repository.dart';
import '../../../helpers/fake_review_repository.dart';
import '../../../helpers/fake_saved_signs_repository.dart';
import '../../../helpers/fake_telemetry.dart';

const MemberUser _unconfirmed = MemberUser(
  'member-uid',
  email: 'learner@example.com',
  emailVerified: false,
);

LearnerData _local([FakeProgressRepository? progress]) => LearnerData(
  progress ?? FakeProgressRepository(),
  FakeReviewRepository(),
  FakeActivityRepository(),
  FakeSavedSignsRepository(),
);

void main() {
  late FakeAuthRepository auth;
  late FakeTelemetry telemetry;

  setUp(() {
    auth = FakeAuthRepository(null);
    telemetry = FakeTelemetry();
  });

  group('AuthFormViewModel', () {
    test('starts idle', () {
      expect(AuthFormViewModel(auth, telemetry).state, const AuthFormIdle());
    });

    blocTest<AuthFormViewModel, AuthFormState>(
      'continues as a guest',
      build: () => AuthFormViewModel(auth, telemetry),
      act: (viewModel) => viewModel.continueAsGuest(),
      expect: () => [const AuthFormBusy(), const AuthFormDone()],
      verify: (_) {
        expect(auth.user, testGuest);
        expect(telemetry.events.single, isA<SignedUp>());
        expect(telemetry.events.single.parameters, {'method': 'guest'});
      },
    );

    blocTest<AuthFormViewModel, AuthFormState>(
      'continues with Google',
      build: () => AuthFormViewModel(auth, telemetry),
      act: (viewModel) => viewModel.continueWithGoogle(),
      expect: () => [const AuthFormBusy(), const AuthFormDone()],
      verify: (_) {
        expect(auth.calls, ['google']);
        expect(telemetry.events.single.parameters, {'method': 'google'});
      },
    );

    blocTest<AuthFormViewModel, AuthFormState>(
      'goes back to idle when Google is closed',
      setUp: () => auth.failure = const AuthFailure(AuthProblem.cancelled),
      build: () => AuthFormViewModel(auth, telemetry),
      act: (viewModel) => viewModel.continueWithGoogle(),
      expect: () => [const AuthFormBusy(), const AuthFormIdle()],
    );

    blocTest<AuthFormViewModel, AuthFormState>(
      'signs in with a trimmed email address',
      build: () => AuthFormViewModel(auth, telemetry),
      act: (viewModel) =>
          viewModel.signIn(email: ' learner@example.com ', password: 'pw'),
      expect: () => [const AuthFormBusy(), const AuthFormDone()],
      verify: (_) {
        expect(auth.calls, ['signIn:learner@example.com']);
        expect(telemetry.events.single.name, 'login');
      },
    );

    blocTest<AuthFormViewModel, AuthFormState>(
      'creates an account and sends the confirmation email',
      build: () => AuthFormViewModel(auth, telemetry),
      act: (viewModel) => viewModel.createAccount(
        email: 'learner@example.com ',
        password: 'secret123',
        languageCode: 'fr',
      ),
      expect: () => [const AuthFormBusy(), const AuthFormDone()],
      verify: (_) {
        expect(auth.calls, ['create:learner@example.com', 'verify:fr']);
        expect(telemetry.events.single.parameters, {'method': 'email'});
      },
    );

    blocTest<AuthFormViewModel, AuthFormState>(
      'sends no confirmation when the account was not created',
      setUp: () => auth.failure = const AuthFailure(AuthProblem.emailInUse),
      build: () => AuthFormViewModel(auth, telemetry),
      act: (viewModel) => viewModel.createAccount(
        email: 'learner@example.com',
        password: 'secret123',
        languageCode: 'en',
      ),
      expect: () => [
        const AuthFormBusy(),
        const AuthFormFailed(AuthFailure(AuthProblem.emailInUse)),
      ],
      verify: (_) {
        expect(auth.calls, ['create:learner@example.com']);
        expect(telemetry.events, isEmpty);
      },
    );

    blocTest<AuthFormViewModel, AuthFormState>(
      'sends a reset link in the interface language',
      build: () => AuthFormViewModel(auth, telemetry),
      act: (viewModel) => viewModel.sendPasswordReset(
        email: ' learner@example.com',
        languageCode: 'ar',
      ),
      expect: () => [const AuthFormBusy(), const AuthFormDone()],
      verify: (_) {
        expect(auth.calls, ['reset:learner@example.com:ar']);
        expect(telemetry.events, isEmpty);
      },
    );

    blocTest<AuthFormViewModel, AuthFormState>(
      'reports a failure and forgets it on request',
      setUp: () => auth.failure = const NetworkFailure(),
      build: () => AuthFormViewModel(auth, telemetry),
      act: (viewModel) async {
        await viewModel.continueAsGuest();
        viewModel
          ..dismissFailure()
          ..dismissFailure();
      },
      expect: () => [
        const AuthFormBusy(),
        const AuthFormFailed(NetworkFailure()),
        const AuthFormIdle(),
      ],
    );

    blocTest<AuthFormViewModel, AuthFormState>(
      'ignores a second tap while busy',
      build: () => AuthFormViewModel(auth, telemetry),
      act: (viewModel) async {
        final hold = auth.hold = Completer<void>();
        final first = viewModel.continueAsGuest();
        await viewModel.continueAsGuest();
        hold.complete();
        await first;
      },
      expect: () => [const AuthFormBusy(), const AuthFormDone()],
      verify: (_) => expect(auth.calls, ['guest']),
    );

    test('stays quiet when closed before the answer', () async {
      final hold = auth.hold = Completer<void>();
      final viewModel = AuthFormViewModel(auth, telemetry);

      final signingIn = viewModel.continueAsGuest();
      await viewModel.close();
      hold.complete();
      await signingIn;

      expect(viewModel.state, const AuthFormBusy());
    });
  });

  group('VerifyEmailViewModel', () {
    test('starts from the signed-in member', () {
      expect(
        VerifyEmailViewModel(FakeAuthRepository(_unconfirmed)).state,
        const VerifyEmailPending(email: 'learner@example.com'),
      );
      expect(
        VerifyEmailViewModel(FakeAuthRepository(testMember)).state,
        const VerifyEmailConfirmed(),
      );
      expect(
        VerifyEmailViewModel(FakeAuthRepository()).state,
        const VerifyEmailPending(email: ''),
      );
      expect(
        VerifyEmailViewModel(FakeAuthRepository(null)).state,
        const VerifyEmailPending(email: ''),
      );
    });

    blocTest<VerifyEmailViewModel, VerifyEmailState>(
      'finishes once the email is confirmed',
      setUp: () =>
          auth = FakeAuthRepository(_unconfirmed)..verifyOnRefresh = true,
      build: () => VerifyEmailViewModel(auth),
      act: (viewModel) => viewModel.check(),
      expect: () => [
        const VerifyEmailPending(email: 'learner@example.com', busy: true),
        const VerifyEmailConfirmed(),
      ],
    );

    blocTest<VerifyEmailViewModel, VerifyEmailState>(
      'says when the email is not confirmed yet',
      setUp: () => auth = FakeAuthRepository(_unconfirmed),
      build: () => VerifyEmailViewModel(auth),
      act: (viewModel) => viewModel.check(),
      expect: () => [
        const VerifyEmailPending(email: 'learner@example.com', busy: true),
        const VerifyEmailPending(
          email: 'learner@example.com',
          notice: VerifyEmailNotice.notConfirmedYet,
        ),
      ],
    );

    blocTest<VerifyEmailViewModel, VerifyEmailState>(
      'reports a check that fails',
      setUp: () =>
          auth = FakeAuthRepository(_unconfirmed)
            ..failure = const NetworkFailure(),
      build: () => VerifyEmailViewModel(auth),
      act: (viewModel) => viewModel.check(),
      expect: () => [
        const VerifyEmailPending(email: 'learner@example.com', busy: true),
        const VerifyEmailPending(
          email: 'learner@example.com',
          failure: NetworkFailure(),
        ),
      ],
    );

    blocTest<VerifyEmailViewModel, VerifyEmailState>(
      'sends the email again in the interface language',
      setUp: () => auth = FakeAuthRepository(_unconfirmed),
      build: () => VerifyEmailViewModel(auth),
      act: (viewModel) => viewModel.resend(languageCode: 'ru'),
      expect: () => [
        const VerifyEmailPending(email: 'learner@example.com', busy: true),
        const VerifyEmailPending(
          email: 'learner@example.com',
          notice: VerifyEmailNotice.sent,
        ),
      ],
      verify: (_) => expect(auth.calls, ['verify:ru']),
    );

    blocTest<VerifyEmailViewModel, VerifyEmailState>(
      'reports an email that could not be sent',
      setUp: () =>
          auth = FakeAuthRepository(_unconfirmed)
            ..failure = const AuthFailure(AuthProblem.tooManyRequests),
      build: () => VerifyEmailViewModel(auth),
      act: (viewModel) => viewModel.resend(languageCode: 'en'),
      expect: () => [
        const VerifyEmailPending(email: 'learner@example.com', busy: true),
        const VerifyEmailPending(
          email: 'learner@example.com',
          failure: AuthFailure(AuthProblem.tooManyRequests),
        ),
      ],
    );

    blocTest<VerifyEmailViewModel, VerifyEmailState>(
      'does nothing while busy or once confirmed',
      setUp: () => auth = FakeAuthRepository(_unconfirmed),
      build: () => VerifyEmailViewModel(auth),
      seed: () =>
          const VerifyEmailPending(email: 'learner@example.com', busy: true),
      act: (viewModel) async {
        await viewModel.check();
        await viewModel.resend(languageCode: 'en');
        viewModel.emit(const VerifyEmailConfirmed());
        await viewModel.check();
        await viewModel.resend(languageCode: 'en');
      },
      expect: () => [const VerifyEmailConfirmed()],
      verify: (_) => expect(auth.calls, isEmpty),
    );

    test('stays quiet when closed before an answer', () async {
      auth = FakeAuthRepository(_unconfirmed);
      final hold = auth.hold = Completer<void>();
      final checking = VerifyEmailViewModel(auth);
      final resending = VerifyEmailViewModel(auth);

      final check = checking.check();
      final resend = resending.resend(languageCode: 'en');
      await checking.close();
      await resending.close();
      hold.complete();
      await (check, resend).wait;

      expect(
        checking.state,
        const VerifyEmailPending(email: 'learner@example.com', busy: true),
      );
      expect(resending.state, checking.state);
    });
  });

  group('AccountViewModel', () {
    test('maps every kind of user', () {
      expect(AccountViewModel.stateOf(null), const AccountSignedOut());
      expect(AccountViewModel.stateOf(testGuest), const AccountGuest());
      expect(
        AccountViewModel.stateOf(_unconfirmed),
        const AccountMember(email: 'learner@example.com', emailVerified: false),
      );
    });

    blocTest<AccountViewModel, AccountState>(
      'follows the signed-in user',
      setUp: () => auth = FakeAuthRepository(),
      build: () => AccountViewModel(auth, _local(), FakeLearnerCloud().cloud),
      act: (viewModel) async {
        auth.user = _unconfirmed;
        await Future<void>.delayed(Duration.zero);
        auth.user = testMember;
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const AccountMember(email: 'learner@example.com', emailVerified: false),
        const AccountMember(email: 'learner@example.com', emailVerified: true),
      ],
      verify: (viewModel) => expect(
        AccountViewModel(
          FakeAuthRepository(testMember),
          _local(),
          FakeLearnerCloud().cloud,
        ).state,
        const AccountMember(email: 'learner@example.com', emailVerified: true),
      ),
    );

    blocTest<AccountViewModel, AccountState>(
      'signs out',
      setUp: () => auth = FakeAuthRepository(testMember),
      build: () => AccountViewModel(auth, _local(), FakeLearnerCloud().cloud),
      act: (viewModel) async {
        expect(await viewModel.signOut(), const Ok<void>(null));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [const AccountSignedOut()],
    );

    test('deletes the account and the progress on the device', () async {
      auth = FakeAuthRepository(testMember);
      final progress = FakeProgressRepository([completed('demo-a1-1')]);
      final remote = FakeLearnerCloud();
      remote.progress.users['member-uid'] = {
        'demo-a1-1': completed('demo-a1-1'),
      };
      final viewModel = AccountViewModel(auth, _local(progress), remote.cloud);
      final states = <AccountState>[];
      final subscription = viewModel.stream.listen(states.add);

      final result = await viewModel.deleteAccount(password: 'secret123');
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(result, const Ok<void>(null));
      expect(auth.calls, ['reauth:secret123', 'delete']);
      expect(remote.calls, [
        'progress.delete:member-uid',
        'cards.delete:member-uid',
        'activity.delete:member-uid',
      ]);
      expect(remote.progress.users, isEmpty);
      expect(progress.stored, isEmpty);
      expect(states, [const AccountDeleting(), const AccountSignedOut()]);
    });

    test('keeps everything when deleting fails', () async {
      auth = FakeAuthRepository(testMember)
        ..failure = const AuthFailure(AuthProblem.wrongCredentials);
      final progress = FakeProgressRepository([completed('demo-a1-1')]);
      final viewModel = AccountViewModel(
        auth,
        _local(progress),
        FakeLearnerCloud().cloud,
      );

      final result = await viewModel.deleteAccount(password: 'wrong');

      expect(
        result,
        const Err<void>(AuthFailure(AuthProblem.wrongCredentials)),
      );
      expect(progress.stored, hasLength(1));
      expect(
        viewModel.state,
        const AccountMember(email: 'learner@example.com', emailVerified: true),
      );
    });

    test('confirms a Google member with Google before deleting', () async {
      auth = FakeAuthRepository(
        const MemberUser(
          'member-uid',
          email: 'learner@gmail.com',
          emailVerified: true,
          usesPassword: false,
        ),
      );
      final viewModel = AccountViewModel(
        auth,
        _local(),
        FakeLearnerCloud().cloud,
      );
      expect(
        viewModel.state,
        const AccountMember(
          email: 'learner@gmail.com',
          emailVerified: true,
          usesPassword: false,
        ),
      );

      expect(await viewModel.deleteAccount(), const Ok<void>(null));
      expect(auth.calls, ['reauth:google', 'delete']);
    });

    test('keeps the account when its cloud data cannot be deleted', () async {
      auth = FakeAuthRepository();
      final remote = FakeLearnerCloud();
      remote.cards.deleteFailure = const NetworkFailure();
      final viewModel = AccountViewModel(auth, _local(), remote.cloud);

      expect(
        await viewModel.deleteAccount(),
        const Err<void>(NetworkFailure()),
      );
      expect(auth.calls, isEmpty);
      expect(viewModel.state, const AccountGuest());
    });

    test('has nothing to delete without a user', () async {
      final viewModel = AccountViewModel(
        FakeAuthRepository(null),
        _local(),
        FakeLearnerCloud().cloud,
      );

      expect(await viewModel.deleteAccount(), const Ok<void>(null));
      expect(viewModel.state, const AccountSignedOut());
    });

    test('stays quiet when closed while deleting fails', () async {
      auth = FakeAuthRepository()..failure = const NetworkFailure();
      final hold = auth.hold = Completer<void>();
      final viewModel = AccountViewModel(
        auth,
        _local(),
        FakeLearnerCloud().cloud,
      );

      final deleting = viewModel.deleteAccount();
      await viewModel.close();
      hold.complete();

      expect(await deleting, const Err<void>(NetworkFailure()));
      expect(viewModel.state, const AccountDeleting());
    });

    test('stops following the user once closed', () async {
      auth = FakeAuthRepository();
      final viewModel = AccountViewModel(
        auth,
        _local(),
        FakeLearnerCloud().cloud,
      );
      await viewModel.close();

      auth.user = testMember;
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.state, const AccountGuest());
    });
  });
}
