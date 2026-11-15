import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/auth/presentation/pages/create_account_page.dart';
import 'package:gestura/features/auth/presentation/pages/reset_password_page.dart';
import 'package:gestura/features/auth/presentation/pages/sign_in_page.dart';
import 'package:gestura/features/auth/presentation/pages/verify_email_page.dart';
import 'package:gestura/features/auth/presentation/pages/welcome_page.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/today/presentation/pages/today_page.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_app.dart';

const AppSettings _arabicDark = AppSettings(
  language: AppLanguage.arabic,
  theme: AppThemePreference.dark,
  onboardingComplete: true,
);

const MemberUser _unconfirmed = MemberUser(
  'member-uid',
  email: 'learner@example.com',
  emailVerified: false,
);

Future<FakeAuthRepository> _signedOut(
  WidgetTester tester, {
  String initialLocation = rootLocation,
  AppSettings settings = englishLight,
  double textScale = 1,
  Size surfaceSize = phoneSize,
}) async {
  final auth = FakeAuthRepository(null);
  await tester.pumpApp(
    auth: auth,
    initialLocation: initialLocation,
    settings: settings,
    textScale: textScale,
    surfaceSize: surfaceSize,
  );
  return auth;
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(GButton, label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _fill(
  WidgetTester tester, {
  String email = 'learner@example.com',
  String password = 'secret123',
}) async {
  await tester.enterText(find.byType(TextFormField).first, email);
  await tester.enterText(find.byType(TextFormField).last, password);
}

void main() {
  group('Welcome', () {
    testWidgets('greets a signed-out learner after onboarding', (tester) async {
      await _signedOut(tester);

      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.text('Ready to start?'), findsOneWidget);
      expect(find.text('Continue as guest'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('I already have an account'), findsOneWidget);
    });

    testWidgets('continues as a guest straight into Today', (tester) async {
      final auth = await _signedOut(tester);

      await _tapButton(tester, 'Continue as guest');

      expect(auth.user, testGuest);
      expect(find.byType(TodayPage), findsOneWidget);
    });

    testWidgets('explains why guest mode failed', (tester) async {
      final auth = await _signedOut(tester);
      auth.failure = const AuthFailure(AuthProblem.unavailable);

      await _tapButton(tester, 'Continue as guest');

      expect(
        find.text(
          "Signing in isn't available right now. Please try again later.",
        ),
        findsOneWidget,
      );
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('locks the other choices while signing in', (tester) async {
      final auth = await _signedOut(tester);
      final hold = auth.hold = Completer<void>();

      await tester.tap(find.text('Continue as guest'));
      await tester.pump();

      expect(
        tester
            .widget<GButton>(find.widgetWithText(GButton, 'Create account'))
            .onPressed,
        isNull,
      );

      hold.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('opens the account forms', (tester) async {
      await _signedOut(tester);

      await _tapButton(tester, 'Create account');
      expect(find.byType(CreateAccountPage), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await _tapButton(tester, 'I already have an account');

      expect(find.byType(SignInPage), findsOneWidget);
    });
  });

  group('Sign in', () {
    final signIn = const SignInRoute().location;

    testWidgets('checks the form before sending it', (tester) async {
      final auth = await _signedOut(tester, initialLocation: signIn);

      await _tapButton(tester, 'Sign in');

      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'learner');
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('signs in and opens Today', (tester) async {
      final auth = await _signedOut(tester, initialLocation: signIn);

      await _fill(tester, email: ' learner@example.com ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(auth.calls, ['signIn:learner@example.com']);
      expect(find.byType(TodayPage), findsOneWidget);
    });

    testWidgets('explains wrong details and keeps the form', (tester) async {
      final auth = await _signedOut(tester, initialLocation: signIn);
      auth.failure = const AuthFailure(AuthProblem.wrongCredentials);

      await _fill(tester);
      await _tapButton(tester, 'Sign in');

      expect(find.text('The email or password is incorrect.'), findsOneWidget);
      expect(find.text('learner@example.com'), findsOneWidget);
    });

    testWidgets('shows and hides the password', (tester) async {
      await _signedOut(tester, initialLocation: signIn);

      bool obscured() => tester
          .widget<EditableText>(
            find.descendant(
              of: find.byType(TextFormField).last,
              matching: find.byType(EditableText),
            ),
          )
          .obscureText;

      expect(obscured(), isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(obscured(), isFalse);
      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(obscured(), isTrue);
    });

    testWidgets('asks the system to fill in saved details', (tester) async {
      await _signedOut(tester, initialLocation: signIn);

      final fields = tester.widgetList<TextField>(find.byType(TextField));

      expect(fields.first.autofillHints, [AutofillHints.email]);
      expect(fields.first.keyboardType, TextInputType.emailAddress);
      expect(fields.last.autofillHints, [AutofillHints.password]);
    });

    testWidgets('opens the reset form and the account form', (tester) async {
      await _signedOut(tester, initialLocation: signIn);

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.byType(ResetPasswordPage), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await _tapButton(tester, 'New here? Create an account');

      expect(find.byType(CreateAccountPage), findsOneWidget);
    });

    testWidgets('goes back to the profile when opened from there', (
      tester,
    ) async {
      final auth = FakeAuthRepository();
      await tester.pumpApp(auth: auth, initialLocation: '/profile');

      await _tapButton(tester, 'I already have an account');
      await _fill(tester);
      await _tapButton(tester, 'Sign in');

      expect(find.text('learner@example.com'), findsOneWidget);
      expect(find.byType(SignInPage), findsNothing);
    });
  });

  group('Create account', () {
    final create = const CreateAccountRoute().location;

    testWidgets('asks for a long enough password', (tester) async {
      final auth = await _signedOut(tester, initialLocation: create);

      expect(find.text('At least 8 characters'), findsOneWidget);

      await _fill(tester, password: 'short');
      await _tapButton(tester, 'Create account');

      expect(find.text('Use at least 8 characters'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('creates the account and asks to confirm the email', (
      tester,
    ) async {
      final auth = await _signedOut(tester, initialLocation: create);

      expect(
        find.text('Create a free account with your email address.'),
        findsOneWidget,
      );
      await _fill(tester);
      await _tapButton(tester, 'Create account');

      expect(auth.calls, ['create:learner@example.com', 'verify:en']);
      expect(find.byType(VerifyEmailPage), findsOneWidget);
      expect(
        find.text(
          'We sent a link to learner@example.com. Open it to confirm your '
          'email address.',
        ),
        findsOneWidget,
      );

      await _tapButton(tester, 'Later');

      expect(find.byType(TodayPage), findsOneWidget);
    });

    testWidgets('explains an email that is already used', (tester) async {
      final auth = await _signedOut(tester, initialLocation: create);
      auth.failure = const AuthFailure(AuthProblem.emailInUse);

      await _fill(tester);
      await _tapButton(tester, 'Create account');

      expect(
        find.text(
          'An account with this email already exists. Sign in instead.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('turns a guest into a member from the profile', (tester) async {
      final auth = FakeAuthRepository()..verifyOnRefresh = true;
      await tester.pumpApp(auth: auth, initialLocation: '/profile');

      expect(find.text("You're learning as a guest"), findsOneWidget);

      await _tapButton(tester, 'Create account');

      expect(
        find.text(
          'Your guest account becomes your new account, so nothing is lost.',
        ),
        findsOneWidget,
      );

      await _fill(tester);
      await _tapButton(tester, 'Create account');
      await _tapButton(tester, "I've confirmed it");

      expect(
        auth.user,
        isA<MemberUser>().having((u) => u.id, 'id', 'guest-uid'),
      );
      expect(find.text('learner@example.com'), findsOneWidget);
      expect(find.text('Email confirmed'), findsOneWidget);
      expect(find.byType(VerifyEmailPage), findsNothing);
    });
  });

  group('Verify email', () {
    final verify = const VerifyEmailRoute().location;

    Future<FakeAuthRepository> open(
      WidgetTester tester, {
      AppUser user = _unconfirmed,
    }) async {
      final auth = FakeAuthRepository(user);
      await tester.pumpApp(auth: auth, initialLocation: verify);
      return auth;
    }

    testWidgets('says when the email is not confirmed yet', (tester) async {
      await open(tester);

      await _tapButton(tester, "I've confirmed it");

      expect(
        find.text(
          "Your email address isn't confirmed yet. Open the link in the "
          'email, then try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('sends the email again', (tester) async {
      final auth = await open(tester);

      await _tapButton(tester, 'Send the email again');

      expect(auth.calls, ['verify:en']);
      expect(find.text('We sent you a new link.'), findsOneWidget);
    });

    testWidgets('explains a failure', (tester) async {
      final auth = await open(tester);
      auth.failure = const NetworkFailure();

      await _tapButton(tester, 'Send the email again');

      expect(
        find.text("You're offline. Check your connection and try again."),
        findsOneWidget,
      );
    });

    testWidgets('goes to Today once the email is confirmed', (tester) async {
      final auth = await open(tester);
      auth.verifyOnRefresh = true;

      await _tapButton(tester, "I've confirmed it");

      expect(find.byType(TodayPage), findsOneWidget);
    });

    testWidgets('lets a confirmed member continue', (tester) async {
      await open(tester, user: testMember);

      expect(find.text('Your email address is confirmed.'), findsOneWidget);

      await _tapButton(tester, 'Continue');

      expect(find.byType(TodayPage), findsOneWidget);
    });

    testWidgets('is only for signed-in learners', (tester) async {
      await _signedOut(tester, initialLocation: verify);

      expect(find.byType(WelcomePage), findsOneWidget);
    });
  });

  group('Reset password', () {
    final reset = const ResetPasswordRoute().location;

    testWidgets('checks the email and sends a link', (tester) async {
      final auth = await _signedOut(tester, initialLocation: reset);

      await _tapButton(tester, 'Send link');
      expect(find.text('Enter your email address'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'learner@example.com');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      expect(auth.calls, ['reset:learner@example.com:en']);
      expect(
        find.text(
          'If an account exists for learner@example.com, a link to reset the '
          'password is on its way.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('explains a failure', (tester) async {
      final auth = await _signedOut(tester, initialLocation: reset);
      auth.failure = const AuthFailure(AuthProblem.tooManyRequests);

      await tester.enterText(find.byType(TextFormField), 'learner@example.com');
      await _tapButton(tester, 'Send link');

      expect(
        find.text('Too many attempts. Wait a moment and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('goes back to sign in after sending', (tester) async {
      await _signedOut(tester, initialLocation: const SignInRoute().location);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'learner@example.com');
      await _tapButton(tester, 'Send link');
      await _tapButton(tester, 'Back to sign in');

      expect(find.byType(SignInPage), findsOneWidget);
    });
  });

  group('Accessibility', () {
    final screens = {
      'welcome': rootLocation,
      'sign in': const SignInRoute().location,
      'create account': const CreateAccountRoute().location,
      'reset password': const ResetPasswordRoute().location,
    };

    for (final MapEntry(key: name, value: location) in screens.entries) {
      for (final settings in [englishLight, _arabicDark]) {
        testWidgets('$name meets the guidelines in ${settings.language.name}', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await _signedOut(
            tester,
            initialLocation: location,
            settings: settings,
          );

          await tester.expectAccessible();
          handle.dispose();
        });
      }

      testWidgets('$name fits at 200% text on a small phone', (tester) async {
        await _signedOut(
          tester,
          initialLocation: location,
          textScale: 2,
          surfaceSize: const Size(320, 640),
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('verify email meets the guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        auth: FakeAuthRepository(_unconfirmed),
        initialLocation: const VerifyEmailRoute().location,
        settings: _arabicDark,
      );

      await tester.expectAccessible();
      handle.dispose();
    });
  });
}
