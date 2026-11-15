import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/app_policy/data/remote_config_policy.dart';
import 'package:gestura/features/app_policy/domain/app_policy.dart';
import 'package:mocktail/mocktail.dart';

class _MockConfig extends Mock implements FirebaseRemoteConfig;

void main() {
  late _MockConfig config;
  late StreamController<RemoteConfigUpdate> updates;
  var minBuild = 0;
  var maintenance = false;

  setUpAll(
    () => registerFallbackValue(
      RemoteConfigSettings(
        fetchTimeout: Duration.zero,
        minimumFetchInterval: Duration.zero,
      ),
    ),
  );

  setUp(() {
    config = _MockConfig();
    updates = StreamController<RemoteConfigUpdate>();
    minBuild = 0;
    maintenance = false;
    when(() => config.setConfigSettings(any())).thenAnswer((_) async {});
    when(() => config.setDefaults(any())).thenAnswer((_) async {});
    when(() => config.onConfigUpdated).thenAnswer((_) => updates.stream);
    when(config.fetchAndActivate).thenAnswer((_) async => true);
    when(config.activate).thenAnswer((_) async => true);
    when(() => config.getInt(RemoteConfigPolicy.minBuildKey))
        .thenAnswer((_) => minBuild);
    when(() => config.getBool(RemoteConfigPolicy.maintenanceKey))
        .thenAnswer((_) => maintenance);
  });

  test('fetches once, then follows live updates', () async {
    final policy = RemoteConfigPolicy(config);
    final seen = <AppPolicy>[];
    policy
      ..watch().listen(seen.add)
      ..watch();
    await pumpEventQueue();

    minBuild = 7;
    updates.add(RemoteConfigUpdate({'min_build'}));
    await pumpEventQueue();

    expect(seen, [AppPolicy.open, const AppPolicy(minBuild: 7)]);
    verify(() => config.setDefaults(any())).called(1);
    verify(config.fetchAndActivate).called(1);
    await policy.dispose();
  });

  test('keeps the last policy when the network or config fails', () async {
    when(config.fetchAndActivate).thenThrow(Exception('offline'));
    when(config.activate).thenThrow(Exception('broken'));
    final policy = RemoteConfigPolicy(config);
    final seen = <AppPolicy>[];
    policy.watch().listen(seen.add);
    await pumpEventQueue();
    updates
      ..add(RemoteConfigUpdate({'maintenance'}))
      ..addError(Exception('stream'));
    await pumpEventQueue();

    expect(seen, isEmpty);
    expect(policy.current, AppPolicy.open);
    await policy.dispose();
  });

  test('stays usable when settings cannot be applied', () async {
    when(() => config.setConfigSettings(any())).thenThrow(Exception('no'));
    maintenance = true;
    final policy = RemoteConfigPolicy(config)..watch();
    await pumpEventQueue();

    verifyNever(config.fetchAndActivate);
    expect(policy.current, const AppPolicy(maintenance: true));
    await policy.dispose();
  });
}
