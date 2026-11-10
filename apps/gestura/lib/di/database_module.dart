import 'package:gestura/core/database/app_database.dart';
import 'package:injectable/injectable.dart';

Future<void> closeDatabase(AppDatabase database) => database.close();

@module
abstract class DatabaseModule {
  @LazySingleton(dispose: closeDatabase)
  AppDatabase get database => AppDatabase();
}
