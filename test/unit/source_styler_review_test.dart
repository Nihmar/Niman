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

void main() {
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
