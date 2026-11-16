import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

typedef Doc = Map<String, Object?>;

abstract interface class PublishedCatalog {
  Future<Doc?> load(String? preferredCode);
}

int _order(Doc doc, String field) => doc[field] as int? ?? 0;

Doc? catalogFromDocuments({
  required List<(String, Doc)> signLanguages,
  required List<(String, Doc)> categories,
  required List<(String, Doc)> signs,
  required List<(String, Doc)> courses,
  required List<(String, Doc)> lessons,
  String? preferredCode,
}) {
  if (signLanguages.isEmpty) return null;
  final ordered = [...signLanguages]
    ..sort((a, b) => _order(a.$2, 'order').compareTo(_order(b.$2, 'order')));
  final (code, pack) = ordered.firstWhere(
    (entry) => entry.$1 == preferredCode,
    orElse: () => ordered.first,
  );
  bool ofPack((String, Doc) entry) => entry.$2['signLanguage'] == code;
  List<(String, Doc)> sorted(List<(String, Doc)> items) => [...items]
    ..sort((a, b) => _order(a.$2, 'order').compareTo(_order(b.$2, 'order')));
  return {
    'version': 1,
    'pack': {
      'code': code,
      'name': pack['name'],
      'fingerspelling': pack['fingerspelling'],
      'placeholder': pack['placeholder'],
    },
    'categories': [
      for (final (id, category) in sorted(categories.where(ofPack).toList()))
        {'id': id, 'name': category['name']},
    ],
    'signs': [
      for (final (id, sign) in signs.where(ofPack))
        {
          'id': id,
          for (final field in const [
            'gloss',
            'meaning',
            'category',
            'video',
            'thumbnail',
            'durationMs',
            'source',
          ])
            field: sign[field],
        },
    ],
    'courses': [
      for (final (id, course) in sorted(courses.where(ofPack).toList()))
        {
          'id': id,
          'level': course['level'],
          'title': course['title'],
          'units': course['units'],
          'lessons': [
            for (final (lessonId, lesson)
                in lessons.where((entry) => entry.$2['courseId'] == id).toList()
                  ..sort(
                    (a, b) =>
                        (_order(a.$2, 'unit') * 100000 + _order(a.$2, 'order'))
                            .compareTo(
                              _order(b.$2, 'unit') * 100000 +
                                  _order(b.$2, 'order'),
                            ),
                  ))
              {
                'id': lessonId,
                'unit': lesson['unit'],
                'order': lesson['order'],
                'title': lesson['title'],
                'steps': lesson['steps'],
              },
          ],
        },
    ],
  };
}

@LazySingleton(as: PublishedCatalog)
final class FirestorePublishedCatalog implements PublishedCatalog {
  const new(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<(String, Doc)>> _published(String collection) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('published', isEqualTo: true)
        .get();
    return [for (final doc in snapshot.docs) (doc.id, doc.data())];
  }

  @override
  Future<Doc?> load(String? preferredCode) async {
    final results = await Future.wait([
      _published('signLanguages'),
      _published('categories'),
      _published('signs'),
      _published('courses'),
      _published('lessons'),
    ]);
    return catalogFromDocuments(
      signLanguages: results[0],
      categories: results[1],
      signs: results[2],
      courses: results[3],
      lessons: results[4],
      preferredCode: preferredCode,
    );
  }
}
