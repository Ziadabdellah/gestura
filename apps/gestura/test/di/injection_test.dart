import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/config/app_info.dart';
import 'package:gestura/core/cloud/cloud_set.dart';
import 'package:gestura/core/cloud/user_documents.dart';
import 'package:gestura/core/database/app_database.dart';
import 'package:gestura/core/errors/crashlytics_error_reporter.dart';
import 'package:gestura/core/errors/error_reporter.dart';
import 'package:gestura/core/errors/logging_error_reporter.dart';
import 'package:gestura/core/media/media_cache.dart';
import 'package:gestura/core/share/link_sharer.dart';
import 'package:gestura/core/telemetry/firebase_telemetry.dart';
import 'package:gestura/core/telemetry/local_telemetry.dart';
import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/app_policy/data/remote_config_policy.dart';
import 'package:gestura/features/app_policy/domain/app_policy.dart';
import 'package:gestura/features/auth/data/firebase_auth_repository.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/content/data/bundled_content_repository.dart';
import 'package:gestura/features/content/data/remote_content_repository.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/learner/learner_cloud.dart';
import 'package:gestura/features/learner/learner_sync.dart';
import 'package:gestura/features/progress/data/drift_progress_repository.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/reminders/data/local_reminders.dart';
import 'package:gestura/features/reminders/domain/reminders.dart';
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

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

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
      expect(
        container<ErrorReporter>(),
        AppConfig(flavor: flavor).isProd
            ? isA<CrashlyticsErrorReporter>()
            : isA<LoggingErrorReporter>(),
      );
      expect(
        container<Telemetry>(),
        AppConfig(flavor: flavor).isProd
            ? isA<FirebaseTelemetry>()
            : isA<LocalTelemetry>(),
      );
      expect(
        container.isRegistered<FirebaseCrashlytics>(),
        AppConfig(flavor: flavor).isProd,
      );
      expect(
        container<LearnerCloud>().progress,
        AppConfig(flavor: flavor).isProd
            ? isA<FirestoreCloudSet<LessonProgress>>()
            : isA<DeviceOnlySet<LessonProgress>>(),
      );
      expect(container<UserDocuments>(), isA<FirestoreUserDocuments>());
      expect(container<Reminders>(), isA<LocalReminders>());
      expect(
        container<AppPolicySource>(),
        AppConfig(flavor: flavor).isProd
            ? isA<RemoteConfigPolicy>()
            : isA<OpenPolicy>(),
      );
      expect(container<LinkSharer>(), isA<SystemLinkSharer>());
      expect(
        container<FirebaseFirestore>().settings.persistenceEnabled,
        isFalse,
      );
      expect(container<LearnerSync>(), isNotNull);
      expect(container<AssetBundle>(), same(rootBundle));
      expect(
        container<ContentRepository>(),
        AppConfig(flavor: flavor).isProd
            ? isA<RemoteContentRepository>()
            : isA<BundledContentRepository>(),
      );
      expect(container<MediaCache>(), isA<DiskMediaCache>());
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

  test('wires Firebase Auth once Firebase is ready', () async {
    final container = GetIt.asNewInstance();
    addTearDown(container.reset);

    await configureDependencies(
      const AppConfig(flavor: Flavor.dev),
      container: container,
    );

    expect(container<FirebaseAuth>(), same(FirebaseAuth.instance));
    expect(container<AuthRepository>(), isA<FirebaseAuthRepository>());
  });

  test('uses the global container by default', () async {
    addTearDown(getIt.reset);

    await configureDependencies(const AppConfig(flavor: Flavor.dev));

    expect(getIt<AppConfig>().flavor, Flavor.dev);
    expect(getIt.isRegistered<SettingsRepository>(), isTrue);
  });
}
