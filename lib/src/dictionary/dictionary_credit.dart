import 'package:niman/src/dictionary/stardict_ifo.dart';

/// Where a pack's words come from, as its `.ifo` says: what the panel prints
/// at its foot and the settings list.
///
/// The packs are CC BY-SA 4.0 and GFDL, Wiktionary's licences, so every
/// entry carries its credit.
final class DictionaryCredit {
  /// A credit for the pack named [bookName].
  const new({
    required this.bookName,
    this.license = '',
    this.source = '',
    this.definitions = '',
    this.website = '',
    this.description = '',
  });

  /// The credit an `.ifo` carries.
  factory fromIfo(StardictIfo ifo) => DictionaryCredit(
    bookName: ifo.bookName,
    license: ifo.license,
    source: ifo.source,
    definitions: ifo.definitions,
    website: ifo.website,
    description: ifo.description,
  );

  /// The pack's name (`bookname`).
  final String bookName;

  /// Its licence (`CC BY-SA 4.0; GFDL`).
  final String license;

  /// Where the entries come from (`it.wiktionary+en.wiktionary`).
  final String source;

  /// The language the glosses are written in.
  final String definitions;

  /// The pack's website.
  final String website;

  /// The attribution and the wiktextract citation.
  final String description;
}
