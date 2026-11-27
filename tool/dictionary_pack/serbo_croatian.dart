// Serbo-Croatian is written in two scripts, and a Serbian book in Cyrillic and
// a Croatian one in Latin must find the same entry. Wiktionary has a page for
// each spelling, but not always a link from one to the other, so the pipeline
// adds the other script of every headword as a form: a key that is not itself
// a headword then reaches its entry through `.syn`.

const Map<String, String> _toLatin = {
  'а': 'a',
  'б': 'b',
  'в': 'v',
  'г': 'g',
  'д': 'd',
  'ђ': 'đ',
  'е': 'e',
  'ж': 'ž',
  'з': 'z',
  'и': 'i',
  'ј': 'j',
  'к': 'k',
  'л': 'l',
  'љ': 'lj',
  'м': 'm',
  'н': 'n',
  'њ': 'nj',
  'о': 'o',
  'п': 'p',
  'р': 'r',
  'с': 's',
  'т': 't',
  'ћ': 'ć',
  'у': 'u',
  'ф': 'f',
  'х': 'h',
  'ц': 'c',
  'ч': 'č',
  'џ': 'dž',
  'ш': 'š',
};

/// The Cyrillic letter of each Latin one, digraphs included.
final Map<String, String> _toCyrillic = {
  for (final e in _toLatin.entries) e.value: e.key,
};

bool _isCyrillic(int rune) => rune >= 0x0400 && rune <= 0x04ff;

/// Whether [word] has a Cyrillic letter.
bool hasCyrillic(String word) => word.runes.any(_isCyrillic);

/// [word] in the other script, or null when it has no letter to change or a
/// letter outside the Serbo-Croatian alphabet (`q`, `w`, `x`, `y`).
String? otherScript(String word) =>
    hasCyrillic(word) ? _cyrillicToLatin(word) : _latinToCyrillic(word);

String? _cyrillicToLatin(String word) {
  final out = StringBuffer();
  final letters = word.split('');
  for (var i = 0; i < letters.length; i++) {
    final letter = letters[i];
    final lower = letter.toLowerCase();
    final latin = _toLatin[lower];
    if (latin == null) {
      if (_isCyrillic(letter.runes.first)) return null;
      out.write(letter);
    } else if (lower == letter) {
      out.write(latin);
    } else if (latin.length == 1) {
      out.write(latin.toUpperCase());
    } else {
      // A capital digraph is `Lj` at the start of a word and `LJ` in a
      // word written in capitals.
      final loud =
          (i > 0 && letters[i - 1] != letters[i - 1].toLowerCase()) ||
          (i + 1 < letters.length &&
              letters[i + 1] != letters[i + 1].toLowerCase());
      out.write(
        loud
            ? latin.toUpperCase()
            : latin[0].toUpperCase() + latin.substring(1),
      );
    }
  }
  final result = out.toString();
  return result == word ? null : result;
}

String? _latinToCyrillic(String word) {
  const digraphs = {'lj', 'nj', 'dž'};
  final out = StringBuffer();
  var changed = false;
  var i = 0;
  while (i < word.length) {
    final pair = i + 1 < word.length ? word.substring(i, i + 2) : '';
    final lowerPair = pair.toLowerCase();
    final piece = digraphs.contains(lowerPair) ? pair : word[i];
    final lowerPiece = piece.toLowerCase();
    final cyrillic = _toCyrillic[lowerPiece];
    if (cyrillic != null) {
      changed = true;
      out.write(piece == lowerPiece ? cyrillic : cyrillic.toUpperCase());
    } else if (piece.toLowerCase() != piece.toUpperCase()) {
      return null;
    } else {
      out.write(piece);
    }
    i += piece.length;
  }
  return changed ? out.toString() : null;
}
