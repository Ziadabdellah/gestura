import 'dart:async';

import 'package:gestura/features/app_policy/domain/app_policy.dart';

class FakePolicySource implements AppPolicySource {
  new([this.current = AppPolicy.open]);

  @override
  AppPolicy current;
  int refreshes = 0;
  final StreamController<AppPolicy> _changes = StreamController.broadcast();

  void publish(AppPolicy policy) {
    current = policy;
    _changes.add(policy);
  }

  @override
  Stream<AppPolicy> watch() => _changes.stream;

  @override
  Future<void> refresh() async => refreshes++;
}
