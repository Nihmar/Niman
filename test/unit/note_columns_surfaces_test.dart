// A note's columns to the surfaces that read a note without drawing it
// (#729, `docs/records/note-columns.md`, "The other surfaces"): the index,
// the outline, the tidying, the escapes of imported text, and slides.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/markdown_format.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/lint/line_join.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/block_tree.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/text_escape.dart';
import 'package:niman/src/ui/kinds/slides/slide_split.dart';

const String _columns = '''
# Top

:::: columns
::: {.column width="40%"}
## Left
A #tag and [[Linked note]].

> [!note]
> :::: columns
> ::: column
> ### In a callout
> ![[pic.png]]
> :::
> ::::
:::

::: column
## Right
- an item

  :::: columns
  ::: column
  #### In an item #deep
  :::
  ::::
:::
::::

# After
''';

void main() {
  test("a column's tags, wikilinks and embeds are the note's", () {
    final references = noteReferencesOf(_columns);
    expect(references.tags, containsAll(<String>['tag', 'deep']));
    expect(
      references.links.whereType<WikiLink>().map((link) => link.ref.target),
      contains('Linked note'),
    );
    expect(
      references.embeds.whereType<WikiLink>().map((link) => link.ref.target),
      contains('pic.png'),
    );
  });

  test('a heading in a column is an outline entry, read either way', () {
    final buffer = SourceBuffer.fromText(_columns);
    final fromBlocks = outlineOfBlocks(
      BlockScanner(buffer).index,
      buffer.lineAt,
    );
    final fromText = outlineOfText(_columns);
    String described(List<OutlineEntry> entries) => [
      for (final entry in entries) '${entry.line}:${entry.level}:${entry.text}',
    ].join(', ');
    expect(described(fromBlocks), described(fromText));
    expect(
      fromBlocks.map((entry) => entry.text),
      containsAllInOrder(<String>['Top', 'Left', 'Right', 'After']),
    );
  });

  group('tidying', () {
    test('a fence line is never joined to the text beside it', () {
      const text =
          ':::: columns\n::: column\nOne line\nand the next\n:::\n::::\n';
      expect(
        joinWrappedLines(text, inItems: true, outside: true),
        ':::: columns\n::: column\nOne line and the next\n:::\n::::\n',
      );
    });

    test('fences stay as written, and the blank lines beside them', () {
      const text =
          ':::: columns\n::: {.column  width="40%"}  \nLeft\n:::\n\n\n'
          '::: column\nRight\n:::\n::::\n';
      expect(formatMarkdown(text), text);
    });

    test('the blocks inside a column are tidied as anywhere', () {
      expect(
        formatMarkdown(
          ':::: columns\n::: column\n#   Heading\ntext   \n:::\n::::\n',
        ),
        ':::: columns\n::: column\n# Heading\n\ntext\n:::\n::::\n',
      );
    });
  });

  test('a line of imported text opening a fence is escaped', () {
    expect(escapeMarkdownLineStart('::: note'), r'\::: note');
    expect(escapeMarkdownLineStart(':: two'), ':: two');
    // The escaped line opens nothing.
    final tree = BlockTree.of(':::: columns\n${r'\:::'} note\n::::');
    expect(tree.single, isA<ColumnsNode>());
  });

  test('a rule inside columns does not split a slide', () {
    final slides = splitSlides(
      'One\n\n:::: columns\n::: column\na\n\n---\n\nb\n:::\n::::\n\n---\n\nTwo',
    );
    expect(slides, hasLength(2));
    expect(slides.first.markdown, contains('---'));
  });
}
