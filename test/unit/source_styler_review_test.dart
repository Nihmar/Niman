// What the review of the Markdown editor found in source mode's colours:
// an oversized block is not joined per line (#1326), the marks inside a
// quote are the tree's (#1327), a fence opened on a list marker line is
// coloured where it is (#1328).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
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

/// Line [line] of [document], as `kind[text]` tokens.
List<String> _line(String document, int line) =>
    _describe(SourceStyler(SourceBuffer.fromText(document)), line);

/// How many of line [line]'s tokens are of [kind].
int _count(String document, int line, String kind) =>
    _line(document, line).where((token) => token.startsWith('$kind[')).length;

void main() {
  group("a quote's marks are the tree's, not the lines' look (#1327)", () {
    // Each: what a quote holds that is no heading, list or quote, the kind of
    // mark its lines look as if they carried, and the line they are on.
    for (final (name, text, kind, line) in [
      ('a fence', '> ```sh\n> # comment\n> ```', 'headingMarker', 1),
      ('code with a list in it', '> ```md\n> - a\n> ```', 'listMarker', 1),
      ('code with an ordered list', '> ```md\n> 1. b\n> ```', 'listMarker', 1),
      ('indented code', '>     - x', 'listMarker', 0),
      ('a paragraph with a 2.', '> foo\n> 2. bar', 'listMarker', 1),
      ('a setext underline', '> foo\n> -', 'listMarker', 1),
      ('a math block', '> \$\$\n> - a\n> \$\$', 'listMarker', 1),
    ]) {
      test(name, () {
        expect(_count(text, line, kind), 0, reason: _line(text, line).join());
      });
    }

    test('a quote inside a fence in a quote is no quote mark', () {
      expect(_count('> ```md\n> > c\n> ```', 1, 'blockquote'), 1);
    });

    test('what is a heading, a list and a nested quote still is', () {
      expect(_line('> # h', 0).take(2), ['blockquote[>]', 'headingMarker[#]']);
      expect(_line('> - a', 0).take(2), ['blockquote[>]', 'listMarker[-]']);
      expect(_count('> > b', 0, 'blockquote'), 2);
      expect(_line('> 1. one\n> 2. two', 1), contains('listMarker[2.]'));
      expect(
        _line('> - [ ] todo', 0),
        containsAll(['listMarker[-]', 'taskBox[[ ]]']),
      );
      expect(_line('> text\n> ## h2 ##', 1), contains('headingMarker[##]'));
    });

    test('a list inside a nested quote is marked at its own column', () {
      expect(_line('> > - a', 0).take(3), [
        'blockquote[>]',
        'blockquote[>]',
        'listMarker[-]',
      ]);
    });

    test('a callout body: its marks, its code left alone', () {
      const text = '> [!note] T\n> - a\n> ```\n> - not\n> ```';
      expect(_line(text, 1), contains('listMarker[-]'));
      expect(_count(text, 3, 'listMarker'), 0);
    });

    test('a block too long to parse is matched as it looks', () {
      final text = [
        '> - a',
        for (var i = 0; i < 900; i++) '> ${'word ' * 20}$i',
      ].join('\n');
      expect(_line(text, 0), contains('listMarker[-]'));
    });
  });

  group('a fence opened on a list marker line is coloured where it is '
      '(#1328)', () {
    const text = '- ```js\n  a\n  b\n  ```';

    test('the marker line holds the fence and its language', () {
      expect(_line(text, 0), [
        'listMarker[-]',
        'codeFence[```]',
        'codeLanguage[js]',
      ]);
    });

    test('the first code line is code, not a fence', () {
      expect(_line(text, 1), ['codeBlock[  a]']);
      expect(_line(text, 2), ['codeBlock[  b]']);
    });

    test('the closing fence is a fence', () {
      expect(_line(text, 3), ['codeFence[  ```]']);
    });

    test('a fence on a later line of the item is as it was', () {
      const later = '1. x\n   ```sh\n   y\n   ```';
      expect(_line(later, 1), ['codeFence[   ```]', 'codeLanguage[sh]']);
      expect(_line(later, 2), ['codeBlock[   y]']);
    });

    test('a tilde fence, no language, and a nested item', () {
      expect(_line('- ~~~\n  a\n  ~~~', 0), [
        'listMarker[-]',
        'codeFence[~~~]',
      ]);
      expect(_line('- a\n  - ```py\n    b', 1).last, 'codeLanguage[py]');
      expect(_line('- ```py\n  b', 1), ['codeBlock[  b]']);
    });

    test('a line that only looks like one is not a fence', () {
      expect(_line('- ``` a`b', 0), isNot(contains(startsWith('codeFence'))));
      expect(
        _line('- text ```js', 0),
        isNot(contains(startsWith('codeFence'))),
      );
    });
  });

  group('a block over the inline limit is not joined per line (#1326)', () {
    final long = 'word ' * 20;
    // Each is over 64 KB: a paragraph, a quote, a table.
    final documents = <String, String>{
      'paragraph': [for (var i = 0; i < 900; i++) '$long$i'].join('\n'),
      'quote': [for (var i = 0; i < 900; i++) '> $long$i'].join('\n'),
      'table': [
        '| a | b |',
        '|---|---|',
        for (var i = 0; i < 900; i++) '| ${'x' * 60} | $long$i |',
      ].join('\n'),
    };
    for (final MapEntry(key: name, value: text) in documents.entries) {
      test(name, () {
        expect(text.length, greaterThan(64 * 1024));
        final styler = SourceStyler(SourceBuffer.fromText(text));
        for (var line = 0; line < 60; line++) {
          styler.tokensOf(line);
        }
        expect(styler.blockTextReads, 0, reason: 'no join, ever');
        expect(styler.parses, 0);
        // The edit does not make it one.
        // Inside the first line, after its marker if it has one.
        styler.edited(styler.buffer.replaceRange(3, 3, 'x'));
        for (var line = 0; line < 60; line++) {
          styler
            ..tokensOf(line)
            ..picturesOf(line)
            ..linkHrefAt(line, 0);
        }
        expect(styler.blockTextReads, 0);
      });
    }

    test('its lines keep their structure', () {
      final quote = ['> # head', for (var i = 0; i < 900; i++) '> $long$i'];
      final styler = SourceStyler(SourceBuffer.fromText(quote.join('\n')));
      expect(_describe(styler, 0), ['blockquote[>]', 'headingMarker[#]']);
    });

    test('a block under the limit is parsed', () {
      final styler = SourceStyler(
        SourceBuffer.fromText('a **b**\n${'word ' * 100}'),
      );
      expect(_describe(styler, 0), contains('bold[b]'));
      expect(styler.blockTextReads, 1);
    });
  });
}
