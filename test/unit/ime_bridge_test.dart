import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/ime_bridge.dart';
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
      ),
      isFalse,
    );
    expect(input.text, 'abcd');
  });
}
