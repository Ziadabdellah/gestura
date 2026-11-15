import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_gate.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/features/auth/domain/auth_entry.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('every screen has a stable address for deep links', () {
    expect(const LearnRoute().location, '/learn');
    expect(const DictionaryRoute().location, '/dictionary');
    expect(const SignRoute(signId: 'hello').location, '/dictionary/sign/hello');
    expect(const ProfileRoute().location, '/profile');
    expect(const SettingsRoute().location, '/profile/settings');
    expect(
      const LessonRoute(lessonId: 'demo-a1-1').location,
      '/lesson/demo-a1-1',
    );
    expect(const OnboardingRoute().location, '/onboarding');
    expect(const WelcomeRoute().location, '/welcome');
    expect(const SignInRoute().location, '/account/sign-in');
    expect(
      const SignInRoute(entry: AuthEntry.profile).location,
      '/account/sign-in?entry=profile',
    );
    expect(const CreateAccountRoute().location, '/account/create');
    expect(const ResetPasswordRoute().location, '/account/reset-password');
    expect(
      const VerifyEmailRoute(entry: AuthEntry.profile).location,
      '/account/verify-email?entry=profile',
    );
  });

  test('each tab is a branch of its own', () {
    final branches = <StatefulShellBranchData Function()>[
      LearnBranch.new,
      DictionaryBranch.new,
      ProfileBranch.new,
    ];

    expect({for (final branch in branches) branch().runtimeType}, hasLength(3));
  });

  test('the router starts where it is told', () {
    final gate = AppGate(onboarded: true, signedIn: true);
    final router = createAppRouter(gate: gate, initialLocation: '/dictionary');
    addTearDown(router.dispose);
    addTearDown(gate.dispose);

    expect(router.routeInformationProvider.value.uri.path, '/dictionary');
  });

  group('gateRedirect', () {
    String? redirect(
      String path, {
      bool onboarded = true,
      bool signedIn = true,
    }) => gateRedirect(path, onboarded: onboarded, signedIn: signedIn);

    test('sends a first-time learner to onboarding from anywhere', () {
      for (final path in ['/', '/learn', '/welcome', '/account/sign-in']) {
        expect(redirect(path, onboarded: false), '/onboarding', reason: path);
      }
      expect(redirect('/onboarding', onboarded: false), isNull);
    });

    test('asks for a guest or an account after onboarding', () {
      for (final path in ['/', '/learn', '/onboarding', '/profile']) {
        expect(redirect(path, signedIn: false), '/welcome', reason: path);
      }
      expect(redirect('/account/verify-email', signedIn: false), '/welcome');
    });

    test('lets a signed-out learner use the sign-in forms', () {
      for (final path in [
        '/welcome',
        '/account/sign-in',
        '/account/create',
        '/account/reset-password',
      ]) {
        expect(redirect(path, signedIn: false), isNull, reason: path);
      }
    });

    test('takes a signed-in learner past the first-run screens', () {
      for (final path in ['/', '/onboarding', '/welcome']) {
        expect(redirect(path), '/learn', reason: path);
      }
    });

    test('leaves every other screen alone once signed in', () {
      for (final path in [
        '/learn',
        '/dictionary/sign/hello',
        '/account/create',
        '/account/verify-email',
      ]) {
        expect(redirect(path), isNull, reason: path);
      }
    });
  });

  group('AppGate', () {
    test('tells the router only when something changed', () {
      final gate = AppGate(onboarded: false, signedIn: false);
      addTearDown(gate.dispose);
      var notified = 0;
      gate
        ..addListener(() => notified++)
        ..onboarded = false
        ..signedIn = false;
      final quiet = notified;
      gate
        ..onboarded = true
        ..signedIn = true;

      expect(quiet, 0);
      expect(notified, 2);
      expect(gate.onboarded, isTrue);
      expect(gate.signedIn, isTrue);
    });
  });
}
