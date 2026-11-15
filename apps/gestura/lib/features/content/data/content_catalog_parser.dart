import 'dart:convert';

import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/domain/localized_text.dart';
import 'package:gestura/features/content/domain/sign.dart';

const int supportedCatalogVersion = 1;
const int quizOptionCount = 4;

typedef MediaResolver = MediaRef Function(String path);

MediaRef bundledMedia(String path) => AssetMedia(path);

ContentCatalog parseContentCatalog(
  String source, {
  MediaResolver media = bundledMedia,
}) {
  final catalog = switch (jsonDecode(source)) {
    {
      'version': supportedCatalogVersion,
      'pack': final Object? pack,
      'categories': final List<Object?> categories,
      'courses': final List<Object?> courses,
      'signs': final List<Object?> signs,
    } =>
      ContentCatalog(
        pack: _pack(pack),
        categories: categories.map(_category).toList(),
        courses: courses.map(_course).toList(),
        signs: [for (final sign in signs) _sign(sign, media)],
      ),
    final Object? other => throw FormatException(
      'Unsupported content catalog',
      other,
    ),
  };
  _checkReferences(catalog);
  return catalog;
}

SignLanguagePack _pack(Object? json) => switch (json) {
  {
    'code': final String code,
    'placeholder': final bool placeholder,
    'fingerspelling': final String fingerspelling,
    'name': final Object? name,
  } =>
    SignLanguagePack(
      code: code,
      name: _text(name),
      fingerspelling: FingerspellingStyle.fromName(fingerspelling),
      isPlaceholder: placeholder,
    ),
  _ => throw FormatException('Invalid pack', json),
};

SignCategory _category(Object? json) => switch (json) {
  {'id': final String id, 'name': final Object? name} => SignCategory(
    id: CategoryId(id),
    name: _text(name),
  ),
  _ => throw FormatException('Invalid category', json),
};

Course _course(Object? json) => switch (json) {
  {
    'id': final String id,
    'level': final String level,
    'title': final Object? title,
    'units': final List<Object?> units,
    'lessons': final List<Object?> lessons,
  } =>
    Course(
      id: CourseId(id),
      level: CefrLevel.fromName(level),
      title: _text(title),
      units: units.map(_unit).toList(),
      lessons: [for (final lesson in lessons) _lesson(lesson, CourseId(id))],
    ),
  _ => throw FormatException('Invalid course', json),
};

CourseUnit _unit(Object? json) => switch (json) {
  {'index': final int index, 'title': final Object? title} => CourseUnit(
    index: index,
    title: _text(title),
  ),
  _ => throw FormatException('Invalid unit', json),
};

Lesson _lesson(Object? json, CourseId courseId) => switch (json) {
  {
    'id': final String id,
    'unit': final int unit,
    'order': final int order,
    'title': final Object? title,
    'steps': final List<Object?> steps,
  } =>
    Lesson(
      id: LessonId(id),
      courseId: courseId,
      unitIndex: unit,
      order: order,
      title: _text(title),
      steps: steps.map(_step).toList(),
    ),
  _ => throw FormatException('Invalid lesson', json),
};

LessonStep _step(Object? json) => switch (json) {
  {'type': 'learn', 'sign': final String sign} => LearnSignStep(SignId(sign)),
  {
    'type': 'chooseWord',
    'sign': final String sign,
    'options': final List<Object?> options,
  } =>
    ChooseWordStep(SignId(sign), _ids(options)),
  {
    'type': 'chooseVideo',
    'sign': final String sign,
    'options': final List<Object?> options,
  } =>
    ChooseVideoStep(SignId(sign), _ids(options)),
  _ => throw FormatException('Invalid lesson step', json),
};

Sign _sign(Object? json, MediaResolver media) => switch (json) {
  {
    'id': final String id,
    'gloss': final String gloss,
    'category': final String category,
    'meaning': final Object? meaning,
    'video': final String video,
    'thumbnail': final String thumbnail,
    'durationMs': final int durationMs,
    'source': {
      'name': final String sourceName,
      'license': final String license,
    },
  } =>
    Sign(
      id: SignId(id),
      gloss: gloss,
      meaning: _text(meaning),
      category: CategoryId(category),
      media: SignMedia(
        video: media(video),
        thumbnail: media(thumbnail),
        duration: Duration(milliseconds: durationMs),
      ),
      source: ContentSource(
        name: sourceName,
        license: license,
        url: switch ((json as Map<String, Object?>)['source']) {
          {'url': final String url} => Uri.parse(url),
          _ => null,
        },
      ),
    ),
  _ => throw FormatException('Invalid sign', json),
};

LocalizedText _text(Object? json) => switch (json) {
  final Map<String, Object?> map
      when map.isNotEmpty && map.values.every((value) => value is String) =>
    LocalizedText({
      for (final MapEntry(:key, :value) in map.entries) key: value! as String,
    }),
  _ => throw FormatException('Invalid localized text', json),
};

List<SignId> _ids(List<Object?> json) => [
  for (final id in json)
    switch (id) {
      final String value => SignId(value),
      _ => throw FormatException('Invalid sign id', id),
    },
];

void _checkReferences(ContentCatalog catalog) {
  final categories = {for (final category in catalog.categories) category.id};
  for (final sign in catalog.signs) {
    if (!categories.contains(sign.category)) {
      throw FormatException('Unknown category', sign.category);
    }
  }
  for (final course in catalog.courses) {
    final units = {for (final unit in course.units) unit.index};
    for (final lesson in course.lessons) {
      if (!units.contains(lesson.unitIndex)) {
        throw FormatException('Unknown unit', lesson.id);
      }
      for (final id in lesson.signs) {
        if (catalog.sign(id) == null) throw FormatException('Unknown sign', id);
      }
      for (final step in lesson.steps) {
        switch (step) {
          case LearnSignStep():
            break;
          case ChooseWordStep(:final sign, :final options) ||
              ChooseVideoStep(:final sign, :final options):
            if (options.length != quizOptionCount ||
                !options.contains(sign) ||
                options.toSet().length != options.length) {
              throw FormatException('Invalid quiz options', lesson.id);
            }
        }
      }
    }
  }
}
