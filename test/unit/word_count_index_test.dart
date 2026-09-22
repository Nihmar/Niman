// The word count kept by the edits (docs/dev/huge-notes.md, item 2).
//
// What it has to be: the answer the whole text gives, reached by counting
// the lines an edit touched and nothing else — and never by joining the
// note.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/editor/word_count.dart';
import 'package:niman/src/editor/word_count_index.dart';
import 'package:niman/src/markdown/block_index.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// What counting the whole text would say.
int joined(SourceBuffer buffer) => countWords(buffer.text);

void main() {
  test('a buffer counted line by line is the whole text counted', () {
    for (final text in <String>[
      '',
      'one',
      'one two three',
      'one\ntwo\nthree',
      'one\n\ntwo',
      'a\nb\n\n\nc d e\n',
      'trailing terminator\n',
      '  leading and trailing  \n\n  spaces  ',
      '\u00A0non-breaking\u00A0space\u00A0is one break',
      'mixed\r\nendings\nhere',
      'ünïcödé wörds\nünicode again',
    ]) {
      final buffer = SourceBuffer.fromText(text);
      expect(
        WordCount.of(buffer).words,
        joined(buffer),
        reason: 'for ${text.replaceAll('\n', r'\n')}',
      );
    }
  });

  test('an edit updates the count for the lines it touched', () {
    final buffer = SourceBuffer.fromText('one two\nthree\nfour five six');
    final words = WordCount.of(buffer);
    expect(words.words, joined(buffer));

    // Inside a line.
    words.edited(buffer.replaceRange(3, 4, 'X'), buffer);
    expect(words.words, joined(buffer));

    // A brand new line (Enter).
    words.edited(buffer.insert(7, '\nnew'), buffer);
    expect(words.words, joined(buffer));

    // A join: `new` and `three` become one line, and the break that
    // separated them is gone.
    final breakAt = buffer.text.indexOf('\n', buffer.text.indexOf('new'));
    words.edited(buffer.delete(breakAt, breakAt + 1), buffer);
    expect(words.words, joined(buffer));
    expect(buffer.lineAt(1), 'newthree');

    // A whole line away.
    final last = buffer.offsetOfLine(buffer.lineCount - 1);
    words.edited(buffer.delete(last, buffer.length), buffer);
    expect(words.words, joined(buffer));
  });

  test('a join merges the words either side of the break', () {
    final buffer = SourceBuffer.fromText('a\nb');
    final words = WordCount.of(buffer);
    expect(words.words, 2);
    final breakAt = buffer.offsetOfLine(1) - 1;
    words.edited(buffer.delete(breakAt, breakAt + 1), buffer);
    expect(buffer.text, 'ab');
    expect(words.words, 1);
    expect(joined(buffer), 1);
  });

  test('an unbuilt count answers zero and takes no edit', () {
    final buffer = SourceBuffer.fromText('one two three');
    final words = WordCount();
    expect(words.isCounted, isFalse);
    expect(words.words, 0);
    words.edited(buffer.insert(0, 'x '), buffer);
    expect(words.words, 0);

    words.adopt(buffer);
    expect(words.isCounted, isTrue);
    expect(words.words, joined(buffer));
  });

  test('a scan of a note reads the same headings the text does', () {
    // Every context that decides whether a `#` line is a heading: inside a
    // fence, inside math, the frontmatter, a quote, a list item, an indent,
    // a setext underline. _headingLevel in the two engines agrees on all of
    // them, and this is what holds it that way.
    final cases = <String>[
      '# One\n\n## Two\n\n### Three',
      '---\ntitle: x\n---\n\n# After frontmatter\n',
      '```\n# in a fence\n```\n\n# Real\n',
      '\$\$\n# in math\n\$\$\n\n# After math\n',
      '#no space\n\n#  padded  \n\n###### six\n\n####### seven\n',
      'text\n\n## With **bold** in it\n\n',
      '> # quoted heading\n\n# top\n',
      '- # in a list item\n\n# top\n',
      '    # indented four\n\n# top\n',
      '   # three spaces\n\n# top\n',
      'Setext\n======\n\n# top\n',
    ];
    for (final text in cases) {
      final buffer = SourceBuffer.fromText(text);
      final index = BlockIndex(
        blocks: BlockScanner(buffer).index.blocks,
        revision: buffer.revision,
      );
      String rows(Iterable<OutlineEntry> entries) =>
          entries.map((e) => '${e.line}|${e.level}|${e.text}').join(', ');
      expect(
        rows(outlineOfBlocks(index, buffer.lineAt)),
        rows(outlineOfText(text)),
        reason: 'for ${text.replaceAll('\n', r'\n')}',
      );
    }
  });

  test('a heading block reads its level and its text', () {
    final buffer = SourceBuffer.fromText(
      '# One\n\n## Two\n\n```\n# not a heading\n```\n\n### Three\n',
    );
    final index = BlockIndex(
      blocks: BlockScanner(buffer).index.blocks,
      revision: buffer.revision,
    );
    expect(
      outlineOfBlocks(
        index,
        buffer.lineAt,
      ).map((e) => (e.line, e.level, e.text)).toList(),
      <(int, int, String)>[(0, 1, 'One'), (2, 2, 'Two'), (8, 3, 'Three')],
    );
  });
}
