/// A word with its grammatical tags: an inflected form of the headword
/// (`caminetti`, plural), or the lemma a section is a form of (`camino`).
///
/// The tags are wiktextract's (`plural`, `masculine`); the panel says them
/// in the app's language, since a pack holds no words of the interface.
final class DictionaryForm {
  /// [text] with [tags].
  const new(this.text, {this.tags = const []});

  /// The word.
  final String text;

  /// Its tags, possibly none.
  final List<String> tags;

  @override
  String toString() => 'DictionaryForm($text, $tags)';
}
