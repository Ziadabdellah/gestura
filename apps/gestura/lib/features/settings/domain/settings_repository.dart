import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';

abstract interface class SettingsRepository {
  AppSettings load();

  Future<Result<void>> save(AppSettings settings);
}
