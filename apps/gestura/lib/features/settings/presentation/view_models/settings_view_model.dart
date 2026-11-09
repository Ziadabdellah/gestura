import 'package:gestura/di/injection.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/domain/settings_repository.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_state.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_view_model.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) => getIt<SettingsRepository>();

@Riverpod(keepAlive: true)
class SettingsViewModel extends _$SettingsViewModel {
  @override
  SettingsState build() =>
      SettingsReady(ref.watch(settingsRepositoryProvider).load());

  Future<void> setLanguage(AppLanguage language) =>
      _update(state.settings.copyWith(language: language));

  Future<void> setTheme(AppThemePreference theme) =>
      _update(state.settings.copyWith(theme: theme));

  Future<void> setReduceMotion({required bool enabled}) =>
      _update(state.settings.copyWith(reduceMotion: enabled));

  Future<void> _update(AppSettings next) async {
    final previous = state.settings;
    if (next == previous) return;
    state = SettingsReady(next);
    final result = await ref.read(settingsRepositoryProvider).save(next);
    if (!ref.mounted) return;
    if (result case Err(:final failure)) {
      state = SettingsSaveFailed(previous, failure);
    }
  }
}
