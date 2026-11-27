import 'package:niman/src/dictionary/unicode_nfc.dart';

/// What a selection is looked up as: the candidates, in the order they are
/// tried, until one is a key of the pack (docs/records/dictionary.md, "The
/// engine").
///
/// A selection arrives as a book, a PDF or a scan gave it: *Dell’acqua,*
/// with a typographic apostrophe and a comma, a word whose last letters
/// are on the next line (`cam-` and a line break, then `mino`), a ligature
/// where the PDF had two letters. The candidates undo that, in order of how
/// much they change the text, so the nearest to what was selected is the
/// first one found.
final class LookupTerm {
  const new _();

  /// The elided articles and pronouns of the languages that have them: what
  /// comes before the apostrophe of `dell'acqua` or `l'homme`.
  static const Map<String, Set<String>> _elisions = {
    'it': {
      'l', 'un', 'dell', 'all', 'dall', 'nell', 'sull', 'coll', 'pell', //
      'quest', 'quell', 'bell', 'sant', 'c', 'm', 't', 's', 'v', 'n', 'd', //
      'gl', 'anch', 'com', 'dov', 'cos', 'tutt', 'senz', 'mezz',
    },
    'fr': {
      'l', 'd', 'j', 'm', 't', 's', 'n', 'c', 'qu', 'jusqu', 'lorsqu', //
      'puisqu', 'quoiqu', 'presqu',
    },
    'ca': {'l', 'd', 'm', 't', 's', 'n', 'qu'},
  };

  /// The longest selection that is tried whole: a dictionary has *a
  /// priori* and *ice cream*, not a sentence.
  static const int _maxWords = 8;

  static final RegExp _invisible = RegExp(
    '[\u{00AD}\u{200B}\u{2060}\u{FEFF}]',
    unicode: true,
  );

  /// A hyphen at the end of a line, the line break, and the letter the word
  /// goes on with. `¬` is the soft hyphen some PDFs print instead.
  static final RegExp _hyphenBreak = RegExp(
    r'(\p{L})[\-\u{2010}\u{2011}\u{00AC}][ \t]*[\r\n]+\s*(\p{L})',
    unicode: true,
  );

  static final RegExp _whitespace = RegExp(r'\s+');

  static final RegExp _outerPunctuation = RegExp(
    r'^[^\p{L}\p{N}\p{M}]+|[^\p{L}\p{N}\p{M}]+$',
    unicode: true,
  );

  /// The apostrophes a typesetter uses in place of the typewriter's.
  static final RegExp _apostrophes = RegExp(
    '[\u{2019}\u{2018}\u{02BC}\u{00B4}\u{0060}\u{2032}]',
    unicode: true,
  );

  static final RegExp _hasWord = RegExp(r'[\p{L}\p{N}]', unicode: true);

  static final RegExp _elision = RegExp(r"^(\p{L}{1,6})'(.+)$", unicode: true);

  static final RegExp _finalSigma = RegExp(
    '(?<=\\p{L})\u{03C3}(?!\\p{L})',
    unicode: true,
  );

  static const Map<String, String> _ligatures = {
    '\u{FB00}': 'ff',
    '\u{FB01}': 'fi',
    '\u{FB02}': 'fl',
    '\u{FB03}': 'ffi',
    '\u{FB04}': 'ffl',
    '\u{FB05}': 'st',
    '\u{FB06}': 'st',
  };

  /// The language code [language] says (`pt-BR`, `it_IT`) as its primary
  /// subtag, lowercase.
  static String primaryLanguage(String language) =>
      language.split(RegExp('[-_]')).first.toLowerCase();

