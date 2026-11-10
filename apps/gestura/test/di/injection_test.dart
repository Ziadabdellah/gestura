import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/config/app_info.dart';
import 'package:gestura/core/database/app_database.dart';
import 'package:gestura/core/errors/error_reporter.dart';
import 'package:gestura/core/errors/logging_error_reporter.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/data/bundled_content_repository.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/progress/data/drift_progress_repository.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/settings/data/shared_preferences_settings_repository.dart';
import 'package:gestura/features/settings/domain/settings_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  new(this.directory);

  final Directory directory;

  @override
  Future<String?> getApplicationDocumentsPath() async => directory.path;

  @override
  Future<String?> getTemporaryPath() async => directory.path;
}

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('gestura_di');
    PathProviderPlatform.instance = _FakePathProvider(directory);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    PackageInfo.setMockInitialValues(
      appName: 'Gestura',
      packageName: 'app.gestura.com',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  tearDown(() => directory.delete(recursive: true));

  for (final flavor in Flavor.values) {
    test('wires the ${flavor.name} environment', () async {
      final container = GetIt.asNewInstance();
      addTearDown(container.reset);

      await configureDependencies(
        AppConfig(flavor: flavor),
        container: container,
      );

      expect(container<AppConfig>().flavor, flavor);
      expect(container<SharedPreferencesWithCache>(), isNotNull);
      expect(
        container<SettingsRepository>(),
        isA<SharedPreferencesSettingsRepository>(),
      );
      expect(container<ErrorReporter>(), isA<LoggingErrorReporter>());
      expect(container<AssetBundle>(), same(rootBundle));
      expect(container<ContentRepository>(), isA<BundledContentRepository>());
      expect(
        container<AppInfo>(),
        const AppInfo(version: '0.1.0', buildNumber: '1'),
      );
      expect(container<ProgressRepository>(), isA<DriftProgressRepository>());
    });
  }

  test(
    'keeps the database in the app documents folder and closes it',
    () async {
      final container = GetIt.asNewInstance();
      await configureDependencies(
        const AppConfig(flavor: Flavor.dev),
        container: container,
      );
      final database = container<AppDatabase>();

      await database.customSelect('SELECT 1').get();
      await container.reset();

      expect(
        File('${directory.path}/${AppDatabase.fileName}.sqlite').existsSync(),
        isTrue,
      );
      expect(database.customSelect('SELECT 1').get(), throwsA(anything));
    },
  );

  test('uses the global container by default', () async {
    addTearDown(getIt.reset);

    await configureDependencies(const AppConfig(flavor: Flavor.dev));

    expect(getIt<AppConfig>().flavor, Flavor.dev);
    expect(getIt.isRegistered<SettingsRepository>(), isTrue);
  });
}
