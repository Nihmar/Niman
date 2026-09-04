import 'dart:io';

import 'package:copist/src/editor/highlighting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inline tokens', () {
    test('heading marker, then plain content', () {
      final doc = HighlightDocument.fromText('## Title');
      final line = doc.lines.single;
      expect(
        line.tokens,
        [const Token(TokenKind.headingMarker, 0, 2)],
      );
    });

    test('heading with inline math and bold', () {
      final doc = HighlightDocument.fromText(r'# H **b** $x$');
      final line = doc.lines.single;
      expect(line.tokens.map((t) => t.kind), [
        TokenKind.headingMarker,
        TokenKind.bold,
        TokenKind.mathInline,
      ]);
      expect(
        line.tokens.map((t) => '${t.start}-${t.end}').toList(),
        ['0-1', '4-9', '10-13'],
      );
    });

    test('bold, italic, strike, code, links, wikilink, tag', () {
      final doc = HighlightDocument.fromText(
        '**b** *i* ~~s~~ `c` [t](u) [[w]] #tag',
      );
      final kinds = doc.lines.single.tokens.map((t) => t.kind).toList();
      expect(
        kinds,
        [
          TokenKind.bold,
          TokenKind.italic,
          TokenKind.strike,
          TokenKind.codeInline,
          TokenKind.link,
          TokenKind.wikilink,
          TokenKind.tag,
        ],
      );
    });

    test('image token covers the whole ![alt](url)', () {
      final doc = HighlightDocument.fromText('see ![alt](img.png) end');
      final t = doc.lines.single.tokens.single;
      expect(t.kind, TokenKind.image);
      expect('see ![alt](img.png) end'.substring(t.start, t.end),
          '![alt](img.png)');
    });

    test('bold wins over italic at the same position', () {
      final doc = HighlightDocument.fromText('**a**');
      expect(doc.lines.single.tokens.single.kind, TokenKind.bold);
    });

    test('italic * validated against ** runs', () {
      final doc = HighlightDocument.fromText('**bold**');
      expect(doc.lines.single.tokens.map((t) => t.kind), [TokenKind.bold]);
      final doc2 = HighlightDocument.fromText('a *x* b');
      expect(doc2.lines.single.tokens.single.kind, TokenKind.italic);
    });

    test('_ emphasis not intra-word', () {
      final doc = HighlightDocument.fromText('snake_case and _em_');
      final kinds = doc.lines.single.tokens.map((t) => t.kind).toList();
      expect(kinds, [TokenKind.italic]);
      expect(
        doc.lines.single.text.substring(
          doc.lines.single.tokens.single.start,
          doc.lines.single.tokens.single.end,
        ),
        '_em_',
      );
    });

    test('inline code with one backtick inside', () {
      final doc = HighlightDocument.fromText('a ``b`c`` d');
      final t = doc.lines.single.tokens.single;
      expect(t.kind, TokenKind.codeInline);
      expect(doc.lines.single.text.substring(t.start, t.end), '``b`c``');
    });

    test('inline code not closed stays plain', () {
      final doc = HighlightDocument.fromText('a `b c');
      expect(doc.lines.single.tokens, isEmpty);
    });

    test('#tag rules: no space after #, space before', () {
      final doc = HighlightDocument.fromText('a #tag and (not) # x');
      final tokens = doc.lines.single.tokens;
      expect(tokens.map((t) => t.kind), [TokenKind.tag]);
      expect(
        doc.lines.single.text.substring(tokens.single.start, tokens.single.end),
        '#tag',
      );
    });
  });

  group('inline math', () {
    test('basic and multiple on a line', () {
      final doc = HighlightDocument.fromText(r'a $x$ b $y_i$ c');
      final tokens = doc.lines.single.tokens;
      expect(tokens.length, 2);
      for (final t in tokens) {
        expect(t.kind, TokenKind.mathInline);
      }
    });

    test('no math when the open is followed by a space', () {
      final doc = HighlightDocument.fromText(r'5 $ 3 $');
      expect(doc.lines.single.tokens, isEmpty);
    });

    test('escaped dollar is not math', () {
      final doc = HighlightDocument.fromText(r'a \$5 b');
      expect(doc.lines.single.tokens, isEmpty);
    });

    test('no math when the close is followed by a digit', () {
      final doc = HighlightDocument.fromText(r'$x$5');
      expect(doc.lines.single.tokens, isEmpty);
    });
  });

  group('fences', () {
    test('fence block with language, content and close', () {
      final doc = HighlightDocument.fromText(
        'before\n```dart\nint x = 1;\n```\nafter',
      );
      final lines = doc.lines;
      expect(lines[1].tokens.first.kind, TokenKind.codeFence);
      final lang = lines[1]
          .tokens
          .firstWhere((t) => t.kind == TokenKind.codeLanguage);
      expect(lines[1].text.substring(lang.start, lang.end), 'dart');
      expect(lines[2].tokens.single.kind, TokenKind.codeFence);
      expect(lines[3].tokens.single.kind, TokenKind.codeFence);
      expect(lines[4].tokens, isEmpty);
    });

    test('dollar signs inside a fence are not math', () {
      const text = '```\n\$a\$ and \$\$\n```\nafter \$x\$';
      final doc = HighlightDocument.fromText(text);
      final spans = doc.mathSpans();
      expect(spans.length, 1);
      expect(spans.single.block, isFalse);
      expect(doc.text.substring(spans.single.start, spans.single.end), r'$x$');
    });

    test('tilde fence closes on a longer run', () {
      final doc = HighlightDocument.fromText('~~~\ncode\n~~~~');
      expect(doc.lines[2].tokens.single.kind, TokenKind.codeFence);
      final doc2 = HighlightDocument.fromText('~~~\ncode\n~~~~\nplain');
      expect(doc2.lines[3].tokens, isEmpty);
    });
  });

  group('display math', () {
    test('multi-line block', () {
      const text = 'a\n\$\$\nf(x) = x^2\n\$\$\nb';
      final doc = HighlightDocument.fromText(text);
      expect(doc.lines[1].tokens.single.kind, TokenKind.mathBlock);
      expect(doc.lines[2].tokens.single.kind, TokenKind.mathBlock);
      expect(doc.lines[3].tokens.single.kind, TokenKind.mathBlock);
      expect(doc.lines[0].tokens, isEmpty);
      expect(doc.lines[4].tokens, isEmpty);
    });

    test('single-line display math on its own line', () {
      final doc = HighlightDocument.fromText(r'$$E=mc^2$$');
      final t = doc.lines.single.tokens.single;
      expect(t.kind, TokenKind.mathBlock);
      expect(doc.lines.single.text, r'$$E=mc^2$$');
    });

    test('mathSpansIn finds block and inline spans with markers', () {
      const text = 'a \$x\$ mid\n\$\$\n\\int f\n\$\$\n\$\$a+b\$\$';
      final spans = mathSpansIn(text).map((s) => text.substring(s.start, s.end))
          .toList();
      expect(
        spans,
        [r'$x$', '\$\$\n\\int f\n\$\$', r'$$a+b$$'],
      );
    });

    test('mathSpansIn skips fences and frontmatter', () {
      const text = '---\nm: \$x\$\n---\n```\n\$y\$\n```\n\$\$z\$\$';
      final spans = mathSpansIn(text);
      expect(spans.length, 1);
      expect(spans.single.block, isTrue);
    });
  });

  group('frontmatter', () {
    test('leading block is frontmatter', () {
      final doc = HighlightDocument.fromText('---\nt: 1\n---\nbody');
      final kinds =
          doc.lines.map((l) => l.tokens.singleOrNull?.kind).toList();
      expect(kinds, [
        TokenKind.frontmatter,
        TokenKind.frontmatter,
        TokenKind.frontmatter,
        null,
      ]);
    });

    test('--- not on line 0 is not frontmatter', () {
      final doc = HighlightDocument.fromText('body\n---\nmore');
      expect(doc.lines[1].tokens.single.kind, TokenKind.horizontalRule);
    });
  });

  group('lists, quotes, rules', () {
    test('bullet, ordered and task markers', () {
      final doc = HighlightDocument.fromText('- a\n1. b\n- [x] c\n- [ ] d');
      final lines = doc.lines;
      for (final l in lines) {
        expect(l.tokens.first.kind, TokenKind.listMarker);
      }
      expect(lines[2].tokens.any((t) => t.kind == TokenKind.taskBox), isTrue);
      expect(lines[3].tokens.any((t) => t.kind == TokenKind.taskBox), isTrue);
    });

    test('blockquote marker', () {
      final doc = HighlightDocument.fromText('> **quoted**');
      final t = doc.lines.single.tokens;
      expect(t.first.kind, TokenKind.blockquote);
      expect(t.any((t) => t.kind == TokenKind.bold), isTrue);
    });

    test('horizontal rules', () {
      final doc = HighlightDocument.fromText('***\n___\n---\ntext');
      expect(
        doc.lines.map((l) => l.tokens.firstOrNull?.kind),
        [
          TokenKind.horizontalRule,
          TokenKind.horizontalRule,
          TokenKind.horizontalRule,
          null,
        ],
      );
    });
  });

  group('incremental replace', () {
    test('single-character insert matches full re-tokenize', () {
      final doc = HighlightDocument.fromText('abc\ndef')
        ..replace(4, 4, 'X');
      expect(doc.text, 'abc\nXdef');
      expect(
        doc.lines.map((l) => l.text).toList(),
        HighlightDocument.fromText('abc\nXdef').lines.map((l) => l.text),
      );
    });

    test('typed fence opening re-styles following lines incrementally',
        () {
      final doc = HighlightDocument.fromText('a\nb\nc');
      // The buffer ends with an open fence; the incremental path must
      // re-style the lines after the edit exactly like a full re-tokenize.
      doc
        ..replace(1, 1, '```\n')
        ..replace(doc.text.length, doc.text.length, 'code');
      final open = doc.lines.map((l) => l.tokens.map((t) => t.kind).toList());
      final full = HighlightDocument.fromText(doc.text);
      expect(open, full.lines.map((l) => l.tokens.map((t) => t.kind).toList()));
    });

    test('randomized edits stay consistent with full re-tokenization', () {
      final fixture = File('test/fixtures/markdown/fixture-10kb.md')
          .readAsStringSync();
      final random = _SeededRandom(42);
      var text = fixture;
      final doc = HighlightDocument.fromText(text);
      String describe(HighlightDocument d) {
        final sb = StringBuffer();
        for (final ln in d.lines) {
          sb.writeln(ln.text);
          for (final t in ln.tokens) {
            sb.writeln('  ${t.kind} ${t.start}-${t.end}');
          }
        }
        return sb.toString();
      }

      for (var i = 0; i < 500; i++) {
        final len = text.length;
        var start = random.nextInt(len + 1);
        var end = random.nextInt(len + 1);
        if (end < start) {
          final tmp = start;
          start = end;
          end = tmp;
        }
        final snippet = random.nextSnippet();
        doc.replace(start, end, snippet);
        text = text.substring(0, start) + snippet + text.substring(end);
        final expected = HighlightDocument.fromText(text);
        expect(describe(doc), describe(expected), reason: 'edit $i');
        expect(doc.text, text, reason: 'text $i');
      }
    });
  });
}

/// A tiny deterministic PRNG (no dart:math import needed in the test).
class _SeededRandom {
  _SeededRandom(this._state);

  int _state;

  int nextInt(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % max;
  }

  static const _snippets = [
    'x',
    '\n',
    '\n```\n',
    '\n\$\$\n',
    '**',
    r'$',
    '#',
    '[ ] ',
    'word ',
    '\n- ',
    r'\$y\$',
  ];

  String nextSnippet() {
    final s = _snippets[nextInt(_snippets.length)];
    return s;
  }
}
