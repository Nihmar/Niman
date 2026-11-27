import 'package:flutter/material.dart';
import 'package:niman/src/dictionary/dictionary_entry_group.dart';
import 'package:niman/src/dictionary/dictionary_form.dart';
import 'package:niman/src/dictionary/dictionary_run.dart';
import 'package:niman/src/dictionary/dictionary_section.dart';
import 'package:niman/src/dictionary/dictionary_sense.dart';
import 'package:niman/src/ui/dictionary_panel/definition_text.dart';
import 'package:niman/src/ui/dictionary_panel/grammar_names.dart';
import 'package:niman/src/ui/strings.dart';

/// "From «caminetti», plural": the form read that led to a lemma, or null
/// when the headword itself was read.
String? foundFormLine(DictionaryForm? form) => switch (form) {
  null => null,
  DictionaryForm(:final text, tags: []) => AppStrings.lookUpFromForm(text),
  DictionaryForm(:final text, :final tags) => AppStrings.lookUpFromFormTags(
    text,
    GrammarNames.tags(tags),
  ),
};

/// One entry of the answer: its parts of speech, each with its numbered
/// senses, then its forms.
///
/// The headword is not here when [heading] is false: the first entry's is
/// the panel's title. A section that is an inflected form says which lemma
/// it is of, and that lemma looks itself up through [onFollow].
final class EntryView extends StatelessWidget {
  /// Draws [group]; [onFollow] looks a lemma up.
  const new({
    required this.group,
    required this.onFollow,
    required this.fontSize,
    this.heading = false,
    super.key,
  });

  /// The entry, with the spellings folded into it.
  final DictionaryEntryGroup group;

  /// Looks a word up in the panel.
  final ValueChanged<String> onFollow;

  /// The size of the body text; the rest follows it.
  final double fontSize;

  /// Whether to write the headword and the form read above the senses: for
  /// the entries after the first.
  final bool heading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = group.entry;
    final muted = theme.colorScheme.onSurfaceVariant;
    final from = foundFormLine(entry.foundForm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading) ...[
          Text(
            entry.headword,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (from != null)
            Text(
              from,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          const SizedBox(height: 4),
        ],
        for (final section in entry.sections)
          _Section(section: section, onFollow: onFollow, fontSize: fontSize),
        for (final spelling in group.otherSpellings)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              AppStrings.lookUpAlsoSpelled(spelling),
              key: const Key('lookup-also-spelled'),
              style: TextStyle(fontSize: fontSize - 1, color: muted),
            ),
          ),
        if (entry.forms.isNotEmpty) _Forms(forms: entry.forms, size: fontSize),
      ],
    );
  }
}

final class _Section extends StatelessWidget {
  const new({
    required this.section,
    required this.onFollow,
    required this.fontSize,
  });

  final DictionarySection section;
  final ValueChanged<String> onFollow;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final kind = GrammarNames.describe(section.pos, section.tags);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kind.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                kind,
                style: TextStyle(
                  fontSize: fontSize - 2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: muted,
                ),
              ),
            ),
          for (final lemma in section.formOf)
            _LemmaLink(lemma: lemma, onFollow: onFollow, fontSize: fontSize),
          for (final (i, sense) in section.senses.indexed)
            _Sense(number: i + 1, sense: sense, fontSize: fontSize),
        ],
      ),
    );
  }
}

/// "plural of «camino»": a lemma that looks itself up.
final class _LemmaLink extends StatelessWidget {
  const new({
    required this.lemma,
    required this.onFollow,
    required this.fontSize,
  });

  final DictionaryForm lemma;
  final ValueChanged<String> onFollow;
  final double fontSize;

  @override
  Widget build(BuildContext context) => InkWell(
    key: Key('lookup-lemma-${lemma.text}'),
    onTap: () => onFollow(lemma.text),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        DefinitionText.formOfLine(lemma.tags, lemma.text),
        style: TextStyle(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}

final class _Sense extends StatelessWidget {
  const new({
    required this.number,
    required this.sense,
    required this.fontSize,
  });

  final int number;
  final DictionarySense sense;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final qualifier = sense.qualifier;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$number.',
              style: TextStyle(fontSize: fontSize, color: muted),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: fontSize, height: 1.4),
                    children: [
                      if (qualifier != null && qualifier.isNotEmpty)
                        TextSpan(
                          text: '($qualifier) ',
                          style: TextStyle(color: muted),
                        ),
                      ..._runs(sense.gloss),
                    ],
                  ),
                ),
                for (final example in sense.examples)
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: fontSize - 1,
                        height: 1.4,
                        color: muted,
                        fontStyle: FontStyle.italic,
                      ),
                      children: _runs(example),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The forms of the headword, as a line of words.
final class _Forms extends StatelessWidget {
  const new({required this.forms, required this.size});

  /// The most forms the panel lists: a verb has dozens, and the panel is a
  /// glance at the word, not its table.
  static const int _most = 24;

  final List<DictionaryForm> forms;
  final double size;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final shown = forms.take(_most).map((form) => form.text).toSet();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.lookUpForms,
            style: TextStyle(
              fontSize: size - 2,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            shown.join(' · '),
            key: const Key('lookup-forms'),
            style: TextStyle(fontSize: size, height: 1.4),
          ),
        ],
      ),
    );
  }
}

List<InlineSpan> _runs(List<DictionaryRun> runs) => [
  for (final run in runs)
    TextSpan(
      text: run.text,
      style: TextStyle(
        fontStyle: run.italic ? FontStyle.italic : null,
        fontWeight: run.bold ? FontWeight.w700 : null,
      ),
    ),
];
