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

  test('a lone deletion is a step, and redo puts the text back', () {
    // Pinned as "a deletion is its own step" before #1046: a deletion is
    // still one step when nothing contiguous follows it.
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

  group('deletions coalesce (#1046)', () {
    final text = List<String>.generate(50, (i) => 'abcdefghij'[i % 10]).join();

    /// Deletes the character before [caret] and records it, as Backspace.
    void backspace(EditHistory history, SourceBuffer buffer, int caret) {
      final removed = buffer.substring(caret - 1, caret);
      buffer.delete(caret - 1, caret);
      history.record(
        EditRecord(start: caret - 1, removed: removed, inserted: ''),
      );
    }

    /// Deletes the character at [caret] and records it, as Delete.
    void forwardDelete(EditHistory history, SourceBuffer buffer, int caret) {
      final removed = buffer.substring(caret, caret + 1);
      buffer.delete(caret, caret + 1);
      history.record(EditRecord(start: caret, removed: removed, inserted: ''));
    }

    test('50 backspaces are one step, undone and redone whole', () {
      final buffer = SourceBuffer.fromText(text);
      final history = EditHistory();
      for (var caret = 50; caret > 0; caret--) {
        backspace(history, buffer, caret);
      }
      expect(buffer.text, '');
      expect(history.length, 1);
      history.undo(buffer);
      expect(buffer.text, text, reason: 'the removed text, in order');
      history.redo(buffer);
      expect(buffer.text, '');
    });

    test('50 forward deletes are one step too', () {
      final buffer = SourceBuffer.fromText(text);
      final history = EditHistory();
      for (var i = 0; i < 50; i++) {
        forwardDelete(history, buffer, 0);
      }
      expect(history.length, 1);
      history.undo(buffer);
      expect(buffer.text, text);
      history.redo(buffer);
      expect(buffer.text, '');
    });

    test('a seal splits the run', () {
      final buffer = SourceBuffer.fromText(text);
      final history = EditHistory();
      backspace(history, buffer, 50);
      backspace(history, buffer, 49);
      history.seal();
      backspace(history, buffer, 48);
      expect(history.length, 2);
    });

    test('a direction change splits the run', () {
      final buffer = SourceBuffer.fromText(text);
      final history = EditHistory();
      backspace(history, buffer, 20);
      backspace(history, buffer, 19);
      forwardDelete(history, buffer, 18);
      expect(history.length, 2);
      history.undo(buffer);
      expect(buffer.length, 48, reason: 'the backspaces stay done');
    });

    test('a deletion elsewhere is a step of its own', () {
      final buffer = SourceBuffer.fromText(text);
      final history = EditHistory();
      backspace(history, buffer, 20);
      backspace(history, buffer, 10);
      expect(history.length, 2);
    });

    test('a line break ends the run on both sides', () {
      final buffer = SourceBuffer.fromText('abc\ndef');
      final history = EditHistory();
      backspace(history, buffer, 7);
      backspace(history, buffer, 6);
      // Across the break: its own step, and nothing joins it.
      final removed = buffer.substring(3, 4);
      buffer.delete(3, 4);
      history.record(EditRecord(start: 3, removed: removed, inserted: ''));
      backspace(history, buffer, 3);
      expect(buffer.text, 'abd');
      expect(history.length, 3);
    });

    test('typing, deleting and typing again are three steps', () {
      final buffer = SourceBuffer.fromText('');
      final history = EditHistory();
      _typed(history, buffer, 0, 'hello');
      backspace(history, buffer, 5);
      backspace(history, buffer, 4);
      _typed(history, buffer, 3, 'p');
      expect(history.length, 3);
    });

    test('250 backspaces leave the earlier steps reachable', () {
      final buffer = SourceBuffer.fromText('');
      final history = EditHistory();
      for (var i = 0; i < 3; i++) {
        // Three steps of typing, told apart by their line break.
        _typed(history, buffer, buffer.length, 'step $i\n');
      }
      final typed = buffer.length;
      _typed(history, buffer, typed, 'x' * 250);
      history.seal();
      for (var caret = typed + 250; caret > typed; caret--) {
        backspace(history, buffer, caret);
      }
      expect(history.length, 5, reason: '3 steps + the typing + the deletion');
      for (var i = 0; i < 5; i++) {
        history.undo(buffer);
      }
      expect(buffer.text, '');
    });
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

  test('a sealed step is not continued by the typing after it', () {
    // The caret moved away and came back: what is typed there next is its own
    // undo step, even though it starts where the last one ended.
    final buffer = SourceBuffer.fromText('x');
    final history = EditHistory();
    _typed(history, buffer, 1, 'a');
    history.seal();
    _typed(history, buffer, 2, 'b');
    expect(history.length, 2);
  });

  test('undo puts back a mixed line ending exactly', () {
    // A CRLF note with one LF line: deleting across the LF and undoing it
    // must give the LF back, not the note's dominant CRLF.
    final buffer = SourceBuffer.fromText('a\r\nb\nc\r\n');
    final history = EditHistory();
    final removed = buffer.substring(3, 6);
    buffer.replaceRange(3, 6, '');
    history
      ..record(EditRecord(start: 3, removed: removed, inserted: ''))
      ..undo(buffer);
    expect(buffer.text, 'a\r\nb\nc\r\n');
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
