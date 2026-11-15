import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/app_policy/data/remote_config_policy.dart';
import 'package:gestura/features/app_policy/domain/app_policy.dart';
import 'package:gestura/features/app_policy/presentation/policy_gate.dart';

void main() {
  test('blocks old builds and every build during maintenance', () {
    const policy = AppPolicy(minBuild: 5);
    expect(policy.statusFor('4'), AppStatus.needsUpdate);
    expect(policy.statusFor('5'), AppStatus.open);
    expect(policy.statusFor(''), AppStatus.open);
    expect(
      const AppPolicy(maintenance: true).statusFor('9'),
      AppStatus.maintenance,
    );
    expect(const AppPolicy(minBuild: 5).hashCode, policy.hashCode);
    expect(policy, isNot(AppPolicy.open));
  });

  test('sends Android to the Play Store and others to the site', () {
    expect(
      storeLink(TargetPlatform.android).toString(),
      'https://play.google.com/store/apps/details?id=app.gestura.com',
    );
    expect(
      storeLink(TargetPlatform.iOS).toString(),
      'https://gestura-prod.web.app',
    );
  });

  test('dev and staging stay open', () async {
    const policy = OpenPolicy();
    expect(policy.current, AppPolicy.open);
    expect(await policy.watch().isEmpty, isTrue);
    await policy.refresh();
  });
}
