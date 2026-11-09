import 'package:meta/meta.dart';

@immutable
final class AppInfo {
  const new({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  String get label => buildNumber.isEmpty ? version : '$version ($buildNumber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfo &&
          other.version == version &&
          other.buildNumber == buildNumber;

  @override
  int get hashCode => Object.hash(version, buildNumber);
}
