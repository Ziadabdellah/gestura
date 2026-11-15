import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/data/bundled_content_repository.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura_core/gestura_core.dart';

class _FlakyBundle extends CachingAssetBundle {
  int calls = 0;

  @override
  Future<ByteData> load(String key) => rootBundle.load(key);

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    calls++;
    if (calls == 1) throw StateError('asset not ready');
    return rootBundle.loadString(key, cache: cache);
  }
}

const List<String> _languages = ['en', 'ar', 'ru', 'es', 'fr', 'de'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BundledContentRepository repository;

  setUp(() => repository = BundledContentRepository(rootBundle));

  Future<T> value<T>(Future<Result<T>> result) async =>
      (await result).valueOrNull as T;

  group('the shipped demo pack', () {
    test('has a placeholder letter for every letter of the alphabet', () async {
      final letters = (await repository.alphabet()).valueOrNull!;

      expect(
        letters.map((letter) => letter.gloss).join(),
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      );
      expect(letters.every((letter) => letter.source.isPlaceholder), isTrue);
    });

    test('is marked as placeholder content', () async {
      final pack = await value(repository.pack());
      final signs = await value(repository.searchSigns(''));

      expect(pack.code, 'demo');
      expect(pack.isPlaceholder, isTrue);
      expect(signs.every((sign) => sign.isPlaceholder), isTrue);
    });

    test('has one course with two units and four ordered lessons', () async {
      final course = (await value(repository.courses())).single;

      expect(course.units.map((unit) => unit.index), [0, 1]);
      expect(
        [for (final unit in course.units) ...course.lessonsIn(unit.index)]
            .map((lesson) => lesson.id.value),
        ['demo-a1-1', 'demo-a1-2', 'demo-a1-3', 'demo-a1-4'],
      );
    });

    test('names everything in all six languages', () async {
      final pack = await value(repository.pack());
      final course = (await value(repository.courses())).single;
      final categories = await value(repository.categories());
      final signs = await value(repository.searchSigns(''));
      final texts = [
        pack.name,
        course.title,
        for (final unit in course.units) unit.title,
        for (final lesson in course.lessons) lesson.title,
        for (final category in categories) category.name,
        for (final sign in signs) sign.meaning,
      ];

      for (final text in texts) {
        expect(text.values.keys, unorderedEquals(_languages));
      }
    });

    test('ships every video and thumbnail it points to', () async {
      final signs = await value(repository.searchSigns(''));

      expect(signs, hasLength(12));
      for (final sign in signs) {
        expect(
          File((sign.media.video as AssetMedia).path).existsSync(),
          isTrue,
        );
        expect(
          File((sign.media.thumbnail as AssetMedia).path).existsSync(),
          isTrue,
        );
      }
    });

    test('starts every lesson by teaching the signs it quizzes', () async {
      final course = (await value(repository.courses())).single;

      for (final lesson in course.lessons) {
        final taught = {
          for (final step in lesson.steps)
            if (step case LearnSignStep(:final sign)) sign,
        };
        final asked = {
          for (final step in lesson.steps)
            if (step is! LearnSignStep) step.sign,
        };
        expect(taught.containsAll(asked), isTrue, reason: lesson.id.value);
      }
    });
  });

  group('lookups', () {
    test('finds a lesson and a sign by id', () async {
      final lesson = await value(
        repository.lesson(const LessonId('demo-a1-1')),
      );
      final sign = await value(repository.sign(const SignId('thank-you')));

      expect(lesson.steps.first, const TypeMatcher<LearnSignStep>());
      expect(sign.gloss, 'THANK-YOU');
    });

    test('reports a missing lesson or sign as not found', () async {
      expect(
        (await repository.lesson(const LessonId('nope'))).failureOrNull,
        const NotFoundFailure(),
      );
      expect(
        (await repository.sign(const SignId('nope'))).failureOrNull,
        const NotFoundFailure(),
      );
    });

    test('returns only the requested signs', () async {
      final signs = await value(
        repository.signs({const SignId('yes'), const SignId('no')}),
      );

      expect(
        signs.map((sign) => sign.id.value),
        unorderedEquals(['yes', 'no']),
      );
    });

    test('reports a broken asset and recovers on the next call', () async {
      final bundle = _FlakyBundle();
      final flaky = BundledContentRepository(bundle);

      final first = await flaky.pack();
      final second = await flaky.pack();

      expect(first.failureOrNull, isA<UnexpectedFailure>());
      expect(second.valueOrNull?.code, 'demo');
      expect(bundle.calls, 2);
    });

    test('reports a broken asset during a lookup', () async {
      final flaky = BundledContentRepository(_FlakyBundle());

      final result = await flaky.lesson(const LessonId('demo-a1-1'));

      expect(result.failureOrNull, isA<UnexpectedFailure>());
    });

    test('reads the asset only once', () async {
      final bundle = _FlakyBundle()..calls = 1;
      final cached = BundledContentRepository(bundle);

      await cached.pack();
      await cached.courses();
      await cached.searchSigns('');

      expect(bundle.calls, 2);
    });
  });

  group('search', () {
    Future<List<String>> ids(String query) async => [
      for (final Sign sign in await value(repository.searchSigns(query)))
        sign.id.value,
    ];

    test('lists every sign by gloss for an empty query', () async {
      final all = await ids('');

      expect(all, hasLength(12));
      expect(all.first, 'brother');
    });

    test('matches the gloss in any case and with spaces for dashes', () async {
      expect(await ids('THANK you'), ['thank-you']);
    });

    test('matches meanings in every interface language', () async {
      expect(await ids('danke'), ['thank-you']);
      expect(await ids('спасибо'), ['thank-you']);
      expect(await ids('gracias'), ['thank-you']);
      expect(await ids('merci'), ['thank-you']);
    });

    test('ignores Arabic diacritics and hamza forms', () async {
      expect(await ids('شكرا'), ['thank-you']);
      expect(await ids('مرحبا'), ['hello']);
      expect(await ids('اخت'), ['sister']);
    });

    test('ignores accents only when they are typed the same way', () async {
      expect(await ids('sœur'), ['sister']);
      expect(await ids('Mère'), ['mother']);
    });

    test('puts prefix matches before matches inside a word', () async {
      expect((await ids('fa')).first, 'family');
    });

    test('returns nothing for an unknown word', () async {
      expect(await ids('xyzzy'), isEmpty);
    });
  });
}
