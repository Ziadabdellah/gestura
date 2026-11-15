import 'package:flutter/material.dart';
import 'package:gestura/app/router/app_gate.dart';
import 'package:gestura/app/view/app_shell.dart';
import 'package:gestura/features/auth/domain/auth_entry.dart';
import 'package:gestura/features/auth/presentation/pages/create_account_page.dart';
import 'package:gestura/features/auth/presentation/pages/reset_password_page.dart';
import 'package:gestura/features/auth/presentation/pages/sign_in_page.dart';
import 'package:gestura/features/auth/presentation/pages/verify_email_page.dart';
import 'package:gestura/features/auth/presentation/pages/welcome_page.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/dictionary/presentation/pages/dictionary_page.dart';
import 'package:gestura/features/learn/presentation/pages/learn_page.dart';
import 'package:gestura/features/lesson/presentation/pages/lesson_page.dart';
import 'package:gestura/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:gestura/features/profile/presentation/pages/profile_page.dart';
import 'package:gestura/features/settings/presentation/pages/settings_page.dart';
import 'package:gestura/features/sign_detail/presentation/pages/sign_detail_page.dart';
import 'package:go_router/go_router.dart';

part 'app_routes.g.dart';

@TypedStatefulShellRoute<AppShellRoute>(
  branches: [
    TypedStatefulShellBranch<LearnBranch>(
      routes: [TypedGoRoute<LearnRoute>(path: '/learn')],
    ),
    TypedStatefulShellBranch<DictionaryBranch>(
      routes: [
        TypedGoRoute<DictionaryRoute>(
          path: '/dictionary',
          routes: [TypedGoRoute<SignRoute>(path: 'sign/:signId')],
        ),
      ],
    ),
    TypedStatefulShellBranch<ProfileBranch>(
      routes: [
        TypedGoRoute<ProfileRoute>(
          path: '/profile',
          routes: [TypedGoRoute<SettingsRoute>(path: 'settings')],
        ),
      ],
    ),
  ],
)
@immutable
class AppShellRoute extends StatefulShellRouteData {
  const new();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) => AppShell(navigationShell: navigationShell);
}

@immutable
class LearnBranch extends StatefulShellBranchData {
  const new();
}

@immutable
class DictionaryBranch extends StatefulShellBranchData {
  const new();
}

@immutable
class ProfileBranch extends StatefulShellBranchData {
  const new();
}

@immutable
class LearnRoute extends GoRouteData with $LearnRoute, MaterialTransitions {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) => const LearnPage();
}

@immutable
class DictionaryRoute extends GoRouteData
    with $DictionaryRoute, MaterialTransitions {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DictionaryPage();
}

@immutable
class SignRoute extends GoRouteData with $SignRoute, MaterialTransitions {
  const new({required this.signId});

  final String signId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SignDetailPage(signId: SignId(signId));
}

@immutable
class ProfileRoute extends GoRouteData with $ProfileRoute, MaterialTransitions {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProfilePage();
}

@immutable
class SettingsRoute extends GoRouteData
    with $SettingsRoute, MaterialTransitions {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsPage();
}

@TypedGoRoute<LessonRoute>(path: '/lesson/:lessonId')
@immutable
class LessonRoute extends GoRouteData with $LessonRoute, MaterialTransitions {
  const new({required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      LessonPage(lessonId: LessonId(lessonId));
}

@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
@immutable
class OnboardingRoute extends GoRouteData
    with $OnboardingRoute, MaterialTransitions {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const OnboardingPage();
}

@TypedGoRoute<WelcomeRoute>(path: '/welcome')
@immutable
class WelcomeRoute extends GoRouteData with $WelcomeRoute, MaterialTransitions {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const WelcomePage();
}

@TypedGoRoute<SignInRoute>(path: '/account/sign-in')
@immutable
class SignInRoute extends GoRouteData with $SignInRoute, MaterialTransitions {
  const new({this.entry = AuthEntry.welcome});

  final AuthEntry entry;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SignInPage(entry: entry);
}

@TypedGoRoute<CreateAccountRoute>(path: '/account/create')
@immutable
class CreateAccountRoute extends GoRouteData
    with $CreateAccountRoute, MaterialTransitions {
  const new({this.entry = AuthEntry.welcome});

  final AuthEntry entry;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CreateAccountPage(entry: entry);
}

@TypedGoRoute<ResetPasswordRoute>(path: '/account/reset-password')
@immutable
class ResetPasswordRoute extends GoRouteData
    with $ResetPasswordRoute, MaterialTransitions {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ResetPasswordPage();
}

@TypedGoRoute<VerifyEmailRoute>(path: '/account/verify-email')
@immutable
class VerifyEmailRoute extends GoRouteData
    with $VerifyEmailRoute, MaterialTransitions {
  const new({this.entry = AuthEntry.welcome});

  final AuthEntry entry;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      VerifyEmailPage(entry: entry);
}

mixin MaterialTransitions on GoRouteData {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      MaterialPage<void>(
        key: state.pageKey,
        name: state.name ?? state.path,
        restorationId: state.pageKey.value,
        child: build(context, state),
      );
}

const String rootLocation = '/';
const String accountLocation = '/account/';

String? gateRedirect(
  String path, {
  required bool onboarded,
  required bool signedIn,
}) {
  final onboarding = const OnboardingRoute().location;
  final welcome = const WelcomeRoute().location;
  if (!onboarded) return path == onboarding ? null : onboarding;
  if (!signedIn) {
    final isAuthForm =
        path.startsWith(accountLocation) &&
        path != const VerifyEmailRoute().location;
    return path == welcome || isAuthForm ? null : welcome;
  }
  if (path == rootLocation || path == onboarding || path == welcome) {
    return const LearnRoute().location;
  }
  return null;
}

GoRouter createAppRouter({
  required AppGate gate,
  String initialLocation = rootLocation,
}) => GoRouter(
  routes: $appRoutes,
  initialLocation: initialLocation,
  refreshListenable: gate,
  redirect: (context, state) => gateRedirect(
    state.uri.path,
    onboarded: gate.onboarded,
    signedIn: gate.signedIn,
  ),
);
