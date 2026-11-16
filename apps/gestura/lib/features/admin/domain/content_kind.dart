enum FieldType {
  text,
  localized,
  number,
  toggle,
  choice,
  reference,
  mediaPath,
  jsonList,
}

enum FieldError { required, tooLong, number, mediaPath, jsonList }

enum FieldName {
  name,
  fingerspelling,
  placeholder,
  order,
  signLanguage,
  gloss,
  meaning,
  category,
  video,
  thumbnail,
  durationMs,
  sourceName,
  sourceLicense,
  sourceUrl,
  level,
  title,
  units,
  courseId,
  unit,
  steps,
}

final class FieldSpec {
  const new(
    this.name,
    this.type, {
    this.max = 300,
    this.min = 0,
    this.choices = const [],
    this.reference,
    this.optional = false,
  });

  final FieldName name;
  final FieldType type;
  final int max;
  final int min;
  final List<String> choices;
  final ContentKind? reference;
  final bool optional;
}

const List<String> contentLanguages = ['en', 'ar', 'ru', 'es', 'fr', 'de'];

enum ContentKind {
  signLanguages('signLanguages', 16),
  categories('categories', 64),
  signs('signs', 64),
  courses('courses', 64),
  lessons('lessons', 64);

  new(this.collection, this.maxIdLength);

  final String collection;
  final int maxIdLength;

  static ContentKind? byCollection(String collection) =>
      values.where((kind) => kind.collection == collection).firstOrNull;

  List<FieldSpec> get fields => switch (this) {
    signLanguages => const [
      FieldSpec(FieldName.name, FieldType.localized),
      FieldSpec(
        FieldName.fingerspelling,
        FieldType.choice,
        choices: ['oneHanded', 'twoHanded'],
      ),
      FieldSpec(FieldName.placeholder, FieldType.toggle),
      FieldSpec(FieldName.order, FieldType.number, max: 10000),
    ],
    categories => const [
      FieldSpec(
        FieldName.signLanguage,
        FieldType.reference,
        reference: ContentKind.signLanguages,
        max: 16,
      ),
      FieldSpec(FieldName.name, FieldType.localized),
      FieldSpec(FieldName.order, FieldType.number, max: 10000),
    ],
    signs => const [
      FieldSpec(
        FieldName.signLanguage,
        FieldType.reference,
        reference: ContentKind.signLanguages,
        max: 16,
      ),
      FieldSpec(FieldName.gloss, FieldType.text, max: 80),
      FieldSpec(FieldName.meaning, FieldType.localized),
      FieldSpec(
        FieldName.category,
        FieldType.reference,
        reference: ContentKind.categories,
        max: 64,
      ),
      FieldSpec(FieldName.video, FieldType.mediaPath),
      FieldSpec(FieldName.thumbnail, FieldType.mediaPath),
      FieldSpec(FieldName.durationMs, FieldType.number, min: 1, max: 60000),
      FieldSpec(FieldName.sourceName, FieldType.text, max: 120),
      FieldSpec(FieldName.sourceLicense, FieldType.text, max: 60),
      FieldSpec(FieldName.sourceUrl, FieldType.text, optional: true),
    ],
    courses => const [
      FieldSpec(
        FieldName.signLanguage,
        FieldType.reference,
        reference: ContentKind.signLanguages,
        max: 16,
      ),
      FieldSpec(
        FieldName.level,
        FieldType.choice,
        choices: ['a1', 'a2', 'b1', 'b2'],
      ),
      FieldSpec(FieldName.title, FieldType.localized),
      FieldSpec(FieldName.units, FieldType.jsonList, max: 50),
      FieldSpec(FieldName.order, FieldType.number, max: 10000),
    ],
    lessons => const [
      FieldSpec(
        FieldName.courseId,
        FieldType.reference,
        reference: ContentKind.courses,
        max: 64,
      ),
      FieldSpec(FieldName.unit, FieldType.number, max: 10000),
      FieldSpec(FieldName.order, FieldType.number, max: 10000),
      FieldSpec(FieldName.title, FieldType.localized),
      FieldSpec(FieldName.steps, FieldType.jsonList, max: 40),
    ],
  };

  String titleOf(Map<String, Object?> data) {
    final label = switch (this) {
      signs => data['gloss'],
      signLanguages || categories => (data['name'] as Map?)?['en'],
      courses || lessons => (data['title'] as Map?)?['en'],
    };
    return label is String && label.isNotEmpty ? label : '';
  }
}

final RegExp _mediaPath = RegExp(r'^(media|asset)/[A-Za-z0-9/._-]+$');
final RegExp _documentId = RegExp(r'^[A-Za-z0-9-]+$');

bool isValidId(String id, ContentKind kind) =>
    id.isNotEmpty && id.length <= kind.maxIdLength && _documentId.hasMatch(id);

FieldError? validateField(FieldSpec spec, Object? value) {
  bool text(Object? v, {bool optional = false}) =>
      v is String && (v.isNotEmpty || optional);
  return switch (spec.type) {
    FieldType.text || FieldType.reference || FieldType.choice =>
      !text(value, optional: spec.optional)
          ? FieldError.required
          : (value! as String).length > spec.max
          ? FieldError.tooLong
          : null,
    FieldType.mediaPath =>
      !text(value)
          ? FieldError.required
          : (value! as String).length > 300 ||
                !_mediaPath.hasMatch(value as String)
          ? FieldError.mediaPath
          : null,
    FieldType.localized => switch (value) {
      final Map<String, String> map when (map['en'] ?? '').isEmpty =>
        FieldError.required,
      final Map<String, String> map
          when map.values.any((text) => text.length > 300) =>
        FieldError.tooLong,
      Map<String, String>() => null,
      _ => FieldError.required,
    },
    FieldType.number => switch (int.tryParse('${value ?? ''}')) {
      final int n when n >= spec.min && n <= spec.max => null,
      _ => FieldError.number,
    },
    FieldType.toggle => value is bool ? null : FieldError.required,
    FieldType.jsonList => switch (value) {
      final List<Object?> list
          when list.isNotEmpty && list.length <= spec.max =>
        null,
      _ => FieldError.jsonList,
    },
  };
}
