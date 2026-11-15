import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/domain/settings_repository.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_state.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../../helpers/fake_settings_repository.dart';

class _SlowSettingsRepository implements SettingsRepository {
  final Completer<Result<void>> pending = Completer();

  @override
  AppSettings load() => AppSettings.defaults;

  @override
  Future<Result<void>> save(AppSettings settings) => pending.future;
}

ProviderContainer _containerFor(SettingsRepository repository) =>
    ProviderContainer.test(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
    );

void main() {
  group('SettingsViewModel', () {
    late FakeSettingsRepository repository;
    late ProviderContainer container;

    SettingsViewModel viewModel() =>
        container.read(settingsViewModelProvider.notifier);

    SettingsState state() => container.read(settingsViewModelProvider);

    setUp(() {
      repository = FakeSettingsRepository(
        const AppSettings(language: AppLanguage.english),
      );
      container = _containerFor(repository);
    });

    test('starts from the stored settings', () {
      expect(
        state(),
        const SettingsReady(AppSettings(language: AppLanguage.english)),
      );
    });

    test('changes and saves the language', () async {
      await viewModel().setLanguage(AppLanguage.arabic);

      expect(state().settings.language, AppLanguage.arabic);
      expect(repository.saved.single.language, AppLanguage.arabic);
    });

    test('saves every onboarding choice', () async {
      await viewModel().setSignLanguage('demo');
      await viewModel().setDailyGoal(DailyGoal.five);
      await viewModel().setDominantHand(DominantHand.left);
      await viewModel().setAnalyticsConsent(granted: true);
      await viewModel().setCrashReportsConsent(granted: true);
      await viewModel().completeOnboarding();

      expect(
        state().settings,
        const AppSettings(
          language: AppLanguage.english,
          signLanguage: 'demo',
          dailyGoal: DailyGoal.five,
          dominantHand: DominantHand.left,
          analyticsConsent: true,
          crashReportsConsent: true,
          onboardingComplete: true,
        ),
      );
      expect(repository.saved, hasLength(6));
      expect(repository.stored, state().settings);
    });

    test('changes and saves the theme', () async {
      await viewModel().setTheme(AppThemePreference.dark);

      expect(state(), isA<SettingsReady>());
      expect(state().settings.theme, AppThemePreference.dark);
      expect(repository.stored.theme, AppThemePreference.dark);
    });

    test('changes and saves reduce motion', () async {
      await viewModel().setReduceMotion(enabled: true);

      expect(state().settings.reduceMotion, isTrue);
      expect(repository.stored.reduceMotion, isTrue);
    });

    test('does not save when nothing changes', () async {
      await viewModel().setLanguage(AppLanguage.english);

      expect(repository.saved, isEmpty);
    });

    test('updates the state before the save finishes', () async {
      final slow = _SlowSettingsRepository();
      final slowContainer = _containerFor(slow);
      addTearDown(() => slow.pending.complete(const Ok(null)));

      unawaited(
        slowContainer
            .read(settingsViewModelProvider.notifier)
            .setTheme(AppThemePreference.light),
      );

      expect(
        slowContainer.read(settingsViewModelProvider).settings.theme,
        AppThemePreference.light,
      );
    });

    test('goes back to the previous settings when saving fails', () async {
      const failure = UnexpectedFailure('disk');
      repository.failure = failure;

      await viewModel().setTheme(AppThemePreference.dark);

      expect(
        state(),
        const SettingsSaveFailed(
          AppSettings(language: AppLanguage.english),
          failure,
        ),
      );
    });

    test('clears the failure after a later successful save', () async {
      repository.failure = const UnexpectedFailure('disk');
      await viewModel().setTheme(AppThemePreference.dark);

      repository.failure = null;
      await viewModel().setTheme(AppThemePreference.dark);

      expect(state(), isA<SettingsReady>());
      expect(state().settings.theme, AppThemePreference.dark);
    });

    test('ignores a save that finishes after it is disposed', () async {
      final slow = _SlowSettingsRepository();
      final slowContainer = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(slow)],
      );
      final saving = slowContainer
          .read(settingsViewModelProvider.notifier)
          .setTheme(AppThemePreference.dark);

      slowContainer.dispose();
      slow.pending.complete(const Err(UnexpectedFailure('late')));

      await expectLater(saving, completes);
    });
  });

  test('reads the repository from the DI container by default', () {
    final repository = FakeSettingsRepository();
    getIt.registerSingleton<SettingsRepository>(repository);
    addTearDown(getIt.reset);
    final container = ProviderContainer.test();

    expect(container.read(settingsRepositoryProvider), same(repository));
  });

  group('SettingsState', () {
    test('states compare by value', () {
      const failure = NetworkFailure();
      final settings = AppSettings(reduceMotion: bool.parse('true'));

      expect(
        SettingsReady(settings),
        const SettingsReady(AppSettings(reduceMotion: true)),
      );
      expect(
        SettingsReady(settings).hashCode,
        const SettingsReady(AppSettings(reduceMotion: true)).hashCode,
      );
      expect(
        SettingsSaveFailed(settings, failure),
        const SettingsSaveFailed(AppSettings(reduceMotion: true), failure),
      );
      expect(
        SettingsSaveFailed(settings, failure).hashCode,
        const SettingsSaveFailed(
          AppSettings(reduceMotion: true),
          failure,
        ).hashCode,
      );
      expect(
        SettingsReady(settings),
        isNot(SettingsSaveFailed(settings, failure)),
      );
    });
  });
}
