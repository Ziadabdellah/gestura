import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DriftDatabase(include: {'tables.drift'})
class AppDatabase extends _$AppDatabase {
  new([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: fileName));

  static const String fileName = 'gestura';

  @override
  int get schemaVersion => 1;
}
