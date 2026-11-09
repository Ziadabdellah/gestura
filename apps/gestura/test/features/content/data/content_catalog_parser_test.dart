import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/data/content_catalog_parser.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/content/domain/lesson.dart';

Map<String, Object?> _sign(String id, {String category = 'basics'}) => {
  'id': id,
  'gloss': id.toUpperCase(),
  'category': category,
  'meaning': {'en': id, 'ar': 'عربي $id'},
  'video': 'assets/$id.mp4',
  'thumbnail': 'assets/$id.webp',
  'durationMs': 2000,
  'source': {'name': 'Test', 'license': 'placeholder'},
};

Map<String, Object?> _catalog({
  List<Object?>? steps,
  List<Object?>? signs,
  int unit = 0,
  Object? version = 1,
}) => {
  'version': version,
  'pack': {
    'code': 'test',
    'placeholder': true,
    'fingerspelling': 'twoHanded',
    'name': {'en': 'Test pack'},
  },
  'categories': [
    {
      'id': 'basics',
      'name': {'en': 'Basics'},
    },
  ],
  'courses': [
    {
      'id': 'course',
      'level': 'a2',
      'title': {'en': 'Course'},
      'units': [
        {
          'index': 0,
          'title': {'en': 'Unit'},
        },
      ],
      'lessons': [
        {
          'id': 'lesson',
          'unit': unit,
          'order': 0,
          'title': {'en': 'Lesson'},
          'steps':
              steps ??
              [
                {'type': 'learn', 'sign': 'a'},
                {
                  'type': 'chooseWord',
                  'sign': 'a',
                  'options': ['b', 'a', 'c', 'd'],
                },
                {
                  'type': 'chooseVideo',
                  'sign': 'b',
                  'options': ['a', 'b', 'c', 'd'],
                },
              ],
        },
      ],
    },
  ],
  'signs': signs ?? [_sign('a'), _sign('b'), _sign('c'), _sign('d')],
};

ContentCatalog _parse(Map<String, Object?> json) =>
    parseContentCatalog(jsonEncode(json));

void main() {
  test('reads the pack, courses, lessons and signs', () {
    final catalog = _parse(_catalog());
    final course = catalog.courses.single;
    final lesson = course.lessons.single;

    expect(catalog.pack.code, 'test');
    expect(catalog.pack.fingerspelling, FingerspellingStyle.twoHanded);
    expect(catalog.pack.isPlaceholder, isTrue);
    expect(course.level, CefrLevel.a2);
    expect(lesson.courseId, const CourseId('course'));
    expect(lesson.steps, hasLength(3));
    expect(lesson.steps[0], isA<LearnSignStep>());
    expect(
      lesson.steps[1],
      isA<ChooseWordStep>().having((step) => step.options, 'options', const [
        SignId('b'),
        SignId('a'),
        SignId('c'),
        SignId('d'),
      ]),
    );
    expect(lesson.steps[2], isA<ChooseVideoStep>());
    expect(catalog.signs.map((sign) => sign.id.value), ['a', 'b', 'c', 'd']);
    expect(catalog.sign(const SignId('a'))?.meaning.resolve('ar'), 'عربي a');
    expect(catalog.sign(const SignId('a'))?.isPlaceholder, isTrue);
    expect(catalog.lesson(const LessonId('lesson')), lesson);
  });

  test('reads an optional source link', () {
    final signs = [
      {
        ..._sign('a'),
        'source': {
          'name': 'Archive',
          'license': 'CC BY 4.0',
          'url': 'https://example.org/a',
        },
      },
      _sign('b'),
      _sign('c'),
      _sign('d'),
    ];

    final sign = _parse(_catalog(signs: signs)).sign(const SignId('a'))!;

    expect(sign.source.url, Uri.parse('https://example.org/a'));
    expect(sign.isPlaceholder, isFalse);
  });

  group('rejects', () {
    void expectRejected(Map<String, Object?> json) =>
        expect(() => _parse(json), throwsFormatException);

    test('a pack, category, course, unit or lesson with missing fields', () {
      Map<String, Object?> course() =>
          (_catalog()['courses']! as List<Object?>).single!
              as Map<String, Object?>;
      Map<String, Object?> withCourse(Map<String, Object?> changed) => {
        ..._catalog(),
        'courses': [changed],
      };

      expectRejected({
        ..._catalog(),
        'pack': {'code': 'test'},
      });
      expectRejected({
        ..._catalog(),
        'categories': [
          {'id': 'basics'},
        ],
      });
      expectRejected(withCourse({...course(), 'units': null}));
      expectRejected(
        withCourse({
          ...course(),
          'units': [
            {'index': 0},
          ],
        }),
      );
      expectRejected(
        withCourse({
          ...course(),
          'lessons': [
            {'id': 'lesson'},
          ],
        }),
      );
    });

    test('an unsupported version', () {
      expectRejected(_catalog(version: 2));
    });

    test('a sign with missing fields', () {
      expectRejected(
        _catalog(
          signs: [
            {'id': 'a'},
          ],
        ),
      );
    });

    test('an unknown step type', () {
      expectRejected(
        _catalog(
          steps: [
            {'type': 'dance', 'sign': 'a'},
          ],
        ),
      );
    });

    test('a step that points to a missing sign', () {
      expectRejected(
        _catalog(
          steps: [
            {'type': 'learn', 'sign': 'z'},
          ],
        ),
      );
    });

    test('a quiz whose options leave out the answer', () {
      expectRejected(
        _catalog(
          steps: [
            {
              'type': 'chooseWord',
              'sign': 'a',
              'options': ['b', 'c', 'd', 'b'],
            },
          ],
        ),
      );
    });

    test('a quiz without exactly four different options', () {
      expectRejected(
        _catalog(
          steps: [
            {
              'type': 'chooseVideo',
              'sign': 'a',
              'options': ['a', 'b', 'c'],
            },
          ],
        ),
      );
    });

    test('a lesson in a unit that does not exist', () {
      expectRejected(_catalog(unit: 3));
    });

    test('a sign in a category that does not exist', () {
      expectRejected(
        _catalog(
          signs: [
            _sign('a', category: 'sports'),
            _sign('b'),
            _sign('c'),
            _sign('d'),
          ],
        ),
      );
    });

    test('a translation that is not text', () {
      expectRejected(
        _catalog(
          signs: [
            {
              ..._sign('a'),
              'meaning': {'en': 1},
            },
            _sign('b'),
            _sign('c'),
            _sign('d'),
          ],
        ),
      );
    });

    test('an option that is not a sign id', () {
      expectRejected(
        _catalog(
          steps: [
            {
              'type': 'chooseWord',
              'sign': 'a',
              'options': ['a', 'b', 'c', 4],
            },
          ],
        ),
      );
    });
  });
}
