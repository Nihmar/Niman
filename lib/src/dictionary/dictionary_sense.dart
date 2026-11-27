import 'package:niman/src/dictionary/dictionary_run.dart';

/// One numbered meaning of a part of speech: its gloss, the qualifier the
/// source put before it (*figurative*, *rare*), and its examples.
final class DictionarySense {
  /// A sense reading [gloss], with an optional [qualifier] and [examples].
  const new(this.gloss, {this.qualifier, this.examples = const []});

  /// The gloss, in the language the pack's definitions are written in.
  final List<DictionaryRun> gloss;

  /// The sense's qualifier (wiktextract's `raw_tags` or `topics`), as the
  /// source wrote it; null when it has none.
  final String? qualifier;

  /// The example sentences, each a list of runs.
  final List<List<DictionaryRun>> examples;

  /// The gloss without its styles.
  String get text => DictionaryRun.plain(gloss);
}
