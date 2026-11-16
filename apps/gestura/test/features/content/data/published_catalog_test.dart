import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/data/published_catalog.dart';

void main() {
  test('nothing is published without a sign language', () {
    expect(
      catalogFromDocuments(
        signLanguages: const [],
        categories: const [],
        signs: const [],
        courses: const [],
        lessons: const [],
      ),
      isNull,
    );
  });

  test('builds the catalog of the chosen pack in order', () {
    final catalog = catalogFromDocuments(
      preferredCode: 'bsl',
      signLanguages: const [
        (
          'ase',
          {
            'order': 0,
            'name': {'en': 'ASL'},
          },
        ),
        (
          'bsl',
          {
            'order': 1,
            'name': {'en': 'BSL'},
            'fingerspelling': 'twoHanded',
            'placeholder': false,
          },
        ),
      ],
      categories: const [
        (
          'b',
          {
            'signLanguage': 'bsl',
            'order': 2,
            'name': {'en': 'B'},
          },
        ),
        (
          'a',
          {
            'signLanguage': 'bsl',
            'order': 1,
            'name': {'en': 'A'},
          },
        ),
        (
          'x',
          {
            'signLanguage': 'ase',
            'name': {'en': 'X'},
          },
        ),
      ],
      signs: const [
        (
          'hello',
          {
            'signLanguage': 'bsl',
            'gloss': 'HELLO',
            'meaning': {'en': 'Hello'},
            'category': 'a',
            'video': 'media/hello.mp4',
            'thumbnail': 'media/hello.jpg',
            'durationMs': 1000,
            'source': {'name': 'S', 'license': 'L'},
            'published': true,
          },
        ),
      ],
      courses: const [
        (
          'c1',
          {
            'signLanguage': 'bsl',
            'level': 'a1',
            'title': {'en': 'Basics'},
            'units': [
              {
                'index': 1,
                'title': {'en': 'One'},
              },
            ],
          },
        ),
      ],
      lessons: const [
        (
          'l2',
          {
            'courseId': 'c1',
            'unit': 1,
            'order': 1,
            'title': {'en': 'Two'},
            'steps': [],
          },
        ),
        (
          'l1',
          {
            'courseId': 'c1',
            'unit': 1,
            'order': 0,
            'title': {'en': 'One'},
            'steps': [],
          },
        ),
        (
          'l0',
          {
            'courseId': 'other',
            'unit': 0,
            'order': 0,
            'title': {'en': 'No'},
            'steps': [],
          },
        ),
      ],
    )!;

    expect(catalog['pack'], {
      'code': 'bsl',
      'name': {'en': 'BSL'},
      'fingerspelling': 'twoHanded',
      'placeholder': false,
    });
    expect((catalog['categories']! as List).map((c) => (c as Map)['id']), [
      'a',
      'b',
    ]);
    expect((catalog['signs']! as List).single, isNot(contains('published')));
    final course = (catalog['courses']! as List).single as Map;
    expect((course['lessons'] as List).map((l) => (l as Map)['id']), [
      'l1',
      'l2',
    ]);
  });

  test('uses the first pack when the chosen one is missing', () {
    final catalog = catalogFromDocuments(
      preferredCode: 'nope',
      signLanguages: const [
        (
          'ase',
          {
            'name': {'en': 'ASL'},
          },
        ),
      ],
      categories: const [],
      signs: const [],
      courses: const [],
      lessons: const [],
    )!;

    expect((catalog['pack']! as Map)['code'], 'ase');
  });
}
