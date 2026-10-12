// Brackets typed in pairs: the rules a keystroke cannot show on its own.
// The typing itself, on every embedder, is in source_embedders_test.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/bracket_pairs.dart';
import 'package:niman/src/markdown/source_buffer.dart';

void main() {
  test('over a selection it wraps it, the selection kept inside', () {
    final buffer = SourceBuffer.fromText('a link here\n');
    final edit = BracketPairs().typed(buffer, 2, 6, '[');
    expect(edit, (start: 2, end: 6, text: '[link]', anchor: 3, extent: 7));
  });

  test(r'after a backslash it is only itself: \( wants \)', () {
    final buffer = SourceBuffer.fromText('math \\\n');
    expect(BracketPairs().typed(buffer, 6, 6, '('), isNull);
  });

  test('before a closing bracket it closes itself', () {
    final buffer = SourceBuffer.fromText('()\n');
    final edit = BracketPairs().typed(buffer, 1, 1, '[');
    expect(edit?.text, '[]');
  });

  test('a closing bracket it did not write is typed', () {
    final buffer = SourceBuffer.fromText('(a)\n');
    expect(BracketPairs().typed(buffer, 2, 2, ')'), isNull);
  });

  test('off its line, the pair forgets what it wrote', () {
    final buffer = SourceBuffer.fromText('\nnext\n');
    final pairs = BracketPairs();
    final open = pairs.typed(buffer, 0, 0, '(')!;
    buffer.replaceRange(open.start, open.end, open.text);
    pairs.caretOnLine(1);
    expect(pairs.typed(buffer, 1, 1, ')'), isNull);
  });

  test('Backspace outside an empty pair takes one character', () {
    final buffer = SourceBuffer.fromText('(a)\n');
    expect(BracketPairs().backspace(buffer, 2), isNull);
  });

  test('over a selection the emphasis wraps it too', () {
    final buffer = SourceBuffer.fromText('parola\n');
    final edit = BracketPairs().typed(buffer, 0, 6, '*');
    expect(edit, (start: 0, end: 6, text: '*parola*', anchor: 1, extent: 7));
  });

  group('the Markdown pairs (#718)', () {
    test('* opens an emphasis and the second star steps over it', () {
      expect(typedThrough('**bold**'), '**bold**');
    });

    test('***bold italic*** falls out of the same open and step', () {
      expect(typedThrough('***both***'), '***both***');
    });

    test('_ opens an emphasis the same way', () {
      expect(typedThrough('_italic_'), '_italic_');
    });

    test('a * that opens a list line stays a marker', () {
      expect(typedThrough('* item'), '* item');
    });

    test('_ in snake_case, and a closing word_, are only themselves', () {
      // Typed on from `snake`, and from `word` with the caret at its end.
      expect(typedThrough('_case', at: 5, text: 'snake'), 'snake_case');
      expect(typedThrough('_', at: 4, text: 'word'), 'word_');
    });

    test('a quote opens a pair, and after a word it is only itself', () {
      expect(typedThrough('"quote"'), '"quote"');
      // An apostrophe: typed between the words of `don` + `t`.
      expect(
        typedThrough("'", at: 3, text: 'dont').replaceFirst("'", ''),
        'dont',
      );
    });

    test('the language’s own quotes pair', () {
      expect(typedThrough('«citazione»'), '«citazione»');
      expect(typedThrough('“quote”'), '“quote”');
    });

    test(' < and > are never a pair: a comparison, an autolink, a tag', () {
      expect(typedThrough('a < b'), 'a < b');
      expect(typedThrough('<div>'), '<div>');
      expect(typedThrough('<https://niman.dev>'), '<https://niman.dev>');
    });

    test('Backspace takes an empty emphasis pair it wrote whole', () {
      final buffer = SourceBuffer.fromText('\n');
      final pairs = BracketPairs();
      final open = pairs.typed(buffer, 0, 0, '*')!;
      buffer.replaceRange(open.start, open.end, open.text);
      expect(pairs.backspace(buffer, 1)?.text, '');
    });

    test('Backspace between two stars it did not write takes one (#761)', () {
      // The caret between the closing stars of a bold: `**bold*|*`.
      final bold = SourceBuffer.fromText('**bold**\n');
      expect(BracketPairs().backspace(bold, 7), isNull);
      // Between the opening ones, and inside `***` and `___` rules.
      expect(BracketPairs().backspace(bold, 1), isNull);
      final stars = SourceBuffer.fromText('***\n');
      expect(BracketPairs().backspace(stars, 1), isNull);
      final lows = SourceBuffer.fromText('___\n');
      expect(BracketPairs().backspace(lows, 2), isNull);
    });

    test('Backspace between two quotes it did not write takes one (#761)', () {
      final single = SourceBuffer.fromText("''\n");
      expect(BracketPairs().backspace(single, 1), isNull);
      final double = SourceBuffer.fromText('""\n');
      expect(BracketPairs().backspace(double, 1), isNull);
    });

    test('an empty bracket pair goes whole whoever wrote it', () {
      final buffer = SourceBuffer.fromText('()\n');
      expect(BracketPairs().backspace(buffer, 1)?.text, '');
    });

    test('after a backslash an emphasis is only itself', () {
      expect(typedThrough('*', at: 1, text: r'\'), r'\*');
    });
  });
}

/// Types [keys] one character at a time through a fresh [BracketPairs],
/// over [text] with the caret at [at], as the surface hands them over, and
/// answers the note.
String typedThrough(String keys, {String text = '', int at = 0}) {
  final pairs = BracketPairs();
  final buffer = SourceBuffer.fromText(text);
  var caret = at;
  for (final key in keys.split('')) {
    final edit = pairs.typed(buffer, caret, caret, key);
    if (edit == null) {
      buffer.replaceRange(caret, caret, key);
      caret += 1;
      continue;
    }
    buffer.replaceRange(edit.start, edit.end, edit.text);
    caret = edit.anchor;
  }
  return buffer.text;
}
