import 'package:niman/src/dictionary/dictionary_entry.dart';

/// One entry as the panel draws it, with the other spellings that said the
/// same thing and are not drawn again.
///
/// A Serbo-Croatian word is an entry in each script, with the same senses
/// (docs/records/dictionary.md, "What the packs keep"); a reader of the
/// Cyrillic one does not need the Latin one's copy of the definition, only
/// to be told it exists.
final class DictionaryEntryGroup {
  /// [entry], also written as [otherSpellings].
  const new(this.entry, {this.otherSpellings = const []});

  /// The entry that is drawn.
  final DictionaryEntry entry;

  /// The headwords of the entries left out because their senses are the
  /// drawn one's.
  final List<String> otherSpellings;

  /// [entries] as the groups to draw, in their order: an entry whose parts
  /// of speech and senses are exactly those of an earlier one, written in
  /// the other script (Cyrillic against Latin), folds into it. Two lemmas
  /// that happen to gloss alike in one script stay two.
  static List<DictionaryEntryGroup> of(List<DictionaryEntry> entries) {
    final groups = <DictionaryEntryGroup>[];
    final spellings = <List<String>>[];
    for (final entry in entries) {
      final same = groups.indexWhere(
        (group) =>
            group.entry.language == entry.language &&
            _isCyrillic(group.entry.headword) != _isCyrillic(entry.headword) &&
            _senses(group.entry) == _senses(entry),
      );
      if (same >= 0 && _hasSenses(entry)) {
        spellings[same].add(entry.headword);
        continue;
      }
      groups.add(DictionaryEntryGroup(entry));
      spellings.add([]);
    }
    return [
      for (final (i, group) in groups.indexed)
        DictionaryEntryGroup(group.entry, otherSpellings: spellings[i]),
    ];
  }

  static bool _hasSenses(DictionaryEntry entry) =>
      entry.sections.any((section) => section.senses.isNotEmpty);

  static bool _isCyrillic(String word) => RegExp('[Ѐ-ӿ]').hasMatch(word);

  /// What an entry says, the headword aside: each part of speech and its
  /// glosses, as plain text.
  static String _senses(DictionaryEntry entry) => [
    for (final section in entry.sections)
      [
        section.pos,
        section.senses.map((sense) => sense.text).join('\u{2}'),
      ].join('\u{1}'),
  ].join('\u{3}');
}
