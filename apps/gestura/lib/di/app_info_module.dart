import 'package:clock/clock.dart';
import 'package:gestura/config/app_info.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

@module
abstract class AppInfoModule {
  @lazySingleton
  Clock get clock => const Clock();

  @preResolve
  @singleton
  Future<AppInfo> get appInfo async {
    final info = await PackageInfo.fromPlatform();
    return AppInfo(version: info.version, buildNumber: info.buildNumber);
  }
}
