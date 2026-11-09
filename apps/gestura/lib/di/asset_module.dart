import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AssetModule {
  @lazySingleton
  AssetBundle get assetBundle => rootBundle;
}
