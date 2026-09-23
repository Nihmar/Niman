// Source mode's colours from the read view's engine: the block a line is in
// gives its structure, the block's parse its inline runs, and each run's
// markers come out as tokens of their own. Checked as `kind[text]` strings,
// with a `*` on a marker, so a failure reads as the line it is about.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_styler.dart';

/// Line [line]'s tokens as `kind[text]`, a marker starred.
List<String> _describe(SourceStyler styler, int line) {
  final text = styler.buffer.lineAt(line);
  return <String>[
    for (final token in styler.tokensOf(line)) _token(text, token),
  ];
}

String _token(String text, Token token) {
  final mark = token.marker ? '*' : '';
  return '${token.kind.name}$mark[${text.substring(token.start, token.end)}]';
}

List<String> _line(String document, [int line = 0]) =>
    _describe(SourceStyler(SourceBuffer.fromText(document)), line);

void main() {
  group('inline runs, their markers apart', () {
    test('strong, emphasis and strikethrough', () {
      expect(_line('a **b** c'), ['bold*[**]', 'bold[b]', 'bold*[**]']);
      expect(_line('a _b_ c'), ['italic*[_]', 'italic[b]', 'italic*[_]']);
      expect(_line('a ~~b~~'), ['strike*[~~]', 'strike[b]', 'strike*[~~]']);
    });

    test('nesting takes the innermost construct', () {
      expect(_line('**a *b* c**'), [
        'bold*[**]',
        'bold[a ]',
        'italic*[*]',
        'italic[b]',
        'italic*[*]',
        'bold[ c]',
        'bold*[**]',
      ]);
    });

    test('a link and an image', () {
      expect(_line('see [t](u) now'), ['link*[[]', 'link[t]', 'link*[](u)]']);
      expect(_line('![a](p.png)'), [
        'image*[![]',
        'image[a]',
        'image*[](p.png)]',
      ]);
    });

    test("the engine's own constructs: code, maths, wikilinks, tags", () {
      expect(_line('a `c` b'), [
        'codeInline*[`]',
        'codeInline[c]',
        'codeInline*[`]',
      ]);
      expect(_line(r'a $x$ b'), [
        r'mathInline*[$]',
        'mathInline[x]',
        r'mathInline*[$]',
      ]);
      expect(_line('a [[N|b]] c'), [
        'wikilink*[[[]',
        'wikilink[N|b]',
        'wikilink*[]]]',
      ]);
      expect(_line('a #tag b'), ['tag[#tag]']);
    });

    test('code inside strong stays code', () {
      expect(_line('**a `c`**'), [
        'bold*[**]',
        'bold[a ]',
        'codeInline*[`]',
        'codeInline[c]',
        'codeInline*[`]',
        'bold*[**]',
      ]);
    });

    test('a construct over two lines is coloured on both', () {
      // What a line-at-a-time tokenizer could not see.
      const note = '**one\ntwo**';
      final styler = SourceStyler(SourceBuffer.fromText(note));
      expect(_describe(styler, 0), ['bold*[**]', 'bold[one]']);
      expect(_describe(styler, 1), ['bold[two]', 'bold*[**]']);
    });
  });

  group('structure from the block', () {
    test('a heading', () {
      expect(_line('## A **b**'), [
        'headingMarker[##]',
        'bold*[**]',
        'bold[b]',
        'bold*[**]',
      ]);
    });

    test('a list item, with its task box', () {
      expect(_line('- [ ] do *it*'), [
        'listMarker[-]',
        'taskBox[[ ]]',
        'italic*[*]',
        'italic[it]',
        'italic*[*]',
      ]);
      expect(_line('12. item'), ['listMarker[12.]']);
    });

    test('a quote that goes a level deeper marks both of its `>`', () {
      // One block, opened at the first level; the second line's second `>`
      // is syntax as much as its first, and `live` drew it as text.
      const note = '> a\n> > b *c*';
      final styler = SourceStyler(SourceBuffer.fromText(note));
      expect(_describe(styler, 1), [
        'blockquote[>]',
        'blockquote[>]',
        'italic*[*]',
        'italic[c]',
        'italic*[*]',
      ]);
    });

    test('a quote, a list inside it, and its continuation', () {
      const note = '> - a **b**\n> more';
      final styler = SourceStyler(SourceBuffer.fromText(note));
      expect(_describe(styler, 0), [
        'blockquote[>]',
        'listMarker[-]',
        'bold*[**]',
        'bold[b]',
        'bold*[**]',
      ]);
      expect(_describe(styler, 1), ['blockquote[>]']);
    });

    test('a nested quote marks each level', () {
      expect(_line('> > deep'), ['blockquote[>]', 'blockquote[>]']);
    });

    test('a fence: every line code, the opening one with its language', () {
      const note = '```dart\nvar a = **b**;\n```';
      final styler = SourceStyler(SourceBuffer.fromText(note));
      expect(_describe(styler, 0), ['codeFence[```]', 'codeLanguage[dart]']);
      expect(_describe(styler, 1), ['codeFence[var a = **b**;]']);
      expect(_describe(styler, 2), ['codeFence[```]']);
    });

    test('display maths, the frontmatter, a rule and a blank line', () {
      const note = '---\ntitle: x\n---\n\n\$\$\na\n\$\$\n\n***';
      final styler = SourceStyler(SourceBuffer.fromText(note));
      expect(_describe(styler, 1), ['frontmatter[title: x]']);
      expect(_describe(styler, 3), isEmpty);
      expect(_describe(styler, 5), ['mathBlock[a]']);
      expect(_describe(styler, 8), ['horizontalRule[***]']);
    });

    test('a reference link is a link once its definition is there', () {
      const note = 'see [t][r]\n\n[r]: https://x';
      final styler = SourceStyler(SourceBuffer.fromText(note));
      expect(_describe(styler, 0), contains('link[t]'));
    });
  });

  group('edits', () {
    /// A line of a note with the constructs the styler reads.
    String line(Random random) => switch (random.nextInt(14)) {
      0 => '```',
      1 => r'$$',
      2 => '# Heading **b**',
      3 => '- item *it* and `code`',
      4 => '> quoted **bold',
      5 => 'text** closes',
      6 => '',
      7 => '[r]: https://x',
      8 => 'see [t][r] and [[Note]]',
      9 => '    indented',
      10 => '| a | b |',
      11 => '|---|---|',
      _ => 'plain words ${random.nextInt(9)}',
    };

    test('follow the note as a fresh styler would read it', () {
      final random = Random(7);
      for (var round = 0; round < 40; round++) {
        final lines = [for (var at = 0; at < 30; at++) line(random)];
        final buffer = SourceBuffer.fromText(lines.join('\n'));
        final styler = SourceStyler(buffer);
        for (var edit = 0; edit < 10; edit++) {
          // Some lines drawn before the edit, as a screen would have.
          for (var ask = 0; ask < 6; ask++) {
            styler.tokensOf(random.nextInt(buffer.lineCount));
          }
          final length = buffer.length;
          final start = random.nextInt(length + 1);
          final end = min(length, start + random.nextInt(12));
          final inserted = random.nextBool()
              ? '\n${line(random)}'
              : ['*', '`', '\n', 'x', '**', '> ', '- '][random.nextInt(7)];
          styler.edited(buffer.replaceRange(start, end, inserted));
          final fresh = SourceStyler(buffer);
          for (var at = 0; at < buffer.lineCount; at++) {
            expect(
              _describe(styler, at),
              _describe(fresh, at),
              reason:
                  'round $round edit $edit line $at: '
                  '"${buffer.lineAt(at)}"',
            );
          }
        }
      }
    });

    test('a keystroke parses the block it landed in, not the screen', () {
      final lines = [
        for (var at = 0; at < 200; at++) 'Paragraph $at with **bold**.\n',
      ];
      final buffer = SourceBuffer.fromText(lines.join('\n'));
      final styler = SourceStyler(buffer);
      for (var at = 0; at < 60; at++) {
        styler.tokensOf(at);
      }
      final before = styler.parses;
      // A line added at the top moves every block on screen down by one.
      styler.edited(buffer.replaceRange(0, 0, 'new\n'));
      for (var at = 0; at < 61; at++) {
        styler.tokensOf(at);
      }
      expect(styler.parses - before, lessThanOrEqualTo(2));
    });
  });

  test('a long note read in the background reads as one read here', () async {
    final note = [
      for (var at = 0; at < 300; at++) '- item $at with *it*\n\n> q **b**',
    ].join('\n');
    final buffer = SourceBuffer.fromText(note);
    final background = await SourceStyler.inBackground(buffer);
    final here = SourceStyler(buffer);
    expect(background.revision, buffer.revision);
    for (var at = 0; at < buffer.lineCount; at += 7) {
      expect(_describe(background, at), _describe(here, at));
    }
  });

  test('the blocks are there whenever the scan is of the buffer as it is', () {
    // A styler read here, and one that has followed an edit, have scanned the
    // current revision: the shell's tools ask for its blocks to know whether
    // the note has a list, and a null sent them to a pane that had none.
    final buffer = SourceBuffer.fromText('- uno\n- due\n');
    final styler = SourceStyler(buffer);
    expect(styler.blocks?.map((b) => b.kind), contains(BlockKind.listItem));
    styler.edited(buffer.replaceRange(0, 0, 'testo\n\n'));
    expect(styler.blocks?.map((b) => b.kind), contains(BlockKind.listItem));
  });

  test(
    'a background scan the buffer has moved on from has no blocks',
    () async {
      final buffer = SourceBuffer.fromText('- uno\n');
      final pending = SourceStyler.inBackground(buffer);
      buffer.replaceRange(0, 0, 'x');
      final stale = await pending;
      expect(
        stale.blocks,
        isNull,
        reason: 'they are of a text no longer there',
      );
    },
  );
}
