import 'package:niman/src/dictionary/dictionary_form.dart';
import 'package:niman/src/dictionary/dictionary_sense.dart';

/// One part of speech of an entry: its senses, in order.
final class DictionarySection {
  /// A section of the part of speech [pos] with its [senses].
  const new(
    this.pos, {
    this.tags = const [],
    this.senses = const [],
    this.formOf = const [],
  });

  /// wiktextract's part-of-speech code (`noun`, `verb`, `adj`), empty for
  /// an entry that did not say.
  final String pos;

  /// The section's tags (`masculine`, `plural`).
  final List<String> tags;

  /// The numbered senses.
  final List<DictionarySense> senses;

  /// The lemmas this section is an inflected form of ("plural of
  /// *camino*"); each is a look-up of its own. Empty for a lemma.
  final List<DictionaryForm> formOf;
}
