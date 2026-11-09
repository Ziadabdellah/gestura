import 'package:gestura/core/storage/preference_keys.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class StorageModule {
  @preResolve
  @singleton
  Future<SharedPreferencesWithCache> get preferences =>
      SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
          allowList: PreferenceKeys.all,
        ),
      );
}
