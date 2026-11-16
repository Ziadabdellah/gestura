import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/gestura_app.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/config/app_info.dart';
import 'package:gestura/core/media/media_cache.dart';
import 'package:gestura/core/share/link_sharer.dart';
import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/admin/data/content_store.dart';
import 'package:gestura/features/admin/domain/admin_access.dart';
import 'package:gestura/features/app_policy/domain/app_policy.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/learner/learner_cloud.dart';
import 'package:gestura/features/learner/learner_data.dart';
import 'package:gestura/features/learner/learner_export.dart';
import 'package:gestura/features/learner/learner_sync.dart';
import 'package:gestura/features/practice/domain/self_camera.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/reminders/domain/reminders.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
import 'package:gestura/features/saved/domain/saved_signs_repository.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/domain/settings_repository.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'fake_activity_repository.dart';
import 'fake_admin.dart';
import 'fake_auth_repository.dart';
import 'fake_content_repository.dart';
import 'fake_learner_cloud.dart';
import 'fake_link_sharer.dart';
import 'fake_media_cache.dart';
import 'fake_policy_source.dart';
import 'fake_progress_repository.dart';
import 'fake_reminders.dart';
import 'fake_review_repository.dart';
import 'fake_saved_signs_repository.dart';
import 'fake_self_camera.dart';
import 'fake_settings_repository.dart';
import 'fake_telemetry.dart';
import 'fake_url_launcher.dart';
import 'fake_video_player_platform.dart';

const AppSettings englishLight = AppSettings(
  language: AppLanguage.english,
  theme: AppThemePreference.light,
  onboardingComplete: true,
);

const AppInfo testAppInfo = AppInfo(version: '1.0.0', buildNumber: '7');

const String learnLocation = '/learn';

const Size phoneSize = Size(360, 780);

final DateTime testNow = DateTime(2026, 11, 15, 12);
const Size tabletSize = Size(800, 1280);

FakeUrlLauncher get fakeLinks =>
    UrlLauncherPlatform.instance as FakeUrlLauncher;

FakeVideoPlayerPlatform get fakeVideo =>
    VideoPlayerPlatform.instance as FakeVideoPlayerPlatform;

Future<void> registerFakes({
  ContentRepository? content,
  ProgressRepository? progress,
  AuthRepository? auth,
  Telemetry? telemetry,
  LearnerCloud? cloud,
  ReviewRepository? reviews,
  ActivityRepository? activity,
  SavedSignsRepository? saved,
  Reminders? reminders,
  AppPolicySource? policy,
  SelfCamera? camera,
  AdminAccess? admin,
  ContentStore? store,
}) async {
  VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  UrlLauncherPlatform.instance = FakeUrlLauncher();
  await getIt.reset();
  getIt
    ..registerSingleton<ContentRepository>(content ?? FakeContentRepository())
    ..registerSingleton<ProgressRepository>(
      progress ?? FakeProgressRepository(),
    )
    ..registerSingleton<AuthRepository>(auth ?? FakeAuthRepository())
    ..registerSingleton<Telemetry>(telemetry ?? FakeTelemetry())
    ..registerSingleton<LearnerCloud>(cloud ?? FakeLearnerCloud().cloud)
    ..registerLazySingleton(
      () => LearnerSync(getIt(), getIt(), getIt(), getIt(), getIt()),
      dispose: (sync) => sync.stop(),
    )
    ..registerSingleton<MediaCache>(FakeMediaCache('assets/content/demo/media'))
    ..registerSingleton<ReviewRepository>(reviews ?? FakeReviewRepository())
    ..registerSingleton<ActivityRepository>(
      activity ?? FakeActivityRepository(),
    )
    ..registerSingleton<SavedSignsRepository>(
      saved ?? FakeSavedSignsRepository(),
    )
    ..registerLazySingleton(
      () => LearnerData(getIt(), getIt(), getIt(), getIt()),
    )
    ..registerSingleton<LinkSharer>(FakeLinkSharer())
    ..registerSingleton<SelfCamera>(camera ?? FakeSelfCamera())
    ..registerSingleton<AppPolicySource>(policy ?? FakePolicySource())
    ..registerSingleton<Reminders>(reminders ?? FakeReminders())
    ..registerLazySingleton(
      () => LearnerExport(
        getIt(),
        getIt(),
        getIt(),
        getIt(),
        getIt(),
        directory: () async => Directory.systemTemp,
      ),
    )
    ..registerSingleton<Clock>(Clock.fixed(testNow))
    ..registerSingleton<AppInfo>(testAppInfo)
    ..registerSingleton<AdminAccess>(admin ?? FakeAdminAccess())
    ..registerSingleton<ContentStore>(store ?? FakeContentStore());
}

Widget appUnderTest({
  required FakeSettingsRepository repository,
  Flavor flavor = Flavor.prod,
  String initialLocation = rootLocation,
}) => ProviderScope(
  overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
  child: GesturaApp(
    config: AppConfig(flavor: flavor),
    initialLocation: initialLocation,
  ),
);

extension PumpApp on WidgetTester {
  Future<FakeSettingsRepository> pumpApp({
    AppSettings settings = englishLight,
    Flavor flavor = Flavor.prod,
    String initialLocation = learnLocation,
    Size surfaceSize = phoneSize,
    double textScale = 1,
    ContentRepository? content,
    ProgressRepository? progress,
    AuthRepository? auth,
    Telemetry? telemetry,
    LearnerCloud? cloud,
    ReviewRepository? reviews,
    ActivityRepository? activity,
    SavedSignsRepository? saved,
    Reminders? reminders,
    AppPolicySource? policy,
    SelfCamera? camera,
    AdminAccess? admin,
    ContentStore? store,
  }) async {
    view
      ..physicalSize = surfaceSize * 3
      ..devicePixelRatio = 3;
    platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(view.reset);
    addTearDown(platformDispatcher.clearTextScaleFactorTestValue);
    await registerFakes(
      content: content,
      progress: progress,
      auth: auth,
      telemetry: telemetry,
      cloud: cloud,
      reviews: reviews,
      activity: activity,
      saved: saved,
      reminders: reminders,
      policy: policy,
      camera: camera,
      admin: admin,
      store: store,
    );
    addTearDown(getIt.reset);

    final repository = FakeSettingsRepository(settings);
    getIt.registerSingleton<SettingsRepository>(repository);
    await pumpWidget(
      appUnderTest(
        repository: repository,
        flavor: flavor,
        initialLocation: initialLocation,
      ),
    );
    await pumpAndSettle();
    return repository;
  }

  Future<void> expectAccessible() async {
    await expectLater(this, meetsGuideline(androidTapTargetGuideline));
    await expectLater(this, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(this, meetsGuideline(textContrastGuideline));
  }

  Future<void> tapDestination(String label) async {
    await tap(
      find.descendant(
        of: find.byWidgetPredicate(
          (widget) => widget is NavigationBar || widget is NavigationRail,
        ),
        matching: find.text(label),
      ),
    );
    await pumpAndSettle();
  }
}
