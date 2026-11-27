/// Which language a selection is looked up in (docs/records/dictionary.md,
/// decision 10): what the surface knows, tag by tag, and nothing guessed
/// from the text.
///
/// A book says its own (`dc:language`); a PDF says none, so it is the
/// choice made for that file, else the library's first spelling language;
/// a note or a recognized text is the library's first spelling language.
/// Whatever is left, the app's own language.
library;

import 'package:niman/src/core/language.dart';
import 'package:niman/src/dictionary/dictionary_language_names.dart';

/// The language of a look-up, from the tags the surfaces hold.
final class DictionaryLanguage {
  const new _();

  /// A book's language: its `dc:language` when it names one the app knows,
  /// else [spelling] (the library's spelling languages, as hunspell names
  /// them), else [ui].
  static String forBook(
    String? declared, {
    List<String> spelling = const [],
    String? ui,
  }) => normalise(declared) ?? _fallback(spelling, ui);

  /// A PDF's language: the [chosen] one kept for the file, else [spelling],
  /// else [ui]. A PDF has no language the app can read.
  static String forPdf(
    String? chosen, {
    List<String> spelling = const [],
    String? ui,
  }) => normalise(chosen) ?? _fallback(spelling, ui);

  /// A note's or a recognized text's language: the library's first
  /// spelling language, else [ui].
  static String forNote({List<String> spelling = const [], String? ui}) =>
      _fallback(spelling, ui);

  /// The app's own language, the last resort.
  static String get appLanguage => AppLanguages.resolved.id;

  static String _fallback(List<String> spelling, String? ui) {
    for (final name in spelling) {
      final code = normalise(name);
      if (code != null) return code;
    }
    return normalise(ui) ?? appLanguage;
  }

  /// The language code [tag] says, as the dictionaries name them: its
  /// primary subtag, lowercase, with the cases the packs do not spell the
  /// same way settled. `it-IT`, `it_IT` and `ITA` are `it`; `pt-BR` is
  /// `pt`; `zh-Hans` is `zh`; `no` is `nb`. `sr-Latn`, `hr` and `bs` stay
  /// themselves: the one Serbo-Croatian pack serves the three. Null for a
  /// tag that says nothing a dictionary could use (empty, or a script
  /// only).
  static String? normalise(String? tag) {
    if (tag == null) return null;
    final primary = tag.trim().split(RegExp('[-_.@ ]')).first.toLowerCase();
    if (primary.isEmpty || !_letters.hasMatch(primary)) return null;
    final code = _alpha3[primary] ?? primary;
    return _renamed[code] ?? code;
  }

  static final RegExp _letters = RegExp(r'^[a-z]{2,3}$');

  /// Codes the packs file under another: Norwegian's macrolanguage is
  /// Bokmål's pack, the old Hebrew and Indonesian codes are not ours at
  /// all, and Serbo-Croatian itself is served as `sr`.
  static const Map<String, String> _renamed = {
    'no': 'nb',
    serboCroatianCode: 'hr',
  };

  /// The three-letter codes books use (ISO 639-2, both the terminological
  /// and the bibliographic form) for the app's languages.
  static const Map<String, String> _alpha3 = {
    'eng': 'en',
    'fra': 'fr',
    'fre': 'fr',
    'deu': 'de',
    'ger': 'de',
    'spa': 'es',
    'por': 'pt',
    'zho': 'zh',
    'chi': 'zh',
    'cmn': 'zh',
    'jpn': 'ja',
    'hin': 'hi',
    'ita': 'it',
    'nld': 'nl',
    'dut': 'nl',
    'swe': 'sv',
    'nob': 'nb',
    'nor': 'nb',
    'dan': 'da',
    'eus': 'eu',
    'baq': 'eu',
    'cat': 'ca',
    'glg': 'gl',
    'pol': 'pl',
    'ces': 'cs',
    'cze': 'cs',
    'fin': 'fi',
    'ron': 'ro',
    'rum': 'ro',
    'hun': 'hu',
    'hrv': 'hr',
    'slk': 'sk',
    'slo': 'sk',
    'slv': 'sl',
    'est': 'et',
    'lav': 'lv',
    'lit': 'lt',
    'bul': 'bg',
    'ukr': 'uk',
    'bel': 'be',
    'srp': 'sr',
    'bos': 'bs',
    'mkd': 'mk',
    'mac': 'mk',
    'sqi': 'sq',
    'alb': 'sq',
    'ell': 'el',
    'gre': 'el',
    'isl': 'is',
    'ice': 'is',
    'tur': 'tr',
  };
}
