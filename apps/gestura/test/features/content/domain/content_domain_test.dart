import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/domain/localized_text.dart';
import 'package:gestura/features/content/domain/sign.dart';

const _title = LocalizedText({'en': 'Title'});

Lesson _lesson(String id, {int unit = 0, int order = 0}) => Lesson(
  id: LessonId(id),
  courseId: const CourseId('course'),
  unitIndex: unit,
  order: order,
  title: _title,
  steps: const [],
);

Sign _sign(String id) => Sign(
  id: SignId(id),
  gloss: id.toUpperCase(),
  meaning: _title,
  category: const CategoryId('basics'),
  media: const SignMedia(
    videoAsset: 'v.mp4',
    thumbnailAsset: 't.webp',
    duration: Duration(seconds: 2),
  ),
  source: const ContentSource(name: 'Test', license: 'CC BY 4.0'),
);

void main() {
  group('LocalizedText', () {
    const text = LocalizedText({'en': 'Hello', 'ar': 'مرحبًا'});

    test('returns the requested language', () {
      expect(text.resolve('ar'), 'مرحبًا');
    });

    test('falls back to English, then to any language', () {
      expect(text.resolve('de'), 'Hello');
      expect(const LocalizedText({'fr': 'Bonjour'}).resolve('de'), 'Bonjour');
      expect(const LocalizedText({}).resolve('de'), isEmpty);
    });

    test('compares by content', () {
      final copy = LocalizedText(Map.of({'ar': 'مرحبًا', 'en': 'Hello'}));

      expect(copy, text);
      expect(copy.hashCode, text.hashCode);
      expect(text, isNot(const LocalizedText({'en': 'Hello'})));
    });
  });

  test('typed ids compare by value', () {
    expect(SignId(String.fromCharCodes('a'.codeUnits)), const SignId('a'));
  });

  group('Lesson', () {
    test('lists every sign it teaches or asks about once', () {
      const lesson = Lesson(
        id: LessonId('l'),
        courseId: CourseId('c'),
        unitIndex: 0,
        order: 0,
        title: _title,
        steps: [
          LearnSignStep(SignId('a')),
          ChooseWordStep(SignId('a'), [
            SignId('a'),
            SignId('b'),
            SignId('c'),
            SignId('d'),
          ]),
          ChooseVideoStep(SignId('e'), [
            SignId('a'),
            SignId('e'),
            SignId('f'),
            SignId('g'),
          ]),
        ],
      );

      expect(
        lesson.signs.map((id) => id.value),
        unorderedEquals(['a', 'b', 'c', 'd', 'e', 'f', 'g']),
      );
    });

    test('compares by id', () {
      expect(_lesson('x', order: 1), _lesson('x', order: 2));
      expect(_lesson('x').hashCode, _lesson('x', order: 3).hashCode);
    });
  });

  group('Course', () {
    final course = Course(
      id: const CourseId('c'),
      level: CefrLevel.fromName('a1'),
      title: _title,
      units: const [
        CourseUnit(index: 0, title: _title),
        CourseUnit(index: 1, title: _title),
      ],
      lessons: [_lesson('b', order: 1), _lesson('c', unit: 1), _lesson('a')],
    );

    test('lists the lessons of a unit in order', () {
      expect(course.lessonsIn(0).map((lesson) => lesson.id.value), ['a', 'b']);
      expect(course.lessonsIn(1).map((lesson) => lesson.id.value), ['c']);
    });

    test('compares by id', () {
      expect(
        course,
        const Course(
          id: CourseId('c'),
          level: CefrLevel.a2,
          title: _title,
          units: [],
          lessons: [],
        ),
      );
      expect(course.hashCode, const CourseId('c').hashCode);
    });
  });

  group('Sign', () {
    test('is a placeholder only with the placeholder licence', () {
      expect(_sign('a').isPlaceholder, isFalse);
      expect(
        const ContentSource(name: 'x', license: 'placeholder').isPlaceholder,
        isTrue,
      );
    });

    test('compares by id', () {
      expect(_sign('a'), _sign('a'));
      expect(_sign('a').hashCode, _sign('a').hashCode);
      expect(_sign('a'), isNot(_sign('b')));
    });
  });
}
