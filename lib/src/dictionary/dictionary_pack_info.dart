/// One dictionary pack the app can download, from the generated catalog
/// (`dictionaryPacks` in `dictionary_catalog.dart`): what it holds, and the
/// file that carries it.
final class DictionaryPackInfo {
  /// The pack [id] (`niman-it`), holding [languages] with their glosses in
  /// [definitions], built from [source], published as [fileName] at [url].
  const new(
    this.id, {
    required this.languages,
    required this.definitions,
    required this.source,
    required this.headwords,
    required this.fileName,
    required this.url,
    required this.bytes,
    required this.sha256,
  });

  /// `niman-<code>`, the pack's folder and the stem of its files.
  final String id;

  /// The app's language ids the pack answers for: one, or `hr`, `sr` and
  /// `bs` for the Serbo-Croatian pack.
  final List<String> languages;

  /// The language the glosses are written in: the pack's own language when
  /// its own Wiktionary was used, `en` otherwise.
  final String definitions;

  /// The Wiktionary editions it was built from (`it.wiktionary+en.wiktionary`).
  final String source;

  /// How many headwords the pack holds.
  final int headwords;

  /// The published archive's name (`niman-it.tar`): the pack's four files,
  /// stored in one tar.
  final String fileName;

  /// Where the archive is downloaded from.
  final String url;

  /// The archive's size in bytes.
  final int bytes;

  /// The archive's SHA-256, in lowercase hexadecimal.
  final String sha256;
}
