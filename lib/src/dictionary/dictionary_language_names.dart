/// The English names of the languages the packs hold, for the settings'
/// search: someone looks for *German* as well as *Deutsch*.
///
/// The native names are the app's own (`AppStrings.languageName`); a pack
/// may serve several languages (`niman-sh` serves `hr`, `sr` and `bs`), so
/// [dictionaryEnglishNames] takes all of them.
library;

/// The pack code of Serbo-Croatian, which has no app language of its own:
/// Croatian, Serbian and Bosnian share it.
const String serboCroatianCode = 'sh';

/// The English names of the languages [codes], space-separated; the code is
/// kept for one that has none (a pack the app does not know).
String dictionaryEnglishNames(Iterable<String> codes) =>
    [for (final code in codes) _english[code] ?? code].join(' ');

const Map<String, String> _english = {
  'en': 'English',
  'fr': 'French',
  'de': 'German',
  'es': 'Spanish',
  'pt': 'Portuguese',
  'zh': 'Chinese',
  'ja': 'Japanese',
  'hi': 'Hindi',
  'it': 'Italian',
  'nl': 'Dutch',
  'sv': 'Swedish',
  'nb': 'Norwegian',
  'da': 'Danish',
  'eu': 'Basque',
  'ca': 'Catalan',
  'gl': 'Galician',
  'pl': 'Polish',
  'cs': 'Czech',
  'fi': 'Finnish',
  'ro': 'Romanian',
  'hu': 'Hungarian',
  'hr': 'Croatian',
  'sk': 'Slovak',
  'sl': 'Slovenian',
  'et': 'Estonian',
  'lv': 'Latvian',
  'lt': 'Lithuanian',
  'bg': 'Bulgarian',
  'uk': 'Ukrainian',
  'be': 'Belarusian',
  'sr': 'Serbian',
  'bs': 'Bosnian',
  'mk': 'Macedonian',
  'sq': 'Albanian',
  'el': 'Greek',
  'is': 'Icelandic',
  'tr': 'Turkish',
  serboCroatianCode: 'Serbo-Croatian',
};
