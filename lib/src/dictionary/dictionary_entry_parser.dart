import 'package:niman/src/dictionary/dictionary_credit.dart';
import 'package:niman/src/dictionary/dictionary_entry.dart';
import 'package:niman/src/dictionary/dictionary_form.dart';
import 'package:niman/src/dictionary/dictionary_run.dart';
import 'package:niman/src/dictionary/dictionary_section.dart';
import 'package:niman/src/dictionary/dictionary_sense.dart';
import 'package:niman/src/dictionary/entry_node.dart';

/// Reads an entry's HTML, the closed grammar of the pack format
/// (docs/records/dictionary.md), into a [DictionaryEntry].
///
/// What it knows: `h1` (the headword), `section` with `data-pos` and
/// `data-tags`, `ol` and its `li` (the senses), `span.q` (a qualifier),
/// `ul.ex` (the examples), `p.form-of` (the lemma) and `div.forms` with a
/// `span` per form, and `<i>` and `<b>` inside the text. Anything else is
/// read as text: an entry without a `section` becomes one section with one
/// sense holding its words, so a pack that is not ours still answers.
final class DictionaryEntryParser {
  const new _();

  static final RegExp _space = RegExp(r'\s+');

  /// The elements that start a line of their own: the words on either side
  /// of one are not one word.
  static const Set<String> _blocks = {
    'p', 'div', 'li', 'ul', 'ol', 'section', 'h1', 'h2', 'h3', 'h4', 'h5', //
    'h6', 'blockquote', 'table', 'tr', 'td', 'th', 'dl', 'dt', 'dd', 'pre',
  };

  /// The entry [html] describes, for a look-up in [language] that found it
  /// under [matched] (the key, which names the form read when it is not the
  /// headword), from the pack [credit] names.
  static DictionaryEntry parse(
    String html, {
    required String language,
    required String matched,
    required DictionaryCredit credit,
  }) {
    final root = EntryNode.parse(html);
    final heading = root.outermost('h1').firstOrNull;
    final headword = heading == null ? '' : _clean(heading.allText);
    final forms = [
      for (final list in root.outermost('div', 'forms'))
        for (final span in list.outermost('span')) _form(span),
    ];
    var sections = [
      for (final node in root.outermost('section')) _section(node),
    ];
    if (sections.isEmpty) sections = _asText(root);
    final entryHeadword = headword.isEmpty ? matched : headword;
    return DictionaryEntry(
      headword: entryHeadword,
      language: language,
      credit: credit,
      sections: sections,
      forms: forms,
      foundForm: _foundForm(matched, entryHeadword, forms),
    );
  }

  /// The form the look-up read, or null when it read the headword.
  static DictionaryForm? _foundForm(
    String matched,
    String headword,
    List<DictionaryForm> forms,
  ) {
    if (matched == headword) return null;
    for (final form in forms) {
      if (form.text == matched) return form;
    }
    // A key of the `.syn` the entry does not list (an alternative spelling).
    return DictionaryForm(matched);
  }

  static DictionaryForm _form(EntryNode node) => DictionaryForm(
    _clean(node.allText),
    tags: _tags(node.attributes['data-tags']),
  );

  static List<String> _tags(String? value) => [
    for (final tag in (value ?? '').split(_space))
      if (tag.isNotEmpty) tag,
  ];

  static String _clean(String text) => text.replaceAll(_space, ' ').trim();

  static DictionarySection _section(EntryNode node) => DictionarySection(
    node.attributes['data-pos'] ?? '',
    tags: _tags(node.attributes['data-tags']),
    senses: [
      for (final list in node.outermost('ol'))
        for (final item in list.children)
          if (item.isElement('li')) _sense(item),
    ],
    formOf: [for (final lemma in node.outermost('p', 'form-of')) _form(lemma)],
  );

  static DictionarySense _sense(EntryNode item) {
    final qualifier = item.outermost('span', 'q').firstOrNull;
    final qualifierText = qualifier == null ? '' : _clean(qualifier.allText);
    final examples = <List<DictionaryRun>>[];
    for (final list in item.outermost('ul', 'ex')) {
      for (final example in list.outermost('li')) {
        final runs = _runs(example.children);
        if (runs.isNotEmpty) examples.add(runs);
      }
    }
    return DictionarySense(
      _runs(
        item.children,
        skip: (node) => node == qualifier || node.isElement('ul', 'ex'),
      ),
      qualifier: qualifierText.isEmpty ? null : qualifierText,
      examples: examples,
    );
  }

  /// A section made of an entry's words, for an entry that has none of the
  /// grammar's: the heading and the forms are left out, as the panel draws
  /// them itself.
  static List<DictionarySection> _asText(EntryNode root) {
    final runs = _runs(
      root.children,
      skip: (node) => node.isElement('h1') || node.isElement('div', 'forms'),
    );
    if (runs.isEmpty) return const [];
    return [
      DictionarySection('', senses: [DictionarySense(runs)]),
    ];
  }

  /// The runs of [nodes]: text, with `<i>` and `<b>` as styles, the
  /// whitespace collapsed to single spaces and trimmed at both ends.
  static List<DictionaryRun> _runs(
    List<EntryNode> nodes, {
    bool Function(EntryNode node)? skip,
  }) {
    final pieces = <DictionaryRun>[];
    void walk(
      List<EntryNode> list, {
      required bool italic,
      required bool bold,
    }) {
      for (final node in list) {
        if (skip != null && skip(node)) continue;
        switch (node.tag) {
          case null:
            pieces.add(DictionaryRun(node.text, italic: italic, bold: bold));
          case 'br':
            pieces.add(DictionaryRun(' ', italic: italic, bold: bold));
          case 'i' || 'em':
            walk(node.children, italic: true, bold: bold);
          case 'b' || 'strong':
            walk(node.children, italic: italic, bold: true);
          case final tag when _blocks.contains(tag):
            // Two paragraphs are two sentences, not one word.
            pieces.add(const DictionaryRun(' '));
            walk(node.children, italic: italic, bold: bold);
            pieces.add(const DictionaryRun(' '));
          default:
            walk(node.children, italic: italic, bold: bold);
        }
      }
    }

    walk(nodes, italic: false, bold: false);
    return _normalized(pieces);
  }

  /// [pieces] with each whitespace run a single space (also across two
  /// pieces), none at either end, and neighbours of one style merged.
  static List<DictionaryRun> _normalized(List<DictionaryRun> pieces) {
    final runs = <DictionaryRun>[];
    var spaceBefore = true;
    for (final piece in pieces) {
      final collapsed = piece.text.replaceAll(_space, ' ');
      final text = spaceBefore && collapsed.startsWith(' ')
          ? collapsed.substring(1)
          : collapsed;
      if (text.isEmpty) continue;
      spaceBefore = text.endsWith(' ');
      final last = runs.isEmpty ? null : runs.last;
      if (last != null &&
          last.italic == piece.italic &&
          last.bold == piece.bold) {
        runs[runs.length - 1] = DictionaryRun(
          last.text + text,
          italic: piece.italic,
          bold: piece.bold,
        );
      } else {
        runs.add(DictionaryRun(text, italic: piece.italic, bold: piece.bold));
      }
    }
    if (runs.isNotEmpty) {
      final last = runs.last;
      final trimmed = last.text.trimRight();
      if (trimmed.isEmpty) {
        runs.removeLast();
      } else if (trimmed != last.text) {
        runs[runs.length - 1] = DictionaryRun(
          trimmed,
          italic: last.italic,
          bold: last.bold,
        );
      }
    }
    return runs;
  }
}
