import 'package:copist/src/editor/highlight_sync.dart';
import 'package:copist/src/editor/line_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Highlighter', () {
    test('first sync builds the document', () {
      final buffer = LineBuffer.fromText('a\nb');
      final highlighter = Highlighter()..sync(buffer);
      expect(highlighter.document, isNotNull);
      expect(highlighter.document!.text, 'a\nb');
    });

    test('a single edit re-tokenizes incrementally (same document)', () {
      final buffer = LineBuffer.fromText('a\nb');
      final highlighter = Highlighter()..sync(buffer);
      final first = highlighter.document;
      buffer.insert(1, 'X'); // "aX\nb"
      highlighter.sync(buffer);
      expect(highlighter.document, same(first));
      expect(highlighter.document!.text, 'aX\nb');
    });

    test('no buffer edit (selection-only) is a no-op', () {
      final buffer = LineBuffer.fromText('abc');
      final highlighter = Highlighter()..sync(buffer);
      final first = highlighter.document;
      highlighter.sync(buffer); // no edit between → no-op
      expect(highlighter.document, same(first));
      expect(buffer.editCount, 0);
    });

    test('edits that accumulate between syncs fall back to a full rebuild', () {
      final buffer = LineBuffer.fromText('ab');
      final highlighter = Highlighter()..sync(buffer);
      final first = highlighter.document;
      buffer
        ..insert(1, 'X') // "aXb"
        ..delete(0, 1); // "Xb"
      highlighter.sync(buffer);
      expect(highlighter.document, isNot(same(first)));
      expect(highlighter.document!.text, 'Xb');
    });

    test('editCount and lastEdit track a buffer edit', () {
      final buffer = LineBuffer.fromText('abc');
      expect(buffer.editCount, 0);
      expect(buffer.lastEdit, isNull);
      buffer.insert(1, 'X'); // "aXbc"
      expect(buffer.editCount, 1);
      final edit = buffer.lastEdit!;
      expect(edit.start, 1);
      expect(edit.end, 1);
      expect(edit.text, 'X');
    });

    test('a no-op replace is not an edit', () {
      final buffer = LineBuffer.fromText('abc')..replace(1, 1, '');
      expect(buffer.editCount, 0);
      expect(buffer.lastEdit, isNull);
    });
  });
}
