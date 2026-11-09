import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';

import '../../helpers/fake_settings_repository.dart';
import '../../helpers/pump_app.dart';

const Size _phone = Size(360, 640);

void main() {
  unawaited(
    goldenTest(
      'Home page in English and Arabic, light and dark',
      fileName: 'home_page',
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          for (final language in [AppLanguage.english, AppLanguage.arabic])
            for (final theme in [
              AppThemePreference.light,
              AppThemePreference.dark,
            ])
              GoldenTestScenario(
                name: '${language.code} ${theme.name}',
                child: SizedBox.fromSize(
                  size: _phone,
                  child: MediaQuery(
                    data: const MediaQueryData(size: _phone),
                    child: appUnderTest(
                      repository: FakeSettingsRepository(
                        AppSettings(language: language, theme: theme),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}
