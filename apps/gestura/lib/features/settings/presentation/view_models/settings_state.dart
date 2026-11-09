import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:meta/meta.dart';

@immutable
sealed class SettingsState {
  const new(this.settings);

  final AppSettings settings;
}

final class SettingsReady extends SettingsState {
  const new(super.settings);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsReady && other.settings == settings;

  @override
  int get hashCode => Object.hash(SettingsReady, settings);
}

final class SettingsSaveFailed extends SettingsState {
  const new(super.settings, this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsSaveFailed &&
          other.settings == settings &&
          other.failure == failure;

  @override
  int get hashCode => Object.hash(SettingsSaveFailed, settings, failure);
}
