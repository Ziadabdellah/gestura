import 'package:flutter/widgets.dart';
import 'package:gestura/app/view/app_shell.dart';
import 'package:gestura/features/dictionary/presentation/pages/dictionary_page.dart';
import 'package:gestura/features/learn/presentation/pages/learn_page.dart';
import 'package:gestura/features/profile/presentation/pages/profile_page.dart';
import 'package:gestura/features/settings/presentation/pages/settings_page.dart';
import 'package:go_router/go_router.dart';

part 'app_routes.g.dart';

@TypedStatefulShellRoute<AppShellRoute>(
  branches: [
    TypedStatefulShellBranch<LearnBranch>(
      routes: [TypedGoRoute<LearnRoute>(path: '/learn')],
    ),
    TypedStatefulShellBranch<DictionaryBranch>(
      routes: [TypedGoRoute<DictionaryRoute>(path: '/dictionary')],
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
class LearnRoute extends GoRouteData with $LearnRoute {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) => const LearnPage();
}

@immutable
class DictionaryRoute extends GoRouteData with $DictionaryRoute {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DictionaryPage();
}

@immutable
class ProfileRoute extends GoRouteData with $ProfileRoute {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProfilePage();
}

@immutable
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsPage();
}

const String rootLocation = '/';

GoRouter createAppRouter({String initialLocation = rootLocation}) => GoRouter(
  routes: $appRoutes,
  initialLocation: initialLocation,
  redirect: (context, state) =>
      state.uri.path == rootLocation ? const LearnRoute().location : null,
);
