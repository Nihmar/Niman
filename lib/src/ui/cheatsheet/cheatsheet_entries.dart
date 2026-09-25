/// What the Markdown cheatsheet shows (#265): every construct Niman reads,
/// each as it is written.
library;

import 'package:flutter/foundation.dart';
import 'package:niman/src/ui/strings.dart';

/// One construct: its name, and an example of it as it is written.
@immutable
final class CheatsheetEntry {
  /// Creates an entry.
  const new({required this.id, required this.title, required this.source});

  /// What tests find it by: `cheat-<id>`.
  final String id;

  /// Its name, in the app's language.
  final String Function() title;

  /// The example, as written. The words in it are English on purpose: the
  /// syntax is the lesson, and it is the same in every language.
  final String source;
}

/// The cheatsheet, in reading order: only what the engine draws, since an
/// example that renders as its own source would teach the wrong thing.
final List<CheatsheetEntry> cheatsheetEntries = <CheatsheetEntry>[
  CheatsheetEntry(
    id: 'headings',
    title: () => AppStrings.cheatHeadings,
    source: '# Heading 1\n## Heading 2\n### Heading 3',
  ),
  CheatsheetEntry(
    id: 'emphasis',
    title: () => AppStrings.cheatEmphasis,
    source: '**bold**, *italic*, ~~struck through~~, ==highlighted==',
  ),
  CheatsheetEntry(
    id: 'html',
    title: () => AppStrings.cheatHtmlFormats,
    source: '<u>underlined</u>, x<sup>2</sup>, H<sub>2</sub>O',
  ),
  CheatsheetEntry(
    id: 'lists',
    title: () => AppStrings.cheatLists,
    source: '- an item\n- another\n  - nested\n\n1. first\n2. second',
  ),
  CheatsheetEntry(
    id: 'checklists',
    title: () => AppStrings.cheatChecklists,
    source: '- [ ] to do\n- [x] done',
  ),
  CheatsheetEntry(
    id: 'quotes',
    title: () => AppStrings.cheatQuotes,
    source: '> A quote\n>\n> > and one inside it',
  ),
  CheatsheetEntry(
    id: 'callouts',
    title: () => AppStrings.cheatCallouts,
    source:
        '> [!tip] A title of its own\n> What it says.\n\n'
        '> [!warning]- Folded until opened\n> Hidden at first.',
  ),
  CheatsheetEntry(
    id: 'links',
    title: () => AppStrings.cheatLinks,
    source: '[a link](https://example.org) and <https://example.org>',
  ),
  CheatsheetEntry(
    id: 'wikilinks',
    title: () => AppStrings.cheatWikilinks,
    source: '[[Note]], [[Note#Heading]], [[Note|shown text]]',
  ),
  CheatsheetEntry(
    id: 'embeds',
    title: () => AppStrings.cheatEmbeds,
    source: '![[image.png]]\n\n![what it shows](image.png)',
  ),
  CheatsheetEntry(
    id: 'tags',
    title: () => AppStrings.cheatTags,
    source: '#idea #work/project',
  ),
  CheatsheetEntry(
    id: 'inline-code',
    title: () => AppStrings.cheatInlineCode,
    source: 'Call `print()` to write it out.',
  ),
  CheatsheetEntry(
    id: 'code',
    title: () => AppStrings.cheatCodeBlocks,
    source: "```dart\nvoid main() {\n  print('hi');\n}\n```",
  ),
  CheatsheetEntry(
    id: 'math',
    title: () => AppStrings.cheatMath,
    source:
        'Inline \$e^{i\\pi} + 1 = 0\$, or on lines of its own:\n\n'
        '\$\$\n\\int_0^1 x^2\\,dx = \\frac{1}{3}\n\$\$',
  ),
  CheatsheetEntry(
    id: 'tables',
    title: () => AppStrings.cheatTables,
    source:
        '| Fruit  | Qty |\n'
        '| ------ | --: |\n'
        '| apples |   3 |\n'
        '| pears  |  12 |',
  ),
  CheatsheetEntry(
    id: 'footnotes',
    title: () => AppStrings.cheatFootnotes,
    source: 'A claim.[^1]\n\n[^1]: Where it comes from.',
  ),
  CheatsheetEntry(
    id: 'rule',
    title: () => AppStrings.cheatRule,
    source: 'Above\n\n---\n\nBelow',
  ),
  CheatsheetEntry(
    id: 'frontmatter',
    title: () => AppStrings.cheatFrontmatter,
    source:
        '---\ntitle: My note\ntags: [work, idea]\n---\nThe note starts here.',
  ),
  CheatsheetEntry(
    id: 'epub-metadata',
    title: () => AppStrings.cheatEpubMetadata,
    source:
        '---\n'
        'title: The book\n'
        'author: [Ada Lovelace, Alan Turing]\n'
        'language: en\n'
        'series: Notes\n'
        'series_index: 2\n'
        'cover: cover.png\n'
        'tags: [geometry, notes]\n'
        'description: What the book is.\n'
        'publisher: Niman Press\n'
        'rights: Public domain\n'
        '---\n'
        "A book's first chapter.",
  ),
  CheatsheetEntry(
    id: 'templates',
    title: () => AppStrings.cheatTemplates,
    source:
        '# {{title}}\nCreated on {{date:YYYY-MM-DD}} at {{time}}.\n\n'
        '{{cursor}}',
  ),
];
