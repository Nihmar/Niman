// Serbo-Croatian is written in two scripts, and a Serbian book in Cyrillic and
// a Croatian one in Latin must find the same entry. Wiktionary has a page for
// each spelling, but not always a link from one to the other. Cyrillic to
// Latin is exact (one letter, or one of three digraphs, for each letter), so a
// Cyrillic headword gains its Latin spelling as a form: a key that is not
// itself a headword then reaches the entry through `.syn`. Latin to Cyrillic
// is not exact (`injekcija` is `инјекција`, not `ињекција`), and a wrong key
// can collide with a real word and send a look-up to the wrong lemma, so a
// Latin headword reaches Cyrillic only through Wiktionary's own pages and
// forms.

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

bool _isCyrillic(int rune) => rune >= 0x0400 && rune <= 0x04ff;

/// Whether [word] has a Cyrillic letter.
bool hasCyrillic(String word) => word.runes.any(_isCyrillic);

/// The Latin spelling of the Cyrillic [word], or null when [word] has no
/// Cyrillic letter, or a Cyrillic one outside the Serbo-Croatian alphabet.
String? latinSpelling(String word) =>
    hasCyrillic(word) ? _cyrillicToLatin(word) : null;

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
