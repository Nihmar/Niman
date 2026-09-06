import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/ime_bridge.dart';
import 'package:copist/src/editor/line_buffer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TextSelection sel(int s) => TextSelection.collapsed(offset: s);

  test('value mirrors the input text and selection', () {
    final input = ComposingInput('hello');
    final bridge = ImeBridge(input);
    expect(bridge.value.text, 'hello');
    expect(bridge.value.selection, sel(0)); // caret starts at the origin

    input.apply(
      const TextEditingDeltaInsertion(
        oldText: 'hello',
        textInserted: ' world',
        insertionOffset: 5,
        selection: TextSelection.collapsed(offset: 11),
        composing: TextRange.empty,
      ),
    );
    expect(bridge.value.text, 'hello world');
    expect(bridge.value.selection, sel(11)); // caret after the insertion
  });

  test('value carries the composing region while it is open', () {
    final input = ComposingInput('');
    final bridge = ImeBridge(input);
    input.apply(
      const TextEditingDeltaReplacement(
        oldText: '',
        replacementText: 'ni',
        replacedRange: TextRange(start: 0, end: 0),
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      ),
    );
    expect(bridge.value.composing, const TextRange(start: 0, end: 2));
  });

  test('applyDelta forwards to the input and reports the resync flag', () {
    final input = ComposingInput('abc');
    final bridge = ImeBridge(input);
    // A recognized insertion is not a resync, and the buffer updates.
    expect(
      bridge.applyDelta(
        const TextEditingDeltaInsertion(
          oldText: 'abc',
          textInserted: 'd',
          insertionOffset: 3,
          selection: TextSelection.collapsed(offset: 4),
          composing: TextRange.empty,
        ),
        windowStart: 0,
      ),
      isFalse,
    );
    expect(input.text, 'abcd');
  });

  group('ImeWindow.around (M2a fix P2)', () {
    /// A ~900-char, 100-line buffer with a caret line in the middle.
    (ComposingInput, LineBuffer) midBuffer() {
      final lines = List.generate(100, (i) => 'line $i');
      final input = ComposingInput(lines.join('\n'));
      return (input, input.buffer);
    }

    test('is KB-sized, clamped to line starts, contains the caret', () {
      final (input, buffer) = midBuffer();
      final caret = buffer.offsetOf(50, 3);
      input.setSelection(TextSelection.collapsed(offset: caret));

      final window = ImeWindow.around(input);

      // KB-sized: at least the budget, far below the ~900-char buffer...
      // (the buffer is small here, so the window is the whole buffer;
      // the budget bound is checked by the 10K-line benchmark instead).
      expect(window.windowText.length, lessThanOrEqualTo(buffer.textLength));
      // Clamped to a line start.
      expect(buffer.locationOf(window.windowStart).$2, 0);
      // Contains the caret, with room on both sides for line breaks.
      expect(window.windowStart, lessThanOrEqualTo(caret));
      expect(window.windowStart + window.windowText.length, greaterThan(caret));
      // The selection is window-local.
      expect(
        window.windowSelection,
        TextSelection.collapsed(offset: caret - window.windowStart),
      );
    });

    test('a large buffer gets a window around the budget, not the text',
        () {
      final lines = List.generate(10000, (i) => 'line $i');
      final input = ComposingInput(lines.join('\n'));
      final buffer = input.buffer;
      final caret = buffer.offsetOf(5000, 3);
      input.setSelection(TextSelection.collapsed(offset: caret));

      final window = ImeWindow.around(input);

      expect(window.windowText.length, greaterThanOrEqualTo(2048));
      expect(window.windowText.length, lessThan(8192));
      expect(window.windowText.length, lessThan(buffer.textLength ~/ 4));
      // Still clamped to a line start and containing the caret.
      expect(buffer.locationOf(window.windowStart).$2, 0);
      expect(window.windowStart, lessThanOrEqualTo(caret));
      expect(
        window.windowStart + window.windowText.length,
        greaterThan(caret),
      );
    });

    test('the window text matches the buffer region it claims', () {
      final (input, buffer) = midBuffer();
      final caret = buffer.offsetOf(40, 2);
      input.setSelection(TextSelection.collapsed(offset: caret));
      final window = ImeWindow.around(input);

      expect(
        window.windowText,
        buffer.substring(window.windowStart, window.windowStart +
            window.windowText.length),
      );
    });

    test('a wide selection (select-all) falls back to the full buffer', () {
      final lines = List.generate(10000, (i) => 'line $i');
      final input = ComposingInput(lines.join('\n'));
      input.setSelection(
        TextSelection(baseOffset: 0, extentOffset: input.textLength),
      );

      final window = ImeWindow.around(input);

      expect(window.windowStart, 0);
      expect(window.windowText.length, input.textLength);
      expect(window.windowSelection.extentOffset, input.textLength);
    });

    test('an anchor translates window-local deltas into the buffer', () {
      final (input, buffer) = midBuffer();
      final caret = buffer.offsetOf(50, 2);
      input.setSelection(TextSelection.collapsed(offset: caret));
      final window = ImeWindow.around(input);

      // An insertion at window-local offset 0 lands at the window start.
      input.apply(
        TextEditingDeltaInsertion(
          oldText: window.windowText,
          textInserted: 'X',
          insertionOffset: 0,
          selection: const TextSelection.collapsed(offset: 1),
          composing: TextRange.empty,
        ),
        anchor: window.windowStart,
      );
      expect(input.text.codeUnitAt(window.windowStart), 'X'.codeUnitAt(0));
      expect(
        input.selection,
        TextSelection.collapsed(offset: window.windowStart + 1),
      );

      // A deletion at window-local [2, 4) deletes buffer [start+2, start+4).
      final before = input.text;
      input.apply(
        const TextEditingDeltaDeletion(
          oldText: '',
          deletedRange: TextRange(start: 2, end: 4),
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange.empty,
        ),
        anchor: window.windowStart + 1, // after the insertion above
      );
      expect(
        input.text,
        before.replaceRange(
          window.windowStart + 3,
          window.windowStart + 5,
          '',
        ),
      );
    });
  });
}
