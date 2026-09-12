// #51: the note offsets are pure functions — pin them directly.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_text_offsets.dart';

void main() {
  group('note text offsets', () {
    const text = '# Hi\n\nbody here\n';

    test('flat offset to line+column and back', () {
      expect(linePosition(text, 0), (line: 0, offset: 0));
      expect(linePosition(text, 4), (line: 0, offset: 4));
      expect(linePosition(text, 6), (line: 2, offset: 0));
      expect(linePosition(text, 9), (line: 2, offset: 3));
      expect(globalOffset(text, 2, 3), 9);
      expect(globalOffset(text, 0, 0), 0);
    });

    test('whole-text and controller selections round-trip', () {
      const whole = TextSelection(baseOffset: 6, extentOffset: 9);
      final lines = codeLineSelection(text, whole);
      expect(lines.baseIndex, 2);
      expect(lines.baseOffset, 0);
      expect(lines.extentIndex, 2);
      expect(lines.extentOffset, 3);
      final back = textSelection(text, lines);
      expect(back.baseOffset, 6);
      expect(back.extentOffset, 9);
    });

    test('codeLineSelection of a collapsed caret', () {
      const whole = TextSelection.collapsed(offset: 6);
      final lines = codeLineSelection(text, whole);
      expect(lines.baseIndex, 2);
      expect(lines.baseOffset, 0);
      expect(lines.extentIndex, 2);
      expect(lines.extentOffset, 0);
      expect(lines.baseIndex == lines.extentIndex, isTrue);
    });

    test('parseOutlineRow reads line|level|text', () {
      final row = parseOutlineRow('12|2|Some|heading');
      expect(row?.line, 12);
      expect(row?.level, 2);
      expect(row?.text, 'Some|heading');
      expect(parseOutlineRow('nope'), isNull);
      expect(parseOutlineRow('1|x|t'), isNull);
    });
  });
}
