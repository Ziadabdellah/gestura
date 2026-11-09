import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/domain/settings_repository.dart';
import 'package:gestura_core/gestura_core.dart';

class FakeSettingsRepository implements SettingsRepository {
  new([this.stored = AppSettings.defaults]);

  AppSettings stored;
  Failure? failure;
  final List<AppSettings> saved = [];

  @override
  AppSettings load() => stored;

  @override
  Future<Result<void>> save(AppSettings settings) async {
    if (failure case final Failure failure) return Err(failure);
    saved.add(settings);
    stored = settings;
    return const Ok(null);
  }
}
