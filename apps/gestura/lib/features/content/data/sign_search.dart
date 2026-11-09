import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura_core/gestura_core.dart';

List<Sign> searchSigns(Iterable<Sign> signs, String query) {
  final needle = _normalize(query);
  final ranked =
      <({Sign sign, int rank})>[
        for (final sign in signs)
          if (_rank(sign, needle) case final int rank) (sign: sign, rank: rank),
      ]..sort(
        (a, b) => switch (a.rank.compareTo(b.rank)) {
          0 => a.sign.gloss.compareTo(b.sign.gloss),
          final order => order,
        },
      );
  return [for (final entry in ranked) entry.sign];
}

int? _rank(Sign sign, String needle) {
  if (needle.isEmpty) return 0;
  final terms = [sign.gloss, ...sign.meaning.all].map(_normalize);
  if (terms.any((term) => term.startsWith(needle))) return 0;
  if (terms.any((term) => term.contains(needle))) return 1;
  return null;
}

String _normalize(String text) => normalizeForSearch(text.replaceAll('-', ' '));
