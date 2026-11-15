import 'package:firebase_core/firebase_core.dart';
import 'package:gestura_core/gestura_core.dart';

Failure firestoreFailure(Object error) => switch (error) {
  FirebaseException(code: 'unavailable' || 'deadline-exceeded') =>
    const NetworkFailure(),
  FirebaseException(code: 'permission-denied' || 'unauthenticated') =>
    const PermissionDeniedFailure(),
  FirebaseException(code: 'not-found') => const NotFoundFailure(),
  FirebaseException(code: 'resource-exhausted') => const StorageFullFailure(),
  _ => UnexpectedFailure(error),
};
