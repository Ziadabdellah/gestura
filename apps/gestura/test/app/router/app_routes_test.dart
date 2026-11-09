import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('every screen has a stable address for deep links', () {
    expect(const LearnRoute().location, '/learn');
    expect(const DictionaryRoute().location, '/dictionary');
    expect(const ProfileRoute().location, '/profile');
    expect(const SettingsRoute().location, '/profile/settings');
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
    final router = createAppRouter(initialLocation: '/dictionary');
    addTearDown(router.dispose);

    expect(router.routeInformationProvider.value.uri.path, '/dictionary');
  });
}
