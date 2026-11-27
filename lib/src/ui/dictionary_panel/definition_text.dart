import 'package:niman/src/dictionary/dictionary_entry.dart';
import 'package:niman/src/dictionary/dictionary_entry_group.dart';
import 'package:niman/src/dictionary/dictionary_section.dart';
import 'package:niman/src/ui/dictionary_panel/grammar_names.dart';
import 'package:niman/src/ui/strings.dart';

/// A definition as plain text: what Copy puts on the clipboard and what
/// *Annotate with the definition* writes as the comment.
///
/// The headword, then each part of speech with its numbered senses, blank
/// lines between the blocks so it reads the same pasted into a note, where
/// the numbered senses are a list. Examples and forms are left out: it is
/// the definition that is copied, not the whole entry.
final class DefinitionText {
  const new _();

  /// The text of [groups], one block per entry.
  static String of(List<DictionaryEntryGroup> groups) =>
      groups.map((group) => _entry(group.entry)).join('\n\n');

  static String _entry(DictionaryEntry entry) => [
    entry.headword,
    for (final section in entry.sections) _section(section),
  ].join('\n\n');

  static String _section(DictionarySection section) {
    final lines = <String>[];
    final kind = GrammarNames.describe(section.pos, section.tags);
    if (kind.isNotEmpty) lines.add(kind);
    for (final lemma in section.formOf) {
      lines.add(formOfLine(lemma.tags, lemma.text));
    }
    for (final (i, sense) in section.senses.indexed) {
      final qualifier = sense.qualifier;
      lines.add(
        '${i + 1}. '
        '${qualifier == null || qualifier.isEmpty ? '' : '($qualifier) '}'
        '${sense.text}',
      );
    }
    return lines.join('\n');
  }

  /// "plural of «camino»", the line a form's section says.
  static String formOfLine(List<String> tags, String lemma) => tags.isEmpty
      ? AppStrings.lookUpFormOfPlain(lemma)
      : AppStrings.lookUpFormOf(GrammarNames.tags(tags), lemma);
}
