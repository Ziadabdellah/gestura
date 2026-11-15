import 'package:meta/meta.dart';

@immutable
final class AppPolicy {
  const new({this.minBuild = 0, this.maintenance = false});

  static const AppPolicy open = AppPolicy();

  final int minBuild;
  final bool maintenance;

  AppStatus statusFor(String buildNumber) {
    if (maintenance) return AppStatus.maintenance;
    final build = int.tryParse(buildNumber);
    if (build != null && build < minBuild) return AppStatus.needsUpdate;
    return AppStatus.open;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPolicy &&
          other.minBuild == minBuild &&
          other.maintenance == maintenance;

  @override
  int get hashCode => Object.hash(minBuild, maintenance);
}

enum AppStatus { open, needsUpdate, maintenance }

abstract interface class AppPolicySource {
  AppPolicy get current;

  Stream<AppPolicy> watch();

  Future<void> refresh();
}
