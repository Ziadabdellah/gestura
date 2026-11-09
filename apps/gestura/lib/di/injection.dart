import 'package:gestura/config/app_config.dart';
import 'package:gestura/di/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit()
Future<GetIt> configureDependencies(AppConfig config, {GetIt? container}) {
  final target = (container ?? getIt)..registerSingleton<AppConfig>(config);
  return target.init(environment: config.flavor.name);
}
