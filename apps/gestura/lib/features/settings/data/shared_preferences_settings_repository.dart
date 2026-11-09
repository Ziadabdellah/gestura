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
  );

  @override
  Future<Result<void>> save(AppSettings settings) => Result.guard(() async {
    final languageCode = settings.language.code;
    await (languageCode == null
        ? _preferences.remove(PreferenceKeys.language)
        : _preferences.setString(PreferenceKeys.language, languageCode));
    await _preferences.setString(PreferenceKeys.theme, settings.theme.name);
    await _preferences.setBool(
      PreferenceKeys.reduceMotion,
      settings.reduceMotion,
    );
  }, onError: (error, stackTrace) => UnexpectedFailure(error));

  T? _read<T>(String key) => switch (_preferences.get(key)) {
    final T value => value,
    _ => null,
  };
}
