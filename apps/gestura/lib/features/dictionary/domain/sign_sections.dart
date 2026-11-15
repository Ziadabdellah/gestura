import 'package:gestura/features/content/domain/sign.dart';
import 'package:meta/meta.dart';

@immutable
final class SignSection {
  const new({required this.initial, required this.signs});

  final String initial;
  final List<Sign> signs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignSection &&
          other.initial == initial &&
          other.signs.length == signs.length &&
          Iterable<int>.generate(signs.length)
              .every((index) => other.signs[index] == signs[index]);

  @override
  int get hashCode => Object.hash(initial, Object.hashAll(signs));
}

List<SignSection> sectionsByInitial(Iterable<Sign> signs) {
  final sorted = [...signs]..sort((a, b) => a.gloss.compareTo(b.gloss));
  final sections = <String, List<Sign>>{};
  for (final sign in sorted) {
    sections.putIfAbsent(_initialOf(sign.gloss), () => []).add(sign);
  }
  return [
    for (final MapEntry(key: initial, value: signs) in sections.entries)
      SignSection(initial: initial, signs: signs),
  ];
}

String _initialOf(String gloss) =>
    String.fromCharCodes(gloss.runes.take(1)).toUpperCase();
