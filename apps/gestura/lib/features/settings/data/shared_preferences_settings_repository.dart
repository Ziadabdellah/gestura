import 'package:gestura/core/storage/preference_keys.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/domain/settings_repository.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@LazySingleton(as: SettingsRepository)
final class SharedPreferencesSettingsRepository implements SettingsRepository {
  const new(this._preferences);

  final SharedPreferencesWithCache _preferences;

  @override
  AppSettings load() => AppSettings(
    language: AppLanguage.fromCode(_read<String>(PreferenceKeys.language)),
    theme: AppThemePreference.fromName(_read<String>(PreferenceKeys.theme)),
    reduceMotion: _read<bool>(PreferenceKeys.reduceMotion) ?? false,
    signLanguage: _read<String>(PreferenceKeys.signLanguage),
    dailyGoal: DailyGoal.fromMinutes(_read<int>(PreferenceKeys.dailyGoal)),
    dominantHand: DominantHand.fromName(
      _read<String>(PreferenceKeys.dominantHand),
    ),
    analyticsConsent: _read<bool>(PreferenceKeys.analyticsConsent) ?? false,
    crashReportsConsent:
        _read<bool>(PreferenceKeys.crashReportsConsent) ?? false,
    onboardingComplete: _read<bool>(PreferenceKeys.onboardingComplete) ?? false,
  );

  @override
  Future<Result<void>> save(AppSettings settings) => Result.guard(() async {
    await _writeString(PreferenceKeys.language, settings.language.code);
    await _preferences.setString(PreferenceKeys.theme, settings.theme.name);
    await _preferences.setBool(
      PreferenceKeys.reduceMotion,
      settings.reduceMotion,
    );
    await _writeString(PreferenceKeys.signLanguage, settings.signLanguage);
    await _preferences.setInt(
      PreferenceKeys.dailyGoal,
      settings.dailyGoal.minutes,
    );
    await _preferences.setString(
      PreferenceKeys.dominantHand,
      settings.dominantHand.name,
    );
    await _preferences.setBool(
      PreferenceKeys.analyticsConsent,
      settings.analyticsConsent,
    );
    await _preferences.setBool(
      PreferenceKeys.crashReportsConsent,
      settings.crashReportsConsent,
    );
    await _preferences.setBool(
      PreferenceKeys.onboardingComplete,
      settings.onboardingComplete,
    );
  }, onError: (error, stackTrace) => UnexpectedFailure(error));

  Future<void> _writeString(String key, String? value) => value == null
      ? _preferences.remove(key)
      : _preferences.setString(key, value);

  T? _read<T>(String key) => switch (_preferences.get(key)) {
    final T value => value,
    _ => null,
  };
}
