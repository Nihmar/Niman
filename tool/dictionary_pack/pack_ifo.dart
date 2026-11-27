// The `.ifo` of a pack: StarDict 3.0.0's keys, then Niman's own
// (docs/records/dictionary.md, "The pack format, version 1").
import 'dart:io';

import 'pack_languages.dart';

/// The version of the format [writeIfo] writes: `niman-pack`.
const int packFormatVersion = 1;

/// The attribution every pack carries in its `description`: the licences of
/// Wiktionary's text, and the citation wiktextract asks for.
const String packAttribution =
    'Definitions from Wiktionary, by Wiktionary contributors, '
    'licensed CC BY-SA 4.0 and GFDL, extracted with wiktextract '
    '(Tatu Ylonen, "Wiktextract: Wiktionary as Machine-Readable Structured '
    'Data", LREC 2022).';

/// What the `.ifo` of a pack says.
typedef IfoFacts = ({
  PackLanguage language,
  String definitions,
  String source,
  int wordCount,
  int synWordCount,
  int idxFileSize,
  String date,
});

/// The text of the `.ifo` for [facts].
String ifoText(IfoFacts facts) {
  final language = facts.language;
  final english = facts.definitions == 'en' && language.code != 'en';
  final edition = facts.source.split('+').first.split('.').first;
  final values = <(String, String)>[
    ('version', '3.0.0'),
    (
      'bookname',
      'Wiktionary ${language.name}${english ? ' (English definitions)' : ''}',
    ),
    ('wordcount', '${facts.wordCount}'),
    ('synwordcount', '${facts.synWordCount}'),
    ('idxfilesize', '${facts.idxFileSize}'),
    ('idxoffsetbits', '32'),
    ('sametypesequence', 'h'),
    ('author', 'Wiktionary contributors'),
    ('website', 'https://$edition.wiktionary.org'),
    ('description', packAttribution),
    ('date', facts.date),
    ('niman-pack', '$packFormatVersion'),
    ('languages', language.languages.join(',')),
    ('definitions', facts.definitions),
    ('source', facts.source),
    ('license', 'CC BY-SA 4.0; GFDL'),
  ];
  final out = StringBuffer("StarDict's dict ifo file\n");
  for (final (key, value) in values) {
    out.write('$key=$value\n');
  }
  return out.toString();
}

/// Writes the `.ifo` of [facts] to [file].
void writeIfo(File file, IfoFacts facts) =>
    file.writeAsStringSync(ifoText(facts));
