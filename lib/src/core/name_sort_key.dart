/// How file and folder names are compared in the tree (#1070).
library;

/// The ASCII letters the Latin letters with marks are read as, after
/// lowercasing; `ß`, `æ` and `œ` are two letters each.
const Map<String, String> _folds = {
  'àáâãäåāăą': 'a',
  'çćĉċč': 'c',
  'ďđð': 'd',
  'èéêëēĕėęě': 'e',
  'ĝğġģ': 'g',
  'ĥħ': 'h',
  'ìíîïĩīĭįı': 'i',
  'ĵ': 'j',
  'ķ': 'k',
  'ĺļľŀł': 'l',
  'ñńņňŉ': 'n',
  'òóôõöøōŏő': 'o',
  'ŕŗř': 'r',
  'śŝşš': 's',
  'ţťŧ': 't',
  'ùúûüũūŭůűų': 'u',
  'ŵ': 'w',
  'ýÿŷ': 'y',
  'źżž': 'z',
  'ß': 'ss',
  'æ': 'ae',
  'œ': 'oe',
};

final Map<int, String> _foldOf = {
  for (final MapEntry(:key, :value) in _folds.entries)
    for (final rune in key.runes) rune: value,
};

/// [name] lowercased and with its diacritics folded: `Émile` reads `emile`.
/// Combining marks (a name written decomposed) are dropped. What the tree's
/// type-ahead compares, and the base of [nameSortKey].
String foldName(String name) {
  final out = StringBuffer();
  for (final rune in name.toLowerCase().runes) {
    if (rune >= 0x300 && rune <= 0x36F) continue;
    final folded = _foldOf[rune];
    if (folded != null) {
      out.write(folded);
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

/// The key the tree orders names by (#1070): [foldName], with each run of
/// digits written as its length and then its digits, so that `note 2` sorts
/// before `note 10` and, in the byte order SQLite compares text in, a number
/// is smaller than a longer one. Leading zeros do not count; a run past 99
/// digits is cut at 99.
///
/// Two names that differ only in case or marks have the same key, which is
/// why the order is `(name_key, name)`.
String nameSortKey(String name) {
  final folded = foldName(name);
  final out = StringBuffer();
  var i = 0;
  while (i < folded.length) {
    final unit = folded.codeUnitAt(i);
    if (unit < 0x30 || unit > 0x39) {
      out.writeCharCode(unit);
      i++;
      continue;
    }
    var end = i;
    while (end < folded.length &&
        folded.codeUnitAt(end) >= 0x30 &&
        folded.codeUnitAt(end) <= 0x39) {
      end++;
    }
    var start = i;
    while (start < end - 1 && folded.codeUnitAt(start) == 0x30) {
      start++;
    }
    var digits = folded.substring(start, end);
    if (digits.length > 99) digits = digits.substring(0, 99);
    out
      ..write(digits.length.toString().padLeft(2, '0'))
      ..write(digits);
    i = end;
  }
  return out.toString();
}
