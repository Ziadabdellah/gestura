import 'package:gestura_core/gestura_core.dart';
import 'package:test/test.dart';

T fresh<T>(T Function() create) => create();

void main() {
  group('Result', () {
    test('Ok exposes its value and no failure', () {
      const Result<int> result = Ok(3);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, 3);
      expect(result.failureOrNull, isNull);
    });

    test('Err exposes its failure and no value', () {
      const Result<int> result = Err(NetworkFailure());

      expect(result.isOk, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, const NetworkFailure());
    });

    test('map transforms an Ok value', () {
      const Result<int> result = Ok(3);

      expect(result.map((value) => value * 2), const Ok(6));
    });

    test('map keeps the failure of an Err', () {
      const Result<int> result = Err(NotFoundFailure());

      expect(
        result.map((value) => value * 2),
        const Err<int>(NotFoundFailure()),
      );
    });

    test('guard wraps a successful body in Ok', () async {
      final result = await Result.guard(
        () async => 'sign',
        onError: (error, stackTrace) => UnexpectedFailure(error),
      );

      expect(result, const Ok('sign'));
    });

    test('guard maps a thrown error to Err', () async {
      final error = StateError('offline');

      final result = await Result.guard<String>(
        () async => throw error,
        onError: (error, stackTrace) => const NetworkFailure(),
      );

      expect(result, const Err<String>(NetworkFailure()));
    });

    test('guard passes the thrown error to onError', () async {
      final error = StateError('boom');
      Object? received;

      await Result.guard<void>(
        () async => throw error,
        onError: (error, stackTrace) {
          received = error;
          return UnexpectedFailure(error);
        },
      );

      expect(received, same(error));
    });

    test('values are equal by content', () {
      final one = int.parse('1');
      final failure = fresh(NetworkFailure.new);

      expect(Ok(one), const Ok(1));
      expect(Ok(one).hashCode, const Ok(1).hashCode);
      expect(Err<int>(failure), const Err<int>(NetworkFailure()));
      expect(
        Err<int>(failure).hashCode,
        const Err<int>(NetworkFailure()).hashCode,
      );
      expect(const Ok(1), isNot(const Ok(2)));
    });

    test('toString describes the variant', () {
      expect(const Ok(1).toString(), 'Ok(1)');
      expect(
        const Err<int>(UnexpectedFailure('x')).toString(),
        'Err(UnexpectedFailure(x))',
      );
    });

    test('switch over Result is exhaustive', () {
      String describe(Result<int> result) => switch (result) {
        Ok(:final value) => 'ok $value',
        Err(:final failure) => 'err $failure',
      };

      expect(describe(const Ok(2)), 'ok 2');
      expect(
        describe(const Err(UnexpectedFailure(1))),
        'err UnexpectedFailure(1)',
      );
    });
  });
}
