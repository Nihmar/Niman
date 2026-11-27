import 'package:niman/src/dictionary/dictionary_credit.dart';
import 'package:niman/src/dictionary/lookup_term.dart';
import 'package:niman/src/dictionary/stardict_ifo.dart';

/// A pack found in the dictionaries folder: its id, where it is, the
/// languages it serves, and whether this app can read it.
final class InstalledPack {
  /// The pack [id] in [directory], serving [languages]; [unavailableReason]
  /// says why this app cannot use it, null when it can.
  const new({
    required this.id,
    required this.directory,
    required this.languages,
    required this.ifo,
    this.unavailableReason,
  });

  /// `niman-it`: the folder's name and the stem of every file in it.
  final String id;

  /// The pack's folder, `<support>/dictionary/<id>`.
  final String directory;

  /// The language codes the pack serves: its `.ifo`'s `languages` key
  /// (`hr`, `sr`, `bs` for the Serbo-Croatian pack), or the code in its id
  /// when the key is absent.
  final List<String> languages;

  /// The pack's header.
  final StardictIfo ifo;

  /// Why this app cannot read the pack (a format it does not know, a file
  /// missing), or null when it can.
  final String? unavailableReason;

  /// Whether look-ups can be made in it.
  bool get isAvailable => unavailableReason == null;

  /// Whether the pack serves [language], a code as a book or a library
  /// says it (`it`, `pt-BR`).
  bool serves(String language) =>
      languages.contains(LookupTerm.primaryLanguage(language));

  /// Where the pack's words come from.
  DictionaryCredit get credit => DictionaryCredit.fromIfo(ifo);

  @override
  String toString() => 'InstalledPack($id, $languages)';
}
