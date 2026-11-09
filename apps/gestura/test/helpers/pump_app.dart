import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/gestura_app.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';

import 'fake_settings_repository.dart';

const AppSettings englishLight = AppSettings(
  language: AppLanguage.english,
  theme: AppThemePreference.light,
);

Widget appUnderTest({
  required FakeSettingsRepository repository,
  Flavor flavor = Flavor.prod,
  String initialLocation = '/',
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
    String initialLocation = '/',
    Size surfaceSize = const Size(360, 780),
    double textScale = 1,
  }) async {
    view
      ..physicalSize = surfaceSize * 3
      ..devicePixelRatio = 3;
    platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(view.reset);
    addTearDown(platformDispatcher.clearTextScaleFactorTestValue);

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
}
