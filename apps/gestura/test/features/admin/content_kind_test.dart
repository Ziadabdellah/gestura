import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/admin/domain/content_codec.dart';
import 'package:gestura/features/admin/domain/content_doc.dart';
import 'package:gestura/features/admin/domain/content_kind.dart';

import '../../helpers/fake_admin.dart';

FieldSpec spec(ContentKind kind, FieldName name) =>
    kind.fields.firstWhere((field) => field.name == name);

void main() {
  test('finds kinds by collection', () {
    expect(ContentKind.byCollection('signs'), ContentKind.signs);
    expect(ContentKind.byCollection('nope'), isNull);
  });

  test('titles come from the gloss, name or English title', () {
    expect(ContentKind.signs.titleOf(sampleSign), 'HELLO');
    expect(
      ContentKind.categories.titleOf({
        'name': {'en': 'Family'},
      }),
      'Family',
    );
    expect(
      ContentKind.lessons.titleOf({
        'title': {'en': 'Hi'},
      }),
      'Hi',
    );
    expect(ContentKind.courses.titleOf({}), '');
  });

  test('ids are short letters, numbers and dashes', () {
    expect(isValidId('demo-a1', ContentKind.courses), isTrue);
    expect(isValidId('', ContentKind.courses), isFalse);
    expect(isValidId('a b', ContentKind.courses), isFalse);
    expect(isValidId('x' * 17, ContentKind.signLanguages), isFalse);
  });

  test('validates every field type like the security rules', () {
    final gloss = spec(ContentKind.signs, FieldName.gloss);
    expect(validateField(gloss, 'HELLO'), isNull);
    expect(validateField(gloss, ''), FieldError.required);
    expect(validateField(gloss, 'x' * 81), FieldError.tooLong);

    final url = spec(ContentKind.signs, FieldName.sourceUrl);
    expect(validateField(url, ''), isNull);

    final video = spec(ContentKind.signs, FieldName.video);
    expect(validateField(video, 'media/a.mp4'), isNull);
    expect(validateField(video, 'http://x'), FieldError.mediaPath);
    expect(validateField(video, null), FieldError.required);

    final meaning = spec(ContentKind.signs, FieldName.meaning);
    expect(validateField(meaning, {'en': 'Hi'}), isNull);
    expect(validateField(meaning, {'ar': 'x'}), FieldError.required);
    expect(validateField(meaning, {'en': 'x' * 301}), FieldError.tooLong);
    expect(validateField(meaning, null), FieldError.required);

    final duration = spec(ContentKind.signs, FieldName.durationMs);
    expect(validateField(duration, '2400'), isNull);
    expect(validateField(duration, '0'), FieldError.number);
    expect(validateField(duration, 'x'), FieldError.number);
    expect(validateField(duration, null), FieldError.number);

    final placeholder = spec(ContentKind.signLanguages, FieldName.placeholder);
    expect(validateField(placeholder, false), isNull);
    expect(validateField(placeholder, null), FieldError.required);

    final steps = spec(ContentKind.lessons, FieldName.steps);
    expect(validateField(steps, [1]), isNull);
    expect(validateField(steps, []), FieldError.jsonList);
    expect(validateField(steps, 'x'), FieldError.jsonList);
  });

  test('turns a sign into form values and back', () {
    final values = formValuesOf(ContentKind.signs, sampleSign);
    expect(values['durationMs'], '2400');
    expect(values['sourceName'], 'Gestura');
    expect(values['sourceUrl'], '');
    expect(values['meaning'], {'en': 'Hello', 'ar': 'مرحبًا'});

    final document = documentOf(ContentKind.signs, {
      ...values,
      'sourceUrl': 'https://gestura.app',
      'meaning': {'en': 'Hello', 'ar': 'مرحبًا', 'fr': ''},
    });
    expect(document['durationMs'], 2400);
    expect(document['meaning'], {'en': 'Hello', 'ar': 'مرحبًا'});
    expect(document['source'], {
      'name': 'Gestura',
      'license': 'CC BY 4.0',
      'url': 'https://gestura.app',
    });
    expect(document['published'], isTrue);
  });

  test('starts empty values for a new item', () {
    final values = formValuesOf(ContentKind.signLanguages, const {});
    expect(values['placeholder'], isFalse);
    expect(values['published'], isFalse);
    expect(values['name'], isEmpty);
    expect(values['sourceName'], isNull);
    expect(
      documentOf(ContentKind.courses, {
        'signLanguage': 'ase',
        'level': 'a1',
        'title': {'en': 'Basics'},
        'units': [1],
        'order': '0',
      }),
      {
        'signLanguage': 'ase',
        'level': 'a1',
        'title': {'en': 'Basics'},
        'units': [1],
        'order': 0,
        'published': false,
      },
    );
    expect(
      formValuesOf(ContentKind.signs, const {'source': 'bad'})['sourceName'],
      isNull,
    );
  });

  test('a document is published only when the flag is true', () {
    expect(const ContentDoc('a', {'published': true}).published, isTrue);
    expect(const ContentDoc('a', {}).published, isFalse);
  });
}
