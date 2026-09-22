// The block scanner: what each line is, that the blocks tile the document, that
// an incremental re-scan agrees with a fresh one after any edit, and that it
// costs O(change) rather than O(document).
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A document with one of everything the scanner knows.
const String _document = r'''
---
title: A note
tags: [a, b]
---

# Heading

A paragraph
that runs on.

> a quote
> continued

- item one
- item two
  wrapped

1. first
2. second

- [ ] todo
- [x] done

```dart
final x = 1;
```

$$
a = b
$$

    indented code

---

| a | b |
|---|---|
| 1 | 2 |

<div>
html block
</div>

last paragraph
''';

/// The kinds of the blocks over [text], in order.
List<BlockKind> _kinds(String text) {
  final scanner = BlockScanner(SourceBuffer.fromText(text));
  return <BlockKind>[for (final block in scanner.index.blocks) block.kind];
}

/// The list depth of every item block in the scanner, in order.
List<int> _depths(BlockScanner scanner) => <int>[
  for (final block in scanner.index.blocks)
    if (block.kind == BlockKind.listItem) block.listDepth,
];

void main() {
  group('classification', () {
    test('one of everything, in order', () {
      final kinds = _kinds(_document);
      expect(kinds, <BlockKind>[
        BlockKind.frontmatter,
        BlockKind.blank,
        BlockKind.heading,
        BlockKind.blank,
        BlockKind.paragraph,
        BlockKind.blank,
        BlockKind.quote,
        BlockKind.blank,
        BlockKind.listItem,
        BlockKind.listItem,
        BlockKind.blank,
        BlockKind.listItem,
        BlockKind.listItem,
        BlockKind.blank,
        BlockKind.listItem,
        BlockKind.listItem,
        BlockKind.blank,
        BlockKind.fencedCode,
        BlockKind.blank,
        BlockKind.math,
        BlockKind.blank,
        BlockKind.indentedCode,
        BlockKind.blank,
        BlockKind.thematicBreak,
        BlockKind.blank,
        BlockKind.table,
        BlockKind.blank,
        BlockKind.html,
        BlockKind.blank,
        BlockKind.paragraph,
        // The document ends with a terminator, so there is a last empty line.
        BlockKind.blank,
      ]);
    });

    test('a fence swallows everything to its close', () {
      final scanner = BlockScanner(
        SourceBuffer.fromText('```\n# not a heading\n- not a list\n```\n# yes'),
      );
      final blocks = scanner.index.blocks;
      expect(blocks.first.kind, BlockKind.fencedCode);
      expect(blocks.first.endLine, 4);
      expect(blocks.first.fenceInfo, isNull);
      expect(blocks.last.kind, BlockKind.heading);
    });

    test('a fence carries its language', () {
      final scanner = BlockScanner(
        SourceBuffer.fromText('```dart meta\nx\n```'),
      );
      expect(scanner.index.blocks.first.fenceInfo, 'dart');
    });

    test('an unclosed fence runs to the end', () {
      final scanner = BlockScanner(SourceBuffer.fromText('```\nx\ny'));
      expect(scanner.index.blocks, hasLength(1));
      expect(scanner.index.blocks.first.endLine, 3);
    });

    test('a display math block is one block, inline math is not', () {
      final display = _kinds('\$\$\na\n\$\$');
      expect(display, <BlockKind>[BlockKind.math]);

      final inline = _kinds(r'a $x$ b');
      expect(inline, <BlockKind>[BlockKind.paragraph]);
    });

    test('two display blocks in a row are two blocks', () {
      // The line that closes a block starts with `$$` as much as the line that
      // opens one does, and a run of them was read as a single block whose tex
      // was both formulas on two lines (#252).
      final kinds = _kinds('\$\$\na\n\$\$\n\$\$\nb\n\$\$');
      expect(kinds, <BlockKind>[BlockKind.math, BlockKind.math]);
    });

    test('a one-line display is a block, as the preview reads it', () {
      // `math_rule.dart` is the shared definition: a line whose trimmed text
      // is `$$…$$` is single-line *display*, and the preview's MathBlockSyntax
      // parses it as a display block. The scanner alone called it inline.
      expect(_kinds(r'$$x$$'), <BlockKind>[BlockKind.math]);
      expect(_kinds('\$\$x\$\$\n\$\$y\$\$'), <BlockKind>[
        BlockKind.math,
        BlockKind.math,
      ]);
      // A prose line that merely contains one is still a paragraph.
      expect(_kinds(r'a $$x$$ b'), <BlockKind>[BlockKind.paragraph]);
    });

    test('frontmatter is only the leading block', () {
      expect(_kinds('---\na\n---'), <BlockKind>[BlockKind.frontmatter]);
      // A `---` further down is a thematic break, or a setext underline; here
      // it is a break, because a paragraph is not above it.
      expect(_kinds('a\n\n---').last, BlockKind.thematicBreak);
    });

    test('a lazy paragraph stays in its quote', () {
      final scanner = BlockScanner(
        SourceBuffer.fromText('> quoted\nlazy line\n\nout'),
      );
      final blocks = scanner.index.blocks;
      expect(blocks.first.kind, BlockKind.quote);
      expect(
        blocks.first.endLine,
        2,
        reason: 'the lazy line belongs to the quote',
      );
      expect(blocks.last.kind, BlockKind.paragraph);
    });

    test('a wrapped list item is one block, a new marker is another', () {
      final scanner = BlockScanner(
        SourceBuffer.fromText('- one\n  wrapped\n- two'),
      );
      final items = scanner.index.blocks
          .where((block) => block.kind == BlockKind.listItem)
          .toList();
      expect(items, hasLength(2));
      expect(items.first.lineCount, 2);
      expect(items.last.lineCount, 1);
    });

    test('an ordered list is items too', () {
      expect(_kinds('1. a\n2. b'), <BlockKind>[
        BlockKind.listItem,
        BlockKind.listItem,
      ]);
    });

    test('sibling items share a depth, a sublist is one deeper', () {
      // The depth used to be the *content column of the item before*, so
      // siblings came out at different indents — the second item of a list was
      // drawn 14 px right of the first, and the item after a sublist further
      // still (device report, 2026-09-21).
      final scanner = BlockScanner(
        SourceBuffer.fromText(
          '- one\n  - nested\n  - nested two\n- two\n\n1. first\n2. second',
        ),
      );
      expect(_depths(scanner), <int>[0, 1, 1, 0, 0, 0]);
    });

    test('a marker at the parent column is a child, not a sibling', () {
      final scanner = BlockScanner(
        SourceBuffer.fromText('- one\n  - child\n- two'),
      );
      expect(_depths(scanner), <int>[0, 1, 0]);
    });

    test('a growing ordered marker stays one level', () {
      // `9. ` and `10. ` start at the same column: same list, same depth,
      // however much their content columns differ.
      final scanner = BlockScanner(SourceBuffer.fromText('9. a\n10. b\n11. c'));
      expect(_depths(scanner), <int>[0, 0, 0]);
      final ordinals = <int>[
        for (final block in scanner.index.blocks)
          if (block.kind == BlockKind.listItem) block.listOrdinal,
      ];
      expect(ordinals, <int>[9, 10, 11]);
    });

    test('an HTML block ends at its own rule', () {
      // A raw-text block ends at its closing tag, not at a blank line.
      final scanner = BlockScanner(
        SourceBuffer.fromText('<pre>\na\n\nstill inside\n</pre>\nafter'),
      );
      final html = scanner.index.blocks.first;
      expect(html.kind, BlockKind.html);
      expect(html.endLine, 5);
    });

    test('a block-tag HTML block ends at a blank line', () {
      final scanner = BlockScanner(
        SourceBuffer.fromText('<div>\na\n</div>\n\nafter'),
      );
      expect(scanner.index.blocks.first.endLine, 3);
      expect(scanner.index.blocks.last.kind, BlockKind.paragraph);
    });

    test('an indented code block needs a blank line before it', () {
      expect(_kinds('para\n    not code'), <BlockKind>[BlockKind.paragraph]);
      expect(_kinds('para\n\n    code'), <BlockKind>[
        BlockKind.paragraph,
        BlockKind.blank,
        BlockKind.indentedCode,
      ]);
    });

    test(r'an indented `$$` line is code, not a formula', () {
      // The preview's parser runs its indented-code syntax before its math
      // one, so a `$$` line four spaces in never opens a formula — either
      // form of it.
      expect(_kinds('para\n\n    code\n    \$\$\n    x\n    \$\$'), <BlockKind>[
        BlockKind.paragraph,
        BlockKind.blank,
        BlockKind.indentedCode,
      ]);
      expect(_kinds('para\n\n    code\n    \$\$x\$\$'), <BlockKind>[
        BlockKind.paragraph,
        BlockKind.blank,
        BlockKind.indentedCode,
      ]);
    });

    test('a table is one block', () {
      final scanner = BlockScanner(
        SourceBuffer.fromText('| a | b |\n|---|---|\n| 1 | 2 |\n\nafter'),
      );
      expect(scanner.index.blocks.first.kind, BlockKind.table);
      expect(scanner.index.blocks.first.endLine, 3);
    });

    test('a pipe line without a delimiter row is prose', () {
      expect(_kinds('a | b'), <BlockKind>[BlockKind.paragraph]);
    });
  });

  group('the blocks tile the document', () {
    test('every line is in exactly one block', () {
      for (final text in <String>[
        _document,
        '',
        '\n',
        'a',
        '# h',
        '- a\n- b',
      ]) {
        final buffer = SourceBuffer.fromText(text);
        final scanner = BlockScanner(buffer);
        var expected = 0;
        for (final block in scanner.index.blocks) {
          expect(block.startLine, expected, reason: text);
          expect(block.endLine, greaterThan(block.startLine));
          expected = block.endLine;
        }
        expect(expected, buffer.lineCount, reason: text);
      }
    });

    test('blockAt finds the block a line is in', () {
      final buffer = SourceBuffer.fromText(_document);
      final scanner = BlockScanner(buffer);
      for (var line = 0; line < buffer.lineCount; line++) {
        final block = scanner.index.blockAt(line);
        expect(block, isNotNull);
        expect(block!.contains(line), isTrue, reason: 'line $line in $block');
      }
    });
  });

  group('incremental rescanning', () {
    test(
      'an edit at the top, the middle and the end agrees with a fresh scan',
      () {
        final edits = <(int, int, String)>[
          (0, 0, '# added\n'),
          (10, 12, 'replaced\n'),
          (40, 40, '\nnew paragraph\n'),
          (60, 200, ''),
        ];
        for (final (start, end, inserted) in edits) {
          final buffer = SourceBuffer.fromText(_document);
          final scanner = BlockScanner(buffer);
          final edit = buffer.replaceRange(start, end, inserted);
          scanner.edited(edit);

          final fresh = BlockScanner(SourceBuffer.fromText(buffer.text));
          expect(
            scanner.index.blocks.map((b) => b.toString()),
            fresh.index.blocks.map((b) => b.toString()),
            reason: 'edit $start..$end',
          );
        }
      },
    );

    test('random edits agree with a fresh scan', () {
      final random = Random(20260921);
      const alphabet = <String>[
        'a',
        'b',
        ' ',
        '\n',
        '#',
        '-',
        '>',
        '`',
        r'$',
        '|',
      ];
      for (var round = 0; round < 60; round++) {
        var text = _randomDocument(random, alphabet);
        final buffer = SourceBuffer.fromText(text);
        final scanner = BlockScanner(buffer);
        for (var step = 0; step < 6; step++) {
          final start = text.isEmpty ? 0 : random.nextInt(text.length + 1);
          final end = text.isEmpty
              ? 0
              : start + random.nextInt(text.length - start + 1);
          final inserted = random.nextInt(3) == 0
              ? ''
              : _randomDocument(random, alphabet);
          if (start == end && inserted.isEmpty) continue;

          text = text.replaceRange(start, end, inserted);
          final edit = buffer.replaceRange(start, end, inserted);
          scanner.edited(edit);

          final fresh = BlockScanner(SourceBuffer.fromText(buffer.text));
          expect(
            scanner.index.blocks.map((b) => b.toString()),
            fresh.index.blocks.map((b) => b.toString()),
            reason: 'round $round step $step on ${buffer.text}',
          );
        }
      }
    });

    test('lines added and removed here and there, read without settling', () {
      // `index` pays every owed shift, so the test above never sees one
      // owed; `blockAt` reads through them. Edits that add and remove lines
      // at points above and below each other are what owes a shift on top of
      // a shift, in both directions.
      final random = Random(20260922);
      for (var round = 0; round < 40; round++) {
        final lines = <String>[
          for (var at = 0; at < 80; at++)
            switch (random.nextInt(6)) {
              0 => '',
              1 => '# h$at',
              2 => '- item',
              3 => '> quote',
              _ => 'text $at',
            },
        ];
        final buffer = SourceBuffer.fromText(lines.join('\n'));
        final scanner = BlockScanner(buffer);
        for (var step = 0; step < 12; step++) {
          final line = random.nextInt(buffer.lineCount);
          final at = buffer.offsetOfLine(line);
          final edit = switch (random.nextInt(3)) {
            0 => buffer.replaceRange(at, at, '\n\n'),
            1 when line > 0 => buffer.replaceRange(at - 1, at, ''),
            _ => buffer.replaceRange(at, at, 'x\n'),
          };
          scanner.edited(edit);
          final fresh = BlockScanner(SourceBuffer.fromText(buffer.text));
          for (var probe = 0; probe < buffer.lineCount; probe++) {
            expect(
              scanner.blockAt(probe).toString(),
              fresh.blockAt(probe).toString(),
              reason: 'round $round step $step line $probe',
            );
          }
        }
      }
    });

    test('a keystroke in a 10 000-line note re-scans a handful of lines', () {
      // Geometria's size and shape: 2 500 paragraphs of three lines, each
      // followed by a blank, which is the app's worst real note in miniature.
      final document = <String>[
        for (var i = 0; i < 2500; i++)
          'paragraph $i\nwith a second line\nand a third\n',
      ].join('\n');
      final buffer = SourceBuffer.fromText(document);
      final scanner = BlockScanner(buffer);
      expect(buffer.lineCount, greaterThan(9000));
      expect(scanner.index.blocks.length, greaterThan(4000));

      final before = scanner.scannedLineTotal;
      final edit = buffer.insert(buffer.offsetOfLine(5000), 'x');
      scanner.edited(edit);
      final cost = scanner.scannedLineTotal - before;
      expect(cost, lessThan(20), reason: 're-scanned $cost lines');

      final fresh = BlockScanner(SourceBuffer.fromText(buffer.text));
      expect(
        scanner.index.blocks.length,
        fresh.index.blocks.length,
        reason: 'the incremental scan and a fresh one must agree',
      );
    });

    test(
      'a keystroke in the middle of a long note re-scans a handful of lines',
      () {
        // 400 paragraphs, so a scan of the whole document would be thousands of
        // lines and the difference is not noise.
        final document = <String>[
          for (var i = 0; i < 400; i++)
            'paragraph $i line one\nand its second line\n',
        ].join('\n');
        final buffer = SourceBuffer.fromText(document);
        final scanner = BlockScanner(buffer);
        final before = scanner.scannedLineTotal;

        final target = buffer.offsetOfLine(600);
        final edit = buffer.insert(target, 'x');
        scanner.edited(edit);

        final cost = scanner.scannedLineTotal - before;
        expect(cost, lessThan(10), reason: 're-scanned $cost lines');
        expect(scanner.index.blocks.length, greaterThan(300));
        expect(scanner.index.blockAt(600), isNotNull);
      },
    );
  });
}

/// A short random document from [alphabet].
String _randomDocument(Random random, List<String> alphabet) {
  final length = random.nextInt(40);
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    buffer.write(alphabet[random.nextInt(alphabet.length)]);
  }
  return buffer.toString();
}
