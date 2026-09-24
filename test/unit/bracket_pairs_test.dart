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
}
