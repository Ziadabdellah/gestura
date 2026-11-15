import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/storage/preference_keys.dart';
import 'package:gestura/features/settings/data/shared_preferences_settings_repository.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

base class _FailingPreferences extends InMemorySharedPreferencesAsync {
  new() : super.empty();

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) => throw StateError('disk is full');
}

Future<SharedPreferencesWithCache> _preferences() =>
    SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: PreferenceKeys.all,
      ),
    );

Future<SharedPreferencesSettingsRepository> _repository() async =>
    SharedPreferencesSettingsRepository(await _preferences());

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test('loads the defaults when nothing is stored', () async {
    final repository = await _repository();

    expect(repository.load(), AppSettings.defaults);
  });

  test('keeps saved settings across app restarts', () async {
    const settings = AppSettings(
      language: AppLanguage.arabic,
      theme: AppThemePreference.dark,
      reduceMotion: true,
    );

    final result = await (await _repository()).save(settings);
    final afterRestart = await _repository();

    expect(result, const Ok<void>(null));
    expect(afterRestart.load(), settings);
  });

  test('keeps the onboarding choices and consents', () async {
    const settings = AppSettings(
      signLanguage: 'demo',
      dailyGoal: DailyGoal.fifteen,
      dominantHand: DominantHand.left,
      analyticsConsent: true,
      crashReportsConsent: true,
      onboardingComplete: true,
    );

    await (await _repository()).save(settings);

    expect((await _repository()).load(), settings);
    expect(
      (await _preferences()).getInt(PreferenceKeys.dailyGoal),
      DailyGoal.fifteen.minutes,
    );
  });

  test('forgets the language when it goes back to the system one', () async {
    final repository = await _repository();
    await repository.save(const AppSettings(language: AppLanguage.german));

    await repository.save(AppSettings.defaults);

    expect(
      (await _preferences()).containsKey(PreferenceKeys.language),
      isFalse,
    );
    expect(repository.load().language, AppLanguage.system);
  });

  test('falls back to defaults for unknown stored values', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          PreferenceKeys.language: 'xx',
          PreferenceKeys.theme: 'neon',
          PreferenceKeys.dailyGoal: 12,
          PreferenceKeys.dominantHand: 'both',
        });

    expect((await _repository()).load(), AppSettings.defaults);
  });

  test('falls back to defaults for values of the wrong type', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          PreferenceKeys.language: 42,
          PreferenceKeys.theme: true,
          PreferenceKeys.reduceMotion: 'yes',
          PreferenceKeys.signLanguage: 7,
          PreferenceKeys.dailyGoal: '10',
          PreferenceKeys.dominantHand: false,
          PreferenceKeys.analyticsConsent: 'true',
          PreferenceKeys.crashReportsConsent: 1,
          PreferenceKeys.onboardingComplete: 'done',
        });

    expect((await _repository()).load(), AppSettings.defaults);
  });

  test('reports a failure instead of throwing when saving fails', () async {
    SharedPreferencesAsyncPlatform.instance = _FailingPreferences();
    final repository = await _repository();

    final result = await repository.save(
      const AppSettings(theme: AppThemePreference.dark),
    );

    expect(result, isA<Err<void>>());
    expect(
      result.failureOrNull,
      isA<UnexpectedFailure>().having(
        (failure) => failure.error,
        'error',
        isA<StateError>(),
      ),
    );
  });
}
