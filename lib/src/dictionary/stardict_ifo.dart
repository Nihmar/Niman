/// A pack's `.ifo`: the StarDict 3.0.0 keys and Niman's own (the pack
/// format, docs/records/dictionary.md).
///
/// Read from text, never throwing: a header the engine cannot serve is a
/// pack that is unavailable ([unsupportedReason]), not an exception its
/// callers have to guard.
final class StardictIfo {
  /// An `.ifo` holding [values], the keys as written.
  const new(this.values);

  /// The first line of every `.ifo`.
  static const String magic = "StarDict's dict ifo file";

  /// The `niman-pack` this engine reads.
  static const int supportedPack = 1;

  /// Reads [text], or null when it is not an `.ifo` at all (no magic line).
  static StardictIfo? parse(String text) {
    final lines = text.replaceFirst('\u{FEFF}', '').split(RegExp(r'\r?\n'));
    if (lines.first.trim() != magic) return null;
    final values = <String, String>{};
    for (final line in lines.skip(1)) {
      final equals = line.indexOf('=');
      if (equals <= 0) continue;
      values[line.substring(0, equals).trim()] = line
          .substring(equals + 1)
          .trim();
    }
    return StardictIfo(values);
  }

  /// Every key and value, as written.
  final Map<String, String> values;

  /// `version`: `3.0.0` for a pack of ours.
  String get version => values['version'] ?? '';

  /// `bookname`.
  String get bookName => values['bookname'] ?? '';

  /// `wordcount`: the `.idx` entries.
  int? get wordCount => int.tryParse(values['wordcount'] ?? '');

  /// `synwordcount`: the `.syn` records.
  int? get synWordCount => int.tryParse(values['synwordcount'] ?? '');

  /// `idxfilesize`.
  int? get idxFileSize => int.tryParse(values['idxfilesize'] ?? '');

  /// `idxoffsetbits`: 32 unless the key says 64.
  int get idxOffsetBits => int.tryParse(values['idxoffsetbits'] ?? '') ?? 32;

  /// `sametypesequence`: `h` for a pack of ours; null when entries carry
  /// their own type bytes.
  String? get sameTypeSequence {
    final value = values['sametypesequence'];
    return value == null || value.isEmpty ? null : value;
  }

  /// `author`.
  String get author => values['author'] ?? '';

  /// `website`.
  String get website => values['website'] ?? '';

  /// `description`: the attribution and the wiktextract citation.
  String get description => values['description'] ?? '';

  /// `date`.
  String get date => values['date'] ?? '';

  /// `niman-pack`: the version of the pack format, null when absent.
  int? get nimanPack => int.tryParse(values['niman-pack'] ?? '');

  /// `languages`: the language codes the pack serves (`hr,sr,bs`), empty
  /// when the key is absent.
  List<String> get languages => [
    for (final code in (values['languages'] ?? '').split(','))
      if (code.trim().isNotEmpty) code.trim().toLowerCase(),
  ];

  /// `definitions`: the language the glosses are written in.
  String get definitions => values['definitions'] ?? '';

  /// `source`: where the entries come from (`it.wiktionary`).
  String get source => values['source'] ?? '';

  /// `license`.
  String get license => values['license'] ?? '';

  /// Why the engine cannot read this pack, or null when it can.
  ///
  /// A pack that says a newer format is not an error to log, only one to
  /// leave unused until the app is updated.
  String? get unsupportedReason {
    if (nimanPack != supportedPack) {
      return 'niman-pack ${values['niman-pack'] ?? 'missing'}, '
          'this app reads $supportedPack';
    }
    if (idxOffsetBits != 32 && idxOffsetBits != 64) {
      return 'idxoffsetbits $idxOffsetBits';
    }
    return null;
  }
}
