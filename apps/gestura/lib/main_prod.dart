import 'package:gestura/bootstrap.dart';
import 'package:gestura/config/app_config.dart';

Future<void> main() => bootstrap(const AppConfig(flavor: Flavor.prod));
