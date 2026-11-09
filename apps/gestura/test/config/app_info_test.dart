import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/config/app_info.dart';

void main() {
  test('shows the build number next to the version', () {
    expect(
      const AppInfo(version: '1.2.0', buildNumber: '14').label,
      '1.2.0 (14)',
    );
  });

  test('shows only the version when there is no build number', () {
    expect(const AppInfo(version: '1.2.0', buildNumber: '').label, '1.2.0');
  });

  test('compares by value', () {
    final info = AppInfo(version: '1.0.0', buildNumber: '1'.padLeft(1));

    expect(info, const AppInfo(version: '1.0.0', buildNumber: '1'));
    expect(
      info.hashCode,
      const AppInfo(version: '1.0.0', buildNumber: '1').hashCode,
    );
    expect(info, isNot(const AppInfo(version: '1.0.0', buildNumber: '2')));
  });
}
