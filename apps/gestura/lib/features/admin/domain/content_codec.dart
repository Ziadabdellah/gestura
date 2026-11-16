import 'package:gestura/features/admin/domain/content_kind.dart';

Map<String, Object?> formValuesOf(ContentKind kind, Map<String, Object?> data) {
  final source = data['source'];
  return {
    for (final field in kind.fields)
      field.name.name: switch (field.name) {
        FieldName.sourceName => source is Map ? source['name'] : null,
        FieldName.sourceLicense => source is Map ? source['license'] : null,
        FieldName.sourceUrl => source is Map ? source['url'] ?? '' : '',
        _ => switch (field.type) {
          FieldType.localized => {
            for (final MapEntry(:key, :value)
                in ((data[field.name.name] as Map?) ?? const {}).entries)
              '$key': '$value',
          },
          FieldType.number => data[field.name.name]?.toString(),
          FieldType.toggle => data[field.name.name] ?? false,
          FieldType.jsonList => data[field.name.name],
          _ => data[field.name.name],
        },
      },
    'published': data['published'] ?? false,
  };
}

Map<String, Object?> documentOf(ContentKind kind, Map<String, Object?> values) {
  final document = <String, Object?>{};
  final source = <String, String>{};
  for (final field in kind.fields) {
    final value = values[field.name.name];
    if (field.name == FieldName.sourceName) {
      source['name'] = value! as String;
    } else if (field.name == FieldName.sourceLicense) {
      source['license'] = value! as String;
    } else if (field.name == FieldName.sourceUrl) {
      if (value is String && value.isNotEmpty) source['url'] = value;
    } else {
      document[field.name.name] = switch (field.type) {
        FieldType.number => int.parse('$value'),
        FieldType.localized => {
          for (final MapEntry(:key, :value)
              in (value! as Map<String, String>).entries)
            if (value.isNotEmpty) key: value,
        },
        _ => value,
      };
    }
  }
  if (source.isNotEmpty) document['source'] = source;
  document['published'] = values['published'] == true;
  return document;
}
