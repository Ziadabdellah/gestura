import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';

void main() {
  test('every screen has a stable address for deep links', () {
    expect(const HomeRoute().location, '/');
    expect(const SettingsRoute().location, '/settings');
  });

  test('the router starts where it is told', () {
    final router = createAppRouter(initialLocation: '/settings');
    addTearDown(router.dispose);

    expect(router.routeInformationProvider.value.uri.path, '/settings');
  });
}
