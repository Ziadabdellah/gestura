import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/gestura_app.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/config/app_info.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'fake_content_repository.dart';
import 'fake_progress_repository.dart';
import 'fake_settings_repository.dart';
import 'fake_video_player_platform.dart';

const AppSettings englishLight = AppSettings(
  language: AppLanguage.english,
  theme: AppThemePreference.light,
);

const AppInfo testAppInfo = AppInfo(version: '1.0.0', buildNumber: '7');

const Size phoneSize = Size(360, 780);
const Size tabletSize = Size(800, 1280);

FakeVideoPlayerPlatform get fakeVideo =>
    VideoPlayerPlatform.instance as FakeVideoPlayerPlatform;

Future<void> registerFakes({
  ContentRepository? content,
  ProgressRepository? progress,
}) async {
  VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  await getIt.reset();
  getIt
    ..registerSingleton<ContentRepository>(content ?? FakeContentRepository())
    ..registerSingleton<ProgressRepository>(
      progress ?? FakeProgressRepository(),
    )
    ..registerSingleton<AppInfo>(testAppInfo);
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
    String initialLocation = rootLocation,
    Size surfaceSize = phoneSize,
    double textScale = 1,
    ContentRepository? content,
    ProgressRepository? progress,
  }) async {
    view
      ..physicalSize = surfaceSize * 3
      ..devicePixelRatio = 3;
    platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(view.reset);
    addTearDown(platformDispatcher.clearTextScaleFactorTestValue);
    await registerFakes(content: content, progress: progress);
    addTearDown(getIt.reset);

    final repository = FakeSettingsRepository(settings);
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
