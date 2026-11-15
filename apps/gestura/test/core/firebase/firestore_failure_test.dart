import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/firebase/firestore_failure.dart';
import 'package:gestura_core/gestura_core.dart';

FirebaseException _error(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

void main() {
  test('turns Firestore codes into failures the learner understands', () {
    const expected = {
      'unavailable': NetworkFailure(),
      'deadline-exceeded': NetworkFailure(),
      'permission-denied': PermissionDeniedFailure(),
      'unauthenticated': PermissionDeniedFailure(),
      'not-found': NotFoundFailure(),
      'resource-exhausted': StorageFullFailure(),
    };

    for (final MapEntry(key: code, value: failure) in expected.entries) {
      expect(firestoreFailure(_error(code)), failure, reason: code);
    }
  });

  test('keeps anything else as an unexpected failure', () {
    final internal = _error('internal');
    final other = StateError('broken');

    expect(firestoreFailure(internal), UnexpectedFailure(internal));
    expect(firestoreFailure(other), UnexpectedFailure(other));
  });
}
