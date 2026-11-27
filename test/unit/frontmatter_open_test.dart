// What opens the frontmatter: the note's first line `---`, with a closer below
// it. One decision, for the block scan and for the properties panel
// (`frontmatterBlock`); and a container's content, read again by a scan of its
// own, never has one (#1323, #1324).
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/html/tree_html.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_styler.dart';

/// The kind of each block of [text], as the scanner makes them.
List<BlockKind> _kinds(String text) => [
  for (final block in BlockScanner(SourceBuffer.fromText(text)).index.blocks)
    block.kind,
];

/// The last line of the frontmatter block of [text], or -1.
int _frontmatterEnd(String text) {
  final blocks = BlockScanner(SourceBuffer.fromText(text)).index.blocks;
  for (final block in blocks) {
    if (block.kind == BlockKind.frontmatter) return block.endLine - 1;
  }
  return -1;
}

void main() {
  group('an opener with no closer is a rule and the text under it', () {
    for (final text in [
      '---\nhello\n\nworld\n',
      '---\ntitle: x\n\n# h',
      '---',
      '---\n',
      '...\nhello\n\nworld',
      '...',
    ]) {
      final shown = text.replaceAll('\n', r'\n');
      test('$shown: the scanner and frontmatterBlock agree', () {
        expect(frontmatterBlock(text), isNull);
        expect(_kinds(text), isNot(contains(BlockKind.frontmatter)));
        expect(_frontmatterEnd(text), -1);
      });
    }

    test('the body is drawn and exported', () {
      final html = TreeHtml('---\nhello\n\nworld').render();
      expect(html, contains('hello'));
      expect(html, contains('world'));
      expect(html, startsWith('<hr />'));
    });

    test('source mode colours it as the note it is', () {
      final styler = SourceStyler(
        SourceBuffer.fromText('---\ntitle: x\n\n# h\n\n*em*'),
      );
      for (var line = 0; line < 6; line++) {
        expect(
          [for (final t in styler.tokensOf(line)) t.kind.name],
          isNot(contains('frontmatter')),
          reason: 'line $line',
        );
      }
    });

    test('a closer past the window is no closer', () {
      final far = '---\n${'a: b\n' * LineSyntax.frontmatterWindow}---\ntext';
      expect(frontmatterBlock(far), isNull);
      expect(_frontmatterEnd(far), -1);
      final near = '---\n${'a: b\n' * (LineSyntax.frontmatterWindow - 2)}---\n';
      expect(frontmatterBlock(near), isNotNull);
      expect(_frontmatterEnd(near), LineSyntax.frontmatterWindow - 1);
    });
  });

  group('a closed block is frontmatter, for both', () {
    for (final (text, end) in [
      ('---\na: b\n---', 2),
      ('---\na: b\n...', 2),
      ('---\n\n# h\n---\nbody', 3),
      ('---\n---', 1),
      ('  ---\na: b\n---', 2),
    ]) {
      final shown = text.replaceAll('\n', r'\n');
      test(shown, () {
        expect(frontmatterBlock(text)?.endLine, end);
        expect(_frontmatterEnd(text), end);
      });
    }

    test('`...` does not open one', () {
      expect(frontmatterBlock('...\na: b\n---'), isNull);
      expect(_kinds('...\na: b\n---'), isNot(contains(BlockKind.frontmatter)));
    });

    test('only the first line opens it', () {
      expect(
        _kinds('x\n---\na: b\n---'),
        isNot(contains(BlockKind.frontmatter)),
      );
      expect(
        _kinds('\n---\na: b\n---'),
        isNot(contains(BlockKind.frontmatter)),
      );
    });
  });

  group("a container's first line is no frontmatter's", () {
    String html(String markdown) => TreeHtml(markdown).render();

    test('a quote', () {
      expect(html('> ---\n> text'), contains('<hr />'));
      expect(html('> ---\n> text'), contains('<p>text</p>'));
      expect(html('> ---'), contains('<hr />'));
      expect(html('> ...\n> t'), contains('<p>'));
    });

    test('a quote whose rule is read again after text', () {
      final out = html('> ---\n> a\n> ---\n> b');
      expect(out, contains('<h2>a</h2>'));
      expect(out, contains('<p>b</p>'));
    });

    test('an item', () {
      final out = html('1. ---\n   x');
      expect(out, contains('<hr />'));
      expect(out, contains('x'));
    });

    test('a callout body', () {
      final out = html('> [!note]\n> ---\n> text');
      expect(out, contains('<hr />'));
      expect(out, contains('text'));
    });

    test('a quote after a paragraph, and in an item', () {
      expect(html('a\n> ---'), contains('<hr />'));
      expect(html('- a\n  > ---'), contains('<hr />'));
    });

    test('the same lines read in source mode keep their inlines', () {
      List<String> kinds(String text, int line) {
        final styler = SourceStyler(SourceBuffer.fromText(text));
        return [for (final t in styler.tokensOf(line)) t.kind.name];
      }

      expect(kinds('> ---\n> *em* and **b**', 1), contains('italic'));
      expect(kinds('> ---\n> *em* and **b**', 1), contains('bold'));
      expect(
        kinds('> ---\n> *em* and **b**', 1),
        kinds('> x\n> ---\n> *em* and **b**', 2),
      );
    });

    test('the note itself still opens one, with the app syntax on', () {
      expect(html('---\na: b\n---\n\ntext'), '<p>text</p>\n');
    });
  });

  group('a rescan agrees with a fresh scan around the frontmatter', () {
    // Lines that open, close, or break a frontmatter, and ones that are text.
    const pieces = ['---', '---', '...', 'a: b', 'text', '', '# h', '> ---'];

    String describe(BlockScanner scanner, SourceBuffer buffer) {
      final out = StringBuffer();
      for (var line = 0; line < buffer.lineCount; line++) {
        final block = scanner.blockAt(line);
        out.write(
          '$line:${block?.kind.name}:${block?.startLine}-'
          '${block?.endLine};',
        );
      }
      return out.toString();
    }

    test('after every kind of edit, at any budget', () {
      final random = Random(1323);
      for (var round = 0; round < 3000; round++) {
        final initial = [
          for (var i = 0; i < 2 + random.nextInt(8); i++)
            pieces[random.nextInt(pieces.length)],
        ].join('\n');
        final buffer = SourceBuffer.fromText(initial);
        final scanner = BlockScanner(buffer, budget: 1 + random.nextInt(3));
        for (var step = 0; step < 4; step++) {
          final line = random.nextInt(buffer.lineCount);
          final at = buffer.offsetOfLine(line);
          final end = at + buffer.lineAt(line).length;
          final text = pieces[random.nextInt(pieces.length)];
          final edit = switch (random.nextInt(4)) {
            0 => buffer.replaceRange(at, at, '$text\n'),
            1 => buffer.replaceRange(at, end, text),
            2 when line > 0 => buffer.replaceRange(at - 1, at, ''),
            _ => buffer.replaceRange(end, end, '\n$text'),
          };
          scanner.edited(edit);
          if (random.nextBool()) scanner.advance(random.nextInt(4));
          final fresh = BlockScanner(SourceBuffer.fromText(buffer.text));
          expect(
            describe(scanner, buffer),
            describe(fresh, buffer),
            reason: 'from ${initial.replaceAll('\n', r'\n')}, step $step',
          );
        }
      }
    });

    test('a scan taken over by the note keeps what its lines looked at', () {
      final text = '---\n${'a: b\n' * 20}end';
      final scanned = BlockScanner(SourceBuffer.fromText(text));
      final buffer = SourceBuffer.fromText(text);
      final scanner = BlockScanner.rebound(scanned, buffer);
      final at = buffer.offsetOfLine(10);
      scanner.edited(buffer.replaceRange(at, at + 4, '---'));
      expect(scanner.blockAt(0)?.kind, BlockKind.frontmatter);
    });

    test('a closer typed far below, within the window, opens it', () {
      final buffer = SourceBuffer.fromText('---\n${'a: b\n' * 50}end');
      final scanner = BlockScanner(buffer);
      expect(scanner.index.blocks.first.kind, isNot(BlockKind.frontmatter));
      final at = buffer.offsetOfLine(30);
      scanner.edited(buffer.replaceRange(at, at + 4, '---'));
      expect(scanner.blockAt(0)?.kind, BlockKind.frontmatter);
      expect(scanner.blockAt(30)?.kind, BlockKind.frontmatter);
      expect(scanner.blockAt(31)?.kind, isNot(BlockKind.frontmatter));
      final del = buffer.offsetOfLine(30);
      scanner.edited(buffer.replaceRange(del, del + 3, 'a: b'));
      expect(scanner.blockAt(0)?.kind, isNot(BlockKind.frontmatter));
    });
  });
}
