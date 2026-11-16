import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:gestura/features/app_policy/domain/app_policy.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AppPolicySource)
final class RemoteConfigPolicy implements AppPolicySource {
  new(this._config);

  static const String minBuildKey = 'min_build';
  static const String maintenanceKey = 'maintenance';
  static const Duration fetchTimeout = Duration(seconds: 10);
  static const Duration fetchInterval = Duration(hours: 1);

  final FirebaseRemoteConfig _config;
  final StreamController<AppPolicy> _changes = StreamController.broadcast();
  StreamSubscription<RemoteConfigUpdate>? _updates;
  Future<void>? _ready;

  @override
  AppPolicy get current => AppPolicy(
    minBuild: _config.getInt(minBuildKey),
    maintenance: _config.getBool(maintenanceKey),
  );

  @override
  Stream<AppPolicy> watch() {
    unawaited(_start());
    return _changes.stream;
  }

  Future<void> _start() => _ready ??= () async {
    try {
      await _config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: fetchTimeout,
          minimumFetchInterval: fetchInterval,
        ),
      );
      await _config.setDefaults(const {minBuildKey: 0, maintenanceKey: false});
      _updates = _config.onConfigUpdated.listen(
        (_) => unawaited(_activate()),
        onError: (Object _) {},
      );
    } on Object {
      return;
    }
    await refresh();
  }();

  Future<void> _activate() async {
    try {
      await _config.activate();
    } on Object {
      return;
    }
    _changes.add(current);
  }

  @override
  Future<void> refresh() async {
    try {
      await _config.fetchAndActivate();
    } on Object {
      return;
    }
    _changes.add(current);
  }

  Future<void> dispose() async {
    await _updates?.cancel();
    await _changes.close();
  }
}
