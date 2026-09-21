// Undo and redo for the note the surface edits (#245, phase 3): a history of
// edits, coalesced where a writer expects it and bounded where a session needs
// it.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/edit_history.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Records an insertion of [text] at [at] over [buffer], as the surface does.
void _typed(EditHistory history, SourceBuffer buffer, int at, String text) {
  buffer.replaceRange(at, at, text);
  history.record(EditRecord(start: at, removed: '', inserted: text));
}

void main() {
  test('an edit is undone to the text it replaced', () {
    final buffer = SourceBuffer.fromText('ciao mondo\n');
    final history = EditHistory();
    buffer.replaceRange(4, 10, '');
    history.record(const EditRecord(start: 4, removed: ' mondo', inserted: ''));
    expect(buffer.text, 'ciao\n');
    expect(history.canUndo, isTrue);
    history.undo(buffer);
    expect(buffer.text, 'ciao mondo\n');
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isTrue);
    history.redo(buffer);
    expect(buffer.text, 'ciao\n');
  });

  test('typing coalesces into one undo step', () {
    final buffer = SourceBuffer.fromText('');
    final history = EditHistory();
    for (var at = 0; at < 5; at++) {
      _typed(history, buffer, at, 'c');
    }
    expect(buffer.text, 'ccccc');
    expect(history.length, 1, reason: 'five keystrokes, one decision');
    history.undo(buffer);
    expect(buffer.text, '', reason: 'one undo takes the word back');
  });

  test('a caret move ends the coalescing', () {
    final buffer = SourceBuffer.fromText('');
    final history = EditHistory();
    _typed(history, buffer, 0, 'ab');
    // The writer moved the caret and typed again: that is a second thought.
    buffer.insert(0, 'X');
    history.record(const EditRecord(start: 0, removed: '', inserted: 'X'));
    expect(history.length, 2, reason: 'not contiguous, so not one step');
    history.undo(buffer);
    expect(buffer.text, 'ab');
  });

  test('a newline is its own step', () {
    final buffer = SourceBuffer.fromText('uno');
    final history = EditHistory();
    _typed(history, buffer, 3, '\n');
    _typed(history, buffer, 4, 'd');
    expect(
      history.length,
      2,
      reason:
          'a line break is a decision, and undoing it separately is expected',
    );
  });

  test('a deletion is its own step, and redo puts the text back', () {
    final buffer = SourceBuffer.fromText('una riga\n');
    final history = EditHistory();
    buffer.delete(3, 8);
    history.record(const EditRecord(start: 3, removed: ' riga', inserted: ''));
    expect(buffer.text, 'una\n');
    history.undo(buffer);
    expect(buffer.text, 'una riga\n');
    history.redo(buffer);
    expect(buffer.text, 'una\n');
  });

  test('a new edit drops what was undone', () {
    final buffer = SourceBuffer.fromText('');
    final history = EditHistory();
    _typed(history, buffer, 0, 'prima');
    history.undo(buffer);
    expect(history.canRedo, isTrue);
    _typed(history, buffer, 0, 'dopo');
    expect(
      history.canRedo,
      isFalse,
      reason: 'the branch that was undone is no longer reachable',
    );
    expect(buffer.text, 'dopo');
  });

  test('the stack is bounded, and the oldest goes first', () {
    final buffer = SourceBuffer.fromText('');
    final history = EditHistory(limit: 3);
    for (var at = 0; at < 6; at++) {
      // One line per step: a newline ends the coalescing, so these are six
      // edits
      // rather than one run of typing.
      _typed(history, buffer, buffer.length, '$at\n');
    }
    expect(history.length, 3);
    while (history.canUndo) {
      history.undo(buffer);
    }
    expect(
      buffer.text,
      '0\n1\n2\n',
      reason: 'the first three edits were dropped, so undo stops there',
    );
  });

  test('an edit that changed nothing is not a step', () {
    final history = EditHistory()
      ..record(const EditRecord(start: 0, removed: '', inserted: ''));
    expect(history.canUndo, isFalse);
  });

  test('clear forgets both directions', () {
    final buffer = SourceBuffer.fromText('x');
    final history = EditHistory();
    _typed(history, buffer, 1, 'y');
    history
      ..undo(buffer)
      ..clear();
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isFalse);
  });
}
