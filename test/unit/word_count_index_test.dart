// The word count kept by the edits (docs/records/huge-notes.md, item 2).
//
// What it has to be: the answer the whole text gives, reached by counting
// the lines an edit touched and nothing else — and never by joining the
// note.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/editor/word_count.dart';
import 'package:niman/src/editor/word_count_index.dart';
import 'package:niman/src/markdown/block_index.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface_controller.dart';

/// What counting the whole text would say.
int joined(SourceBuffer buffer) => countWords(buffer.text);

void main() {
  test(
    'a count worked out in the background is taken, not redone here',
    () async {
      // The controller counted the note in an isolate, threw the answer away
      // and counted it again on the UI isolate: 246 MB of words, seconds with
      // the window frozen, on every open of the stress note.
      final buffer = SourceBuffer.fromText('one two\nthree\n' * 200);
      final controller = MarkdownSurfaceController(buffer);
      final before = WordCount.linesCountedHere;
      await controller.buildWords();
      expect(controller.words.words, joined(buffer));
      expect(
        WordCount.linesCountedHere,
        before,
        reason: 'no line was counted on this isolate',
      );
    },
  );
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
      '  ## two spaces ##\n\n# top\n',
      '- item\n\n  # in the item\n',
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

  group('the count is of the text, not of the syntax (#1051)', () {
    int counted(String text) => WordCount.of(SourceBuffer.fromText(text)).words;

    test("the marks before a line's text are not words", () {
      for (final (text, expected) in <(String, int)>[
        ('# a b', 2),
        ('## Title', 1),
        ('###### six', 1),
        ('#', 0),
        ('- x y', 2),
        ('* x y', 2),
        ('+ x y', 2),
        ('3. x y', 2),
        ('3) x y', 2),
        ('- [ ] buy milk', 2),
        ('- [x] done', 1),
        ('  - nested item', 2),
        ('> q r', 2),
        ('> > q r', 2),
        ('>q r', 2),
        ('> - x', 1),
        ('> # Heading', 1),
        ('> [!note] A title', 3),
        ('#tag stays a word', 4),
        ('a-b and 5-6', 3),
        ('**bold** text', 2),
      ]) {
        expect(counted(text), expected, reason: text);
      }
    });

    test('a line of only syntax counts zero', () {
      for (final text in <String>[
        '---',
        '***',
        '___',
        '-----',
        '- - -',
        '* * *',
        '  ---  ',
        '> ---',
        '|---|---|',
        '| --- | :-: | --: |',
        '---|---',
        '```',
        '```dart',
        '~~~',
        '~~~~ python',
        '   ```',
        '> ```',
        '-',
        '1.',
        '- [ ]',
      ]) {
        expect(counted(text), 0, reason: text);
      }
    });

    test('what only looks like syntax is text', () {
      for (final (text, expected) in <(String, int)>[
        ('--', 1),
        ('``` inline ```', 3),
        ('    ```', 1),
        ('`` x', 2),
        ('-- dash --', 3),
      ]) {
        expect(counted(text), expected, reason: text);
      }
    });

    test("a table row is its cells' words, the pipes are not", () {
      expect(counted('| a | b c |'), 3);
      expect(counted('|a|b|'), 2);
      expect(counted('a | b'), 3, reason: 'not a row: no leading pipe');
      expect(counted('| a | b |\n|---|---|\n| c | d |'), 4);
    });

    test('frontmatter counts zero, and only the leading block', () {
      const note =
          '---\ntitle: A title\ntags: [a, b]\n---\n\n# Heading\nbody text\n';
      expect(counted(note), 3);
      expect(counted('---\ntitle: x\n...\nbody'), 1);
      expect(counted('text\n---\ntitle: x\n---\nbody'), 4);
      expect(counted('---\nno closing mark\nbody text'), 5);
    });

    test("a fence counts its lines' words, not its marks", () {
      expect(counted('```dart\nvar x = 1;\n```'), 4);
    });

    test('a prose note counts as it did', () {
      expect(counted('One two\nthree four five\n\nsix'), 6);
    });

    test('each edit leaves the count the whole text gives', () {
      final random = Random(1051);
      const lines = <String>[
        '# Title words',
        '## Sub',
        '- item one',
        '  - nested item',
        '1. first',
        '- [ ] task here',
        '> quote text',
        '> > deeper quote',
        '> [!note] Callout',
        '---',
        '***',
        '|---|---|',
        '| a | b c |',
        '```dart',
        '```',
        'plain words on a line',
        '',
        '---',
        '...',
        'title: x y',
      ];
      for (var round = 0; round < 200; round++) {
        final parts = <String>[
          for (var i = random.nextInt(14); i > 0; i--)
            lines[random.nextInt(lines.length)],
        ];
        // Half the notes open with a frontmatter block, closed or not.
        if (random.nextBool()) parts.insert(0, '---');
        final buffer = SourceBuffer.fromText(parts.join('\n'));
        final words = WordCount.of(buffer);
        for (var step = 0; step < 12; step++) {
          final line = random.nextInt(buffer.lineCount);
          final start = buffer.offsetOfLine(line);
          final end = start + buffer.lineLengthAt(line);
          final edit = switch (random.nextInt(5)) {
            // A line replaced by another.
            0 => buffer.replaceRange(
              start,
              end,
              lines[random.nextInt(lines.length)],
            ),
            // A line inserted before it.
            1 => buffer.replaceRange(
              start,
              start,
              '${lines[random.nextInt(lines.length)]}\n',
            ),
            // The line and its break gone (the last line has no break).
            2 =>
              line + 1 < buffer.lineCount
                  ? buffer.delete(start, buffer.offsetOfLine(line + 1))
                  : buffer.replaceRange(start, end, ''),
            // A break typed inside the line.
            3 => buffer.insert(
              start + random.nextInt(buffer.lineLengthAt(line) + 1),
              '\n',
            ),
            // A mark typed at the head of the line.
            _ => buffer.replaceRange(start, start, '- '),
          };
          words.edited(edit, buffer);
          expect(
            words.words,
            counted(buffer.text),
            reason: 'round $round step $step: ${buffer.text}',
          );
        }
      }
    });
  });
}
