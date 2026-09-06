import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/editor_gestures.dart';
import 'package:copist/src/editor/hit_test.dart';
import 'package:copist/src/editor/line_buffer.dart';
import 'package:copist/src/editor/row_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ComposingInput input;
  late EditorGestures gestures;

  setUp(() {
    // The HitTest and the ComposingInput each own a buffer over the same
    // text, so the pixel→offset mapping lines up with the selection edits.
    input = ComposingInput('ab\ncdefgh\nij');
    final rows = RowModel(LineBuffer.fromText('ab\ncdefgh\nij'), columns: 4);
    gestures = EditorGestures(
      hitTest: HitTest(rows: rows, rowHeight: 10, charWidth: 5),
      input: input,
    );
  });

  test('tap places the caret', () {
    gestures.tapAt(2.5, 0); // offset 1
    expect(input.selection, const TextSelection.collapsed(offset: 1));
  });

  test('drag selects from anchor to drag position (persists on release)',
      () {
    gestures
      ..dragStartAt(0, 15) // offset 3 (line 1 start)
      ..dragTo(2.5, 15); // offset 4
    // The selection persists (no collapse on release, M2a fix P4): the
    // handles and toolbar stay up over it.
    expect(
      input.selection,
      const TextSelection(baseOffset: 3, extentOffset: 4),
    );
  });

  test('drag across rows extends the selection', () {
    gestures
      ..dragStartAt(0, 0) // offset 0
      ..dragTo(2.5, 25); // offset 8
    expect(
      input.selection,
      const TextSelection(baseOffset: 0, extentOffset: 8),
    );
  });

  test('long-press selects the word; a following drag extends it', () {
    gestures.longPressAt(2.5, 15); // offset 4, inside 'cdefgh'
    expect(
      input.selection,
      const TextSelection(baseOffset: 3, extentOffset: 9),
    );
    gestures.dragTo(2.5, 25); // offset 8 (wrapped row 'gh')
    expect(
      input.selection,
      const TextSelection(baseOffset: 3, extentOffset: 8),
    );
  });

  test('the methods report whether the selection changed', () {
    expect(gestures.tapAt(2.5, 0), isTrue); // offset 1
    expect(gestures.tapAt(2.5, 0), isFalse); // same cell again
    expect(gestures.longPressAt(2.5, 15), isTrue); // word 'cdefgh'
    expect(gestures.longPressAt(2.5, 15), isFalse); // same word again
    expect(gestures.dragStartAt(0, 0), isTrue); // offset 0
    expect(gestures.dragTo(2.5, 5), isTrue); // offset 1
    expect(gestures.dragTo(2.5, 5), isFalse); // same offset
  });
}
