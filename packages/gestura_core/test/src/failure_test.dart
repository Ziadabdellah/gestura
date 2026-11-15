import 'package:gestura_core/gestura_core.dart';
import 'package:test/test.dart';

T fresh<T>(T Function() create) => create();

void main() {
  group('Failure', () {
    test('failures of the same type are equal', () {
      expect(fresh(NetworkFailure.new), const NetworkFailure());
      expect(fresh(NotFoundFailure.new), const NotFoundFailure());
      expect(
        fresh(PermissionDeniedFailure.new),
        const PermissionDeniedFailure(),
      );
      expect(fresh(StorageFullFailure.new), const StorageFullFailure());
      expect(fresh(NoContentFailure.new), const NoContentFailure());
      expect(
        fresh(NetworkFailure.new).hashCode,
        const NetworkFailure().hashCode,
      );
    });

    test('failures of different types are not equal', () {
      expect(const NetworkFailure(), isNot(const NotFoundFailure()));
    });

    test('unexpected failures compare their error', () {
      final error = String.fromCharCode(97);

      expect(UnexpectedFailure(error), const UnexpectedFailure('a'));
      expect(
        UnexpectedFailure(error).hashCode,
        const UnexpectedFailure('a').hashCode,
      );
      expect(const UnexpectedFailure('a'), isNot(const UnexpectedFailure('b')));
      expect(const UnexpectedFailure('a'), isNot(const NetworkFailure()));
    });

    test('auth failures compare their problem', () {
      AuthFailure of(AuthProblem problem) => AuthFailure(problem);

      expect(
        of(AuthProblem.emailInUse),
        const AuthFailure(AuthProblem.emailInUse),
      );
      expect(
        of(AuthProblem.emailInUse).hashCode,
        const AuthFailure(AuthProblem.emailInUse).hashCode,
      );
      expect(
        const AuthFailure(AuthProblem.emailInUse),
        isNot(const AuthFailure(AuthProblem.weakPassword)),
      );
      expect(
        const AuthFailure(AuthProblem.weakPassword),
        isNot(const NetworkFailure()),
      );
      expect(
        const AuthFailure(AuthProblem.tooManyRequests).toString(),
        'AuthFailure(tooManyRequests)',
      );
    });

    test('every failure can be handled by an exhaustive switch', () {
      String code(Failure failure) => switch (failure) {
        NetworkFailure() => 'network',
        NotFoundFailure() => 'not-found',
        PermissionDeniedFailure() => 'permission',
        StorageFullFailure() => 'storage',
        NoContentFailure() => 'no-content',
        AuthFailure() => 'auth',
        UnexpectedFailure() => 'unexpected',
      };

      expect(
        [
          const NetworkFailure(),
          const NotFoundFailure(),
          const PermissionDeniedFailure(),
          const StorageFullFailure(),
          const NoContentFailure(),
          const AuthFailure(AuthProblem.unavailable),
          const AuthFailure(AuthProblem.signInAgain),
          const UnexpectedFailure(0),
        ].map(code),
        [
          'network',
          'not-found',
          'permission',
          'storage',
          'no-content',
          'auth',
          'auth',
          'unexpected',
        ],
      );
    });
  });
}
