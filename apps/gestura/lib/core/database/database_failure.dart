import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:gestura_core/gestura_core.dart';

const int sqliteFull = 13;
const int _primaryResultCodeMask = 0xff;

Failure databaseFailure(Object error) => switch (error) {
  DriftRemoteException(:final remoteCause) => databaseFailure(remoteCause),
  SqliteException(:final extendedResultCode)
      when extendedResultCode & _primaryResultCodeMask == sqliteFull =>
    const StorageFullFailure(),
  _ => UnexpectedFailure(error),
};
