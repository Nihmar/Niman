// The 35 packs and what each is built from (docs/records/dictionary.md, "The
// packs"): the app's 37 languages, with Croatian, Serbian and Bosnian sharing
// one Serbo-Croatian pack.

/// One pack: the language it holds and how wiktextract names it.
final class PackLanguage {
  /// A pack named after the app's language [code] (`niman-<code>`).
  ///
  /// [appCodes] are the app languages it answers for (just [code] by
  /// default), [wiktextractCodes] the `lang_code` values of its entries in
  /// the dumps, and [hasOwnEdition] whether wiktextract extracts that
  /// language's own Wiktionary.
  const new(
    this.code,
    this.name, {
    this.appCodes = const [],
    this.wiktextractCodes = const [],
    this.hasOwnEdition = false,
  });

  /// The code in the pack's id: the app's language id, or `sh`.
  final String code;

  /// The English name, for the `.ifo`'s `bookname`.
  final String name;

  /// The app's language ids the pack serves, when not just [code].
  final List<String> appCodes;

  /// The `lang_code` values its entries carry, when not just [code].
  final List<String> wiktextractCodes;

  /// Whether the language has its own wiktextract edition.
  final bool hasOwnEdition;

  /// `niman-it`.
  String get id => 'niman-$code';

  /// The app languages the `.ifo`'s `languages` lists.
  List<String> get languages => appCodes.isEmpty ? [code] : appCodes;

  /// The `lang_code` values to keep from a dump.
  List<String> get sourceCodes =>
      wiktextractCodes.isEmpty ? [code] : wiktextractCodes;
}

/// Every pack, in the order of the record's table.
const List<PackLanguage> packLanguages = [
  PackLanguage('en', 'English'),
  PackLanguage('fr', 'French', hasOwnEdition: true),
  PackLanguage('de', 'German', hasOwnEdition: true),
  PackLanguage('es', 'Spanish', hasOwnEdition: true),
  PackLanguage('pt', 'Portuguese', hasOwnEdition: true),
  // Mandarin is `cmn` in the English edition and `zh` in Chinese
  // Wiktionary: a reader of Chinese finds both under one pack.
  PackLanguage(
    'zh',
    'Chinese',
    wiktextractCodes: ['zh', 'cmn'],
    hasOwnEdition: true,
  ),
  PackLanguage('ja', 'Japanese', hasOwnEdition: true),
  PackLanguage('it', 'Italian', hasOwnEdition: true),
  PackLanguage('nl', 'Dutch', hasOwnEdition: true),
  PackLanguage('pl', 'Polish', hasOwnEdition: true),
  PackLanguage('cs', 'Czech', hasOwnEdition: true),
  PackLanguage('el', 'Greek', hasOwnEdition: true),
  PackLanguage('tr', 'Turkish', hasOwnEdition: true),
  PackLanguage('hi', 'Hindi'),
  PackLanguage('sv', 'Swedish'),
  PackLanguage('nb', 'Norwegian Bokmal'),
  PackLanguage('da', 'Danish'),
  PackLanguage('eu', 'Basque'),
  PackLanguage('ca', 'Catalan'),
  PackLanguage('gl', 'Galician'),
  PackLanguage('fi', 'Finnish'),
  PackLanguage('ro', 'Romanian'),
  PackLanguage('hu', 'Hungarian'),
  // Wiktionary has no Croatian, Serbian or Bosnian entries of its own: all
  // three are Serbo-Croatian, written in two scripts.
  PackLanguage('sh', 'Serbo-Croatian', appCodes: ['hr', 'sr', 'bs']),
  PackLanguage('sk', 'Slovak'),
  PackLanguage('sl', 'Slovenian'),
  PackLanguage('et', 'Estonian'),
  PackLanguage('lv', 'Latvian'),
  PackLanguage('lt', 'Lithuanian'),
  PackLanguage('bg', 'Bulgarian'),
  PackLanguage('uk', 'Ukrainian'),
  PackLanguage('be', 'Belarusian'),
  PackLanguage('mk', 'Macedonian'),
  PackLanguage('sq', 'Albanian'),
  PackLanguage('is', 'Icelandic'),
];

/// The pack for the language [code] (the pack's own code, or an app id such
/// as `hr` that a pack serves), or null.
PackLanguage? packLanguageFor(String code) {
  for (final language in packLanguages) {
    if (language.code == code || language.languages.contains(code)) {
      return language;
    }
  }
  return null;
}

/// Where kaikki.org publishes the raw extraction of Wiktionary's English
/// edition.
const String englishEditionUrl =
    'https://kaikki.org/dictionary/raw-wiktextract-data.jsonl.gz';

/// Where kaikki.org publishes the raw extraction of the [code] edition.
String ownEditionUrl(String code) =>
    'https://kaikki.org/dictionary/downloads/$code/$code-extract.jsonl.gz';
