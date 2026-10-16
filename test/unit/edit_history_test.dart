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

  group('the history is bounded by text as well as steps (#1050)', () {
    /// Replaces the whole [buffer] with [text] and records it.
    void replaceAll(EditHistory history, SourceBuffer buffer, String text) {
      final before = buffer.text;
      buffer.replaceRange(0, buffer.length, text);
      history.record(EditRecord(start: 0, removed: before, inserted: text));
    }

    test('the default budget is 16 M code units, 32 MB of UTF-16', () {
      expect(EditHistory().budget, 16 * 1024 * 1024);
    });

    test('the oldest steps go first when the text outgrows the budget', () {
      // Ten replacements of 5 000 characters by 5 000 others against a budget
      // of 16 000: the scale of "ten 5 MB pastes against 16 MB", small enough
      // to run anywhere. A step holds 10 000, so one fits and two do not.
      final buffer = SourceBuffer.fromText('s' * 5000);
      final history = EditHistory(budget: 16000);
      for (var i = 0; i < 10; i++) {
        replaceAll(history, buffer, '${i}x' * 2500);
      }
      expect(history.length, 1, reason: 'the others were evicted');
      expect(history.units, lessThanOrEqualTo(16000));
      history.undo(buffer);
      expect(buffer.text, '8x' * 2500, reason: 'the newest is undoable');
    });

    test('several small steps fit and the count cap still applies', () {
      final buffer = SourceBuffer.fromText('');
      final history = EditHistory(limit: 4, budget: 1000);
      for (var i = 0; i < 10; i++) {
        _typed(history, buffer, buffer.length, 'line $i\n');
      }
      expect(history.length, 4);
      expect(history.units, lessThan(1000));
    });

    test('a step bigger than the budget is kept: it is the newest', () {
      final buffer = SourceBuffer.fromText('a' * 100);
      final history = EditHistory(budget: 10);
      replaceAll(history, buffer, 'b' * 100);
      expect(history.length, 1);
      history.undo(buffer);
      expect(buffer.text, 'a' * 100);
    });

    test('what a step holds is given back when it is undone', () {
      final buffer = SourceBuffer.fromText('a' * 100);
      final history = EditHistory();
      replaceAll(history, buffer, 'b' * 100);
      expect(history.units, 200);
      history.undo(buffer);
      expect(history.units, 0);
      history.redo(buffer);
      expect(history.units, 200);
    });

    test('an edit over a long span keeps only the lines that changed', () {
      final lines = List<String>.generate(20000, (i) => 'line number $i');
      final before = '${lines.join('\n')}\n';
      final changed = List<String>.of(lines)
        ..[10] = 'ten'
        ..[10000] = 'ten thousand'
        ..[19990] = 'nineteen nine ninety';
      final after = '${changed.join('\n')}\n';
      // A Replace All from the first match to the last: it spans the note.
      final buffer = SourceBuffer.fromText('head\n$before');
      final history = EditHistory();
      buffer.replaceRange(5, buffer.length, after);
      history.record(EditRecord(start: 5, removed: before, inserted: after));
      expect(history.units, lessThan(200), reason: 'three lines, both sides');
      history.undo(buffer);
      expect(buffer.text, 'head\n$before');
      history.redo(buffer);
      expect(buffer.text, 'head\n$after');
      expect(buffer.lineCount, 20002);
    });

    test('a CRLF note is put back exactly through its hunks', () {
      final lines = List<String>.generate(2000, (i) => 'line number $i');
      final before = '${lines.join('\r\n')}\r\n';
      final changed = List<String>.of(lines)
        ..[3] = 'three'
        ..[1500] = 'fifteen hundred';
      final after = '${changed.join('\r\n')}\r\n';
      final buffer = SourceBuffer.fromText(before);
      final history = EditHistory();
      buffer.replaceRange(0, buffer.length, after);
      history
        ..record(EditRecord(start: 0, removed: before, inserted: buffer.text))
        ..undo(buffer);
      expect(buffer.text, before);
      history.redo(buffer);
      expect(buffer.text, after);
    });

    test('undo and redo say where the caret goes', () {
      final buffer = SourceBuffer.fromText('ciao mondo\n');
      final history = EditHistory();
      buffer.replaceRange(4, 10, '');
      history.record(
        const EditRecord(start: 4, removed: ' mondo', inserted: ''),
      );
      expect(history.undo(buffer), 10, reason: 'after what came back');
      expect(history.redo(buffer), 4, reason: 'after what redo did');
      expect(history.redo(buffer), isNull);
    });
  });

  group('where a typing step ends (#1053)', () {
    var now = Duration.zero;
    EditHistory make() {
      now = Duration.zero;
      return EditHistory(clock: () => now);
    }

    /// Types [text] one character at a time at the end of [buffer].
    void type(EditHistory history, SourceBuffer buffer, String text) {
      for (final char in text.split('')) {
        _typed(history, buffer, buffer.length, char);
      }
    }

    /// Types [text] one character at a time from [at], inside the text.
    void typeInside(
      EditHistory history,
      SourceBuffer buffer,
      int at,
      String text,
    ) {
      for (var i = 0; i < text.length; i++) {
        _typed(history, buffer, at + i, text[i]);
      }
    }

    /// Types a bracket that wrote its pair, the caret between: what the
    /// surface records as `()` with one closer.
    void pair(EditHistory history, SourceBuffer buffer, int at) {
      buffer.replaceRange(at, at, '()');
      history.record(
        EditRecord(start: at, removed: '', inserted: '()'),
        closing: 1,
      );
    }

    test('a pause of more than a second ends the step', () {
      final buffer = SourceBuffer.fromText('');
      final history = make();
      type(history, buffer, 'a' * 15);
      now += const Duration(seconds: 2);
      type(history, buffer, 'b' * 15);
      expect(history.length, 2);
      history.undo(buffer);
      expect(buffer.text, 'a' * 15);
    });

    test('a pause of exactly the limit does not', () {
      final buffer = SourceBuffer.fromText('');
      final history = make();
      type(history, buffer, 'ab');
      now += const Duration(seconds: 1);
      type(history, buffer, 'cd');
      expect(history.length, 1);
    });

    test('keys pressed inside the second keep the step alive', () {
      final buffer = SourceBuffer.fromText('');
      final history = make();
      for (var i = 0; i < 10; i++) {
        type(history, buffer, 'a');
        now += const Duration(milliseconds: 600);
      }
      expect(history.length, 1, reason: '6 s of typing, no 1 s gap');
    });

    test('a pause ends a run of deletions too', () {
      final buffer = SourceBuffer.fromText('abcdef');
      final history = make();
      for (var caret = 6; caret > 4; caret--) {
        final removed = buffer.substring(caret - 1, caret);
        buffer.delete(caret - 1, caret);
        history.record(
          EditRecord(start: caret - 1, removed: removed, inserted: ''),
        );
      }
      now += const Duration(seconds: 2);
      buffer.delete(3, 4);
      history.record(const EditRecord(start: 3, removed: 'd', inserted: ''));
      expect(history.length, 2);
    });

    test('a word after a space is a step of its own', () {
      final buffer = SourceBuffer.fromText('');
      final history = make();
      type(history, buffer, 'one two');
      expect(history.length, 2);
      history.undo(buffer);
      expect(buffer.text, 'one ', reason: 'the last word goes first');
      history.undo(buffer);
      expect(buffer.text, '');
    });

    test('spaces before the first word do not end the step', () {
      final buffer = SourceBuffer.fromText('');
      final history = make();
      type(history, buffer, '   one');
      expect(history.length, 1);
    });

    test('a run of spaces between words is part of the first word', () {
      final buffer = SourceBuffer.fromText('');
      final history = make();
      type(history, buffer, 'one   two');
      expect(history.length, 2);
      history.undo(buffer);
      expect(buffer.text, 'one   ');
    });

    test('typing inside a bracket pair is the step that wrote the pair', () {
      final buffer = SourceBuffer.fromText('');
      final history = make();
      pair(history, buffer, 0);
      _typed(history, buffer, 1, 'a');
      _typed(history, buffer, 2, 'b');
      _typed(history, buffer, 3, 'c');
      expect(buffer.text, '(abc)');
      expect(history.length, 1);
      history.undo(buffer);
      expect(buffer.text, '', reason: 'the closer goes with the step');
      history.redo(buffer);
      expect(buffer.text, '(abc)');
    });

    test('stepping over the closer goes on in the same step', () {
      final buffer = SourceBuffer.fromText('');
      final history = make();
      pair(history, buffer, 0);
      typeInside(history, buffer, 1, 'abc');
      // `)` typed over the closer: the caret moves, nothing is inserted.
      history.stepOver(5);
      _typed(history, buffer, 5, ' ');
      _typed(history, buffer, 6, 'd');
      expect(buffer.text, '(abc) d');
      // `(abc) ` then the word after the space: two steps, not four.
      expect(history.length, 2);
    });

    test('a pair inside a pair keeps both closers in the step', () {
      final buffer = SourceBuffer.fromText('');
      final history = make();
      pair(history, buffer, 0);
      buffer.replaceRange(1, 1, '[]');
      history.record(
        const EditRecord(start: 1, removed: '', inserted: '[]'),
        closing: 1,
      );
      _typed(history, buffer, 2, 'x');
      expect(buffer.text, '([x])');
      expect(history.length, 1);
      history
        ..stepOver(4)
        ..stepOver(5);
      _typed(history, buffer, 5, '.');
      expect(history.length, 1);
      history.undo(buffer);
      expect(buffer.text, '');
    });

    test('a caret move inside the pair ends the step', () {
      final buffer = SourceBuffer.fromText('');
      final history = make();
      pair(history, buffer, 0);
      history.seal();
      _typed(history, buffer, 1, 'a');
      expect(history.length, 2);
    });

    test('a step over something the step did not write ends it', () {
      final buffer = SourceBuffer.fromText('');
      final history = make();
      type(history, buffer, 'ab');
      history.stepOver(3);
      _typed(history, buffer, 2, 'c');
      expect(history.length, 2);
    });

    test('typing past the closers joins the step too', () {
      final buffer = SourceBuffer.fromText('');
      final history = make();
      pair(history, buffer, 0);
      typeInside(history, buffer, 1, 'a');
      // The caret went to the end of the line without a key of the pair's:
      // what is typed there still continues what stands before it.
      _typed(history, buffer, 3, 'b');
      expect(buffer.text, '(a)b');
      expect(history.length, 1);
      history.undo(buffer);
      expect(buffer.text, '');
    });
  });
}
