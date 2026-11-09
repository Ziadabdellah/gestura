import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/core/errors/error_reporter.dart';
import 'package:gestura/core/errors/logging_error_reporter.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/data/bundled_content_repository.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/settings/data/shared_preferences_settings_repository.dart';
import 'package:gestura/features/settings/domain/settings_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

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
    });
  }

  test('uses the global container by default', () async {
    addTearDown(getIt.reset);

    await configureDependencies(const AppConfig(flavor: Flavor.dev));

    expect(getIt<AppConfig>().flavor, Flavor.dev);
    expect(getIt.isRegistered<SettingsRepository>(), isTrue);
  });
}
