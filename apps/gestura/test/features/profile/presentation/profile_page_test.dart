import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/auth/presentation/pages/verify_email_page.dart';
import 'package:gestura/features/auth/presentation/pages/welcome_page.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/presentation/pages/settings_page.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_progress_repository.dart';
import '../../../helpers/pump_app.dart';

const MemberUser _unconfirmed = MemberUser(
  'member-uid',
  email: 'learner@example.com',
  emailVerified: false,
);

final String _profile = const ProfileRoute().location;

void main() {
  group('Profile', () {
    testWidgets('shows the app version', (tester) async {
      await tester.pumpApp(initialLocation: _profile);

      expect(find.text('About Gestura'), findsOneWidget);
      expect(find.text('Version 1.0.0 (7)'), findsOneWidget);
    });

    testWidgets('invites a guest to create an account', (tester) async {
      await tester.pumpApp(initialLocation: _profile);

      expect(find.text("You're learning as a guest"), findsOneWidget);
      expect(
        find.text('Create a free account with your email address.'),
        findsOneWidget,
      );
      expect(find.text('Sign out'), findsNothing);
    });

    testWidgets('shows a member with a confirmed email', (tester) async {
      await tester.pumpApp(
        initialLocation: _profile,
        auth: FakeAuthRepository(testMember),
      );

      expect(find.text('learner@example.com'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
      expect(find.text('Email confirmed'), findsOneWidget);
      expect(find.text('Confirm email'), findsNothing);
    });

    testWidgets('asks a member to confirm the email and comes back', (
      tester,
    ) async {
      await tester.pumpApp(
        initialLocation: _profile,
        auth: FakeAuthRepository(_unconfirmed),
      );

      expect(find.text('Email not confirmed yet'), findsOneWidget);

      await tester.tap(find.widgetWithText(GButton, 'Confirm email'));
      await tester.pumpAndSettle();

      expect(find.byType(VerifyEmailPage), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);

      await tester.tap(find.widgetWithText(GButton, 'Later'));
      await tester.pumpAndSettle();

      expect(find.text('Email not confirmed yet'), findsOneWidget);
    });

    testWidgets('signs out only after confirming', (tester) async {
      final auth = FakeAuthRepository(testMember);
      await tester.pumpApp(initialLocation: _profile, auth: auth);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Sign out?'), findsOneWidget);
      expect(find.text('Your progress stays on this device.'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(auth.user, testMember);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(auth.user, isNull);
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('closes the sign out dialog from outside', (tester) async {
      final auth = FakeAuthRepository(testMember);
      await tester.pumpApp(initialLocation: _profile, auth: auth);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(auth.user, testMember);
    });

    testWidgets('explains a sign out that failed', (tester) async {
      final auth = FakeAuthRepository(testMember);
      await tester.pumpApp(initialLocation: _profile, auth: auth);
      auth.failure = const NetworkFailure();

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(
        find.text("You're offline. Check your connection and try again."),
        findsOneWidget,
      );
      expect(auth.user, testMember);
    });

    testWidgets('deletes a guest account after confirming', (tester) async {
      final auth = FakeAuthRepository();
      final progress = FakeProgressRepository([completed('demo-a1-1')]);
      await tester.pumpApp(
        initialLocation: _profile,
        auth: auth,
        progress: progress,
      );

      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();

      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(auth.user, testGuest);

      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(auth.calls, ['delete']);
      expect(progress.stored, isEmpty);
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('asks a member for the password before deleting', (
      tester,
    ) async {
      final auth = FakeAuthRepository(testMember);
      await tester.pumpApp(initialLocation: _profile, auth: auth);

      await tester.scrollUntilVisible(find.text('Delete account'), 100);
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();

      final delete = find.widgetWithText(TextButton, 'Delete');
      expect(tester.widget<TextButton>(delete).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'secret123');
      await tester.pump();
      await tester.tap(delete);
      await tester.pumpAndSettle();

      expect(auth.calls, ['reauth:secret123', 'delete']);
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('shows a spinner while deleting and explains a failure', (
      tester,
    ) async {
      final auth = FakeAuthRepository(testMember)
        ..failure = const AuthFailure(AuthProblem.signInAgain);
      await tester.pumpApp(initialLocation: _profile, auth: auth);
      final hold = auth.hold = Completer<void>();

      await tester.scrollUntilVisible(find.text('Delete account'), 100);
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'old-password');
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.bySemanticsLabel('Deleting your account'), findsOneWidget);

      hold.complete();
      await tester.pumpAndSettle();

      expect(
        find.text('For your security, enter your password again.'),
        findsOneWidget,
      );
      expect(find.text('learner@example.com'), findsOneWidget);
    });

    testWidgets('opens settings inside the Profile tab', (tester) async {
      await tester.pumpApp(initialLocation: _profile);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('opens the about page with the open-source licenses', (
      tester,
    ) async {
      await tester.pumpApp(initialLocation: _profile);

      await tester.tap(find.text('About Gestura'));
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
      expect(find.text('Gestura'), findsWidgets);
      expect(find.text('1.0.0 (7)'), findsOneWidget);
      expect(
        find.text(
          'A learning companion, not a replacement for Deaf teachers and '
          'communities.',
        ),
        findsOneWidget,
      );
    });

    for (final settings in [
      englishLight,
      const AppSettings(
        language: AppLanguage.arabic,
        theme: AppThemePreference.dark,
        onboardingComplete: true,
      ),
    ]) {
      for (final user in [testGuest, _unconfirmed]) {
        testWidgets('meets the accessibility guidelines for a '
            '${user.runtimeType} in '
            '${settings.language.name} ${settings.theme.name}', (tester) async {
          final handle = tester.ensureSemantics();
          await tester.pumpApp(
            settings: settings,
            initialLocation: _profile,
            auth: FakeAuthRepository(user),
          );

          await tester.expectAccessible();
          handle.dispose();
        });
      }
    }

    testWidgets('fits at 200% text on a small phone', (tester) async {
      await tester.pumpApp(
        initialLocation: _profile,
        surfaceSize: const Size(320, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
