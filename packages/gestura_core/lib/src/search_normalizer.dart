String normalizeForSearch(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    if (_ignoredRunes.contains(rune)) continue;
    final char = String.fromCharCode(rune);
    buffer.write(_folds[char] ?? _foldDigit(rune) ?? char);
  }
  return buffer.toString().trim().replaceAll(_whitespace, ' ');
}

String? _foldDigit(int rune) {
  for (final zero in _nativeDigitZeros) {
    if (rune >= zero && rune <= zero + 9) return '${rune - zero}';
  }
  return null;
}

final RegExp _whitespace = RegExp(r'\s+');

const _nativeDigitZeros = [0x0660, 0x06F0];

const _folds = {
  'أ': 'ا',
  'إ': 'ا',
  'آ': 'ا',
  'ٱ': 'ا',
  'ى': 'ي',
  'ة': 'ه',
  'ؤ': 'و',
  'ئ': 'ي',
  'ё': 'е',
  'ß': 'ss',
};

final Set<int> _ignoredRunes = {
  for (var rune = 0x064B; rune <= 0x0652; rune++) rune,
  0x0640,
  0x0670,
};