  /// The candidates for [selection] in the language [language], without
  /// repeats, in the order they are tried.
  ///
  /// The whole selection first, then its first word, since a dictionary has
  /// entries like *a priori*. Each one cleaned, then its elisions undone,
  /// then as it is, lowercased, and capitalized (what a German noun or a
  /// proper name is written as when a text prints it in capitals). The
  /// selection as it was, apart from its whitespace, comes last, for the
  /// entries that begin or end with punctuation (*etc.*, *-ing*).
  static List<String> candidates(String selection, {String language = ''}) {
    final lang = primaryLanguage(language);
    final found = <String>{};
    final loose = _variants(selection);
    final wholes = [
      for (final text in loose)
        if (_tidy(text) case final tidy when tidy.isNotEmpty) tidy,
    ];
    for (final whole in wholes) {
      if (_wordCount(whole) <= _maxWords) found.addAll(_withCases(whole, lang));
    }
    for (final whole in wholes) {
      final first = _firstWord(whole);
      if (first != whole) found.addAll(_withCases(first, lang));
    }
    for (final text in loose) {
      if (_hasWord.hasMatch(text) && _wordCount(text) <= _maxWords) {
        found.add(text);
      }
    }
    return found.toList();
  }

  /// The spellings of the first word of [selection] that its nearest keys
  /// are looked for under: the cases of the word, without the elision's
  /// article.
  static List<String> prefixBases(String selection, {String language = ''}) {
    final lang = primaryLanguage(language);
    for (final text in _variants(selection)) {
      final tidy = _tidy(text);
      if (tidy.isEmpty) continue;
      final first = _firstWord(tidy);
      return _cases(_undoElision(first, lang) ?? first, lang);
    }
    return const [];
  }

  /// [text] with the invisible characters gone, the ligatures expanded, the
  /// whitespace on one line and NFC: one string, or two when a hyphen at a
  /// line end may belong to the word (`well-` and a line break, then
  /// `known`, is `wellknown` or `well-known`; the joined one first).
  static List<String> _variants(String text) {
    var clean = text.replaceAll(_invisible, '');
    for (final MapEntry(:key, :value) in _ligatures.entries) {
      clean = clean.replaceAll(key, value);
    }
    final variants = _hyphenBreak.hasMatch(clean)
        ? [
            clean.replaceAllMapped(_hyphenBreak, (m) => '${m[1]}${m[2]}'),
            clean.replaceAllMapped(_hyphenBreak, (m) => '${m[1]}-${m[2]}'),
          ]
        : [clean];
    return [
      for (final variant in variants)
        UnicodeNfc.compose(variant.replaceAll(_whitespace, ' ').trim()),
    ];
  }

  /// No punctuation around [text], the apostrophes straight.
  static String _tidy(String text) =>
      text.replaceAll(_outerPunctuation, '').replaceAll(_apostrophes, "'");

  static int _wordCount(String text) => ' '.allMatches(text).length + 1;

  /// The first word of [text], tidied again: *word,* of *word, another*.
  static String _firstWord(String text) {
    final space = text.indexOf(' ');
    return space < 0 ? text : _tidy(text.substring(0, space));
  }

  /// [term], then the same with its elision undone, each as it is,
  /// lowercased and capitalized.
  static List<String> _withCases(String term, String language) => [
    ..._cases(term, language),
    if (_undoElision(term, language) case final bare?)
      ..._cases(bare, language),
  ];

  /// [term] without the elided article before its apostrophe, when the
  /// language has them: `dell'acqua` to `acqua`.
  static String? _undoElision(String term, String language) {
    final articles = _elisions[language];
    final match = articles == null ? null : _elision.firstMatch(term);
    if (match == null) return null;
    final article = match[1]!;
    if (!articles!.contains(_lower(article, language))) return null;
    return match[2];
  }

  static List<String> _cases(String term, String language) =>
      {term, _lower(term, language), _capitalized(term, language)}.toList();

  /// Unicode lowercasing, with the Turkish dotted and dotless *i* (`I` is
  /// `ı` there, `İ` is `i`) and the Greek final sigma.
  static String _lower(String term, String language) {
    final source = language == 'tr'
        ? term.replaceAll('I', '\u{0131}').replaceAll('\u{0130}', 'i')
        : term;
    return source.toLowerCase().replaceAll(_finalSigma, '\u{03C2}');
  }

  /// [term] with its first letter in capitals and the rest lowercased.
  static String _capitalized(String term, String language) {
    if (term.isEmpty) return term;
    final first = String.fromCharCode(term.runes.first);
    final rest = term.substring(first.length);
    final upper = language == 'tr' && first == 'i'
        ? '\u{0130}'
        : language == 'tr' && first == '\u{0131}'
        ? 'I'
        : first.toUpperCase();
    return upper + _lower(rest, language);
  }
}
