import 'package:copist/src/editor/highlight_style.dart';
import 'package:copist/src/editor/highlighting.dart';
import 'package:copist/src/editor/styled_runs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('styledRuns', () {
    StyledLine line(String text) => HighlightDocument.fromText(text).lineAt(0);

    test('a plain slice is a single unstyled run', () {
      final spans = styledRuns(line('hello world'), 0, 5);
      expect(spans, hasLength(1));
      expect(spans.single.text, 'hello');
      expect(spans.single.style, isNull);
    });

    test('a token inside the slice is styled; the rest is plain', () {
      final spans = styledRuns(line('**bold** text'), 0, 13);
      expect(spans.length, 2);
      expect(spans[0].text, '**bold**');
      expect(spans[0].style, tokenStyle(TokenKind.bold));
      expect(spans[1].text, ' text');
      expect(spans[1].style, isNull);
    });

    test('a continuation row ignores a token that ended before the slice', () {
      // `text` sits at 9..13; the bold ended at 8, so the slice is plain.
      final spans = styledRuns(line('**bold** text'), 9, 13);
      expect(spans, hasLength(1));
      expect(spans.single.text, 'text');
      expect(spans.single.style, isNull);
    });

    test('a slice starting inside a token keeps that token style', () {
      final spans = styledRuns(line('**bold** text'), 3, 11);
      expect(spans.length, 2);
      expect(spans[0].text, 'old**');
      expect(spans[0].style, tokenStyle(TokenKind.bold));
      expect(spans[1].text, ' te');
      expect(spans[1].style, isNull);
    });

    test('a heading marks the marker dim and the title bold', () {
      final spans = styledRuns(line('# Title'), 0, 7);
      expect(spans.length, 2);
      expect(spans[0].text, '#');
      expect(spans[0].style, tokenStyle(TokenKind.headingMarker));
      expect(spans[1].text, ' Title');
      expect(spans[1].style, headingStyle);
    });

    test('a slice past the line end is empty', () {
      expect(styledRuns(line('abc'), 9, 20), isEmpty);
    });
  });
}
