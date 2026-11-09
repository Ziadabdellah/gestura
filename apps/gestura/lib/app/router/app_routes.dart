import 'package:flutter/widgets.dart';
import 'package:gestura/app/view/home_page.dart';
import 'package:gestura/features/settings/presentation/pages/settings_page.dart';
import 'package:go_router/go_router.dart';

part 'app_routes.g.dart';

@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [TypedGoRoute<SettingsRoute>(path: 'settings')],
)
@immutable
class HomeRoute extends GoRouteData with $HomeRoute {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

@immutable
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsPage();
}

GoRouter createAppRouter({String initialLocation = '/'}) =>
    GoRouter(routes: $appRoutes, initialLocation: initialLocation);
