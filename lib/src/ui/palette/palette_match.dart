/// How the palette ranks what it finds (#155).
library;

/// How well [text] answers [query], or null when it does not.
///
/// Every word of the query must appear in the text (any order, any
/// case). A word that starts the text, or a word of it, counts for more
/// than one found inside a word; so "sw ed" finds "Editor: Switch to
/// the WYSIWYG editor" and ranks it above a name that merely contains
/// the letters.
int? paletteScore(String text, String query) {
  final haystack = text.toLowerCase();
  final words = query.toLowerCase().split(RegExp(r'\s+'))
    ..removeWhere((w) => w.isEmpty);
  if (words.isEmpty) return 0;
  var score = 0;
  for (final word in words) {
    final at = haystack.indexOf(word);
    if (at < 0) return null;
    if (at == 0) {
      score += 3;
    } else if (_startsWord(haystack, at)) {
      score += 2;
    } else {
      score += 1;
    }
  }
  return score;
}

bool _startsWord(String text, int at) {
  final before = text.codeUnitAt(at - 1);
  // A space, a colon, a slash, a dash, a dot, an underscore.
  return const [0x20, 0x3A, 0x2F, 0x2D, 0x2E, 0x5F].contains(before);
}

/// [items] that answer [query], best first: what was used recently
/// first — the order [recent] gives — then by score, then by name.
List<T> paletteRank<T>(
  Iterable<T> items,
  String query, {
  required String Function(T item) name,
  required Object Function(T item) id,
  List<Object> recent = const [],
}) {
  final scored = <(T, int)>[];
  for (final item in items) {
    final score = paletteScore(name(item), query);
    if (score != null) scored.add((item, score));
  }
  int recency(T item) {
    final at = recent.indexOf(id(item));
    return at < 0 ? recent.length : at;
  }

  scored.sort((a, b) {
    final byRecent = recency(a.$1).compareTo(recency(b.$1));
    if (byRecent != 0) return byRecent;
    final byScore = b.$2.compareTo(a.$2);
    if (byScore != 0) return byScore;
    return name(a.$1).toLowerCase().compareTo(name(b.$1).toLowerCase());
  });
  return [for (final (item, _) in scored) item];
}
