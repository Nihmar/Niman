import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/note_editor_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

NoteEditorClient _client(
  ComposingInput input, {
  List<TextEditingValue>? pushed,
  void Function(TextInputAction)? onAction,
  VoidCallback? onConnectionClosed,
}) {
  final sink = pushed ?? <TextEditingValue>[];
  return NoteEditorClient(
    input: input,
    onPushValue: sink.add,
    onAction: onAction,
    onConnectionClosed: onConnectionClosed,
  );
}

TextEditingDeltaInsertion _ins(
  String oldText,
  String text,
  int offset, {
  TextRange composing = TextRange.empty,
}) {
  return TextEditingDeltaInsertion(
    oldText: oldText,
    textInserted: text,
    insertionOffset: offset,
    selection: TextSelection.collapsed(offset: offset + text.length),
    composing: composing,
  );
}

void main() {
  group('NoteEditorClient', () {
    test('forwards a lockstep delta sequence without pushing', () {
      final input = ComposingInput('hi');
      final pushed = <TextEditingValue>[];
      _client(input, pushed: pushed).updateEditingValueWithDeltas([
        _ins('hi', ' ', 2),
        _ins('hi ', '!', 3),
      ]);

      expect(input.text, 'hi !');
      expect(input.caret, 4);
      expect(pushed, isEmpty, reason: 'standard deltas stay in lockstep');
    });

    test('composing deltas track the composing region', () {
      final input = ComposingInput('');
      _client(input).updateEditingValueWithDeltas([
        _ins('', 'n', 0, composing: const TextRange(start: 0, end: 1)),
      ]);

      expect(input.isComposing, isTrue);
      expect(input.composing, const TextRange(start: 0, end: 1));
    });

    test('pushValue after a direct edit restores lockstep (edit preserved)',
        () {
      final input = ComposingInput('hello');
      final pushed = <TextEditingValue>[];
      final client = _client(input, pushed: pushed);

      input
        ..setSelection(const TextSelection(baseOffset: 0, extentOffset: 5))
        ..deleteSelection(); // buffer '', _needsImeSync set
      client.pushValue(); // the view pushed; lockstep restored

      expect(input.text, '');
      expect(pushed, hasLength(1));
      expect(pushed.single.text, '');

      // The next delta applies on the (pushed) buffer, not re-anchored.
      client.updateEditingValueWithDeltas([_ins('', 'x', 0)]);
      expect(input.text, 'x');
      expect(
        pushed,
        hasLength(1),
        reason: 'no extra push for a standard delta',
      );
    });

    test('without pushValue the next delta re-anchors (lost-edit protection)',
        () {
      final input = ComposingInput('hello');
      final client = _client(input);

      input
        ..setSelection(const TextSelection(baseOffset: 0, extentOffset: 5))
        ..deleteSelection(); // buffer '', but the IME still holds 'hello'
      // A delta relative to the IME's stale 'hello' arrives. apply re-anchors
      // the buffer to oldText (the platform copy), losing the delete but
      // applying the delta correctly — a lost edit, not a corrupt buffer.
      client.updateEditingValueWithDeltas([_ins('hello', '!', 5)]);
      expect(input.text, 'hello!');
    });

    test('updateEditingValue (legacy) resets the buffer and pushes', () {
      final input = ComposingInput('old');
      final pushed = <TextEditingValue>[];
      _client(input, pushed: pushed).updateEditingValue(
        const TextEditingValue(
          text: 'from ime',
          selection: TextSelection.collapsed(offset: 8),
        ),
      );

      expect(input.text, 'from ime');
      expect(input.caret, 8);
      expect(pushed, hasLength(1));
      expect(pushed.single.text, 'from ime');
    });

    test('performAction reports to onAction', () {
      final input = ComposingInput('a');
      final actions = <TextInputAction>[];
      _client(input, onAction: actions.add)
          .performAction(TextInputAction.done);

      expect(actions, [TextInputAction.done]);
      expect(input.text, 'a', reason: 'the client does not edit on action');
    });

    test('connectionClosed reports to onConnectionClosed', () {
      final input = ComposingInput('a');
      var closed = 0;
      _client(input, onConnectionClosed: () => closed++)
          .connectionClosed();

      expect(closed, 1);
    });

    test('currentTextEditingValue mirrors the input value', () {
      final input = ComposingInput('abc');
      final client = _client(input);

      expect(client.currentTextEditingValue, isNotNull);
      expect(client.currentTextEditingValue!.text, 'abc');
    });
  });
}
