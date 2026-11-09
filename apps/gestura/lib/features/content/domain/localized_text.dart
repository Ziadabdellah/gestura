import 'package:meta/meta.dart';

@immutable
final class LocalizedText {
  const new(this.values);

  static const String fallbackLanguage = 'en';

  final Map<String, String> values;

  String resolve(String languageCode) =>
      values[languageCode] ??
      values[fallbackLanguage] ??
      values.values.firstOrNull ??
      '';

  Iterable<String> get all => values.values;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalizedText &&
          other.values.length == values.length &&
          values.entries.every(
            (entry) => other.values[entry.key] == entry.value,
          );

  @override
  int get hashCode => Object.hashAllUnordered(
    values.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}
