import 'dart:math';

import 'package:copist/src/editor/composing_input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applying deltas', () {
    test('insertion inserts at the offset', () {
      final input = ComposingInput('say ');
      const delta = TextEditingDeltaInsertion(
        oldText: 'say ',
        textInserted: 'hi',
        insertionOffset: 4,
        selection: TextSelection.collapsed(offset: 6),
        composing: TextRange(start: 4, end: 6),
      );
      expect((input..apply(delta)).text, 'say hi');
      expect(input.caret, 6);
    });

    test('deletion removes a range', () {
      final input = ComposingInput('say hi');
      const delta = TextEditingDeltaDeletion(
        oldText: 'say hi',
        deletedRange: TextRange(start: 4, end: 6),
        selection: TextSelection.collapsed(offset: 4),
        composing: TextRange.empty,
      );
      expect((input..apply(delta)).text, 'say ');
      expect(input.caret, 4);
    });

    test('replacement swaps a range (autocorrect)', () {
      final input = ComposingInput('say hi');
      const delta = TextEditingDeltaReplacement(
        oldText: 'say hi',
        replacementText: 'yo',
        replacedRange: TextRange(start: 4, end: 6),
        selection: TextSelection.collapsed(offset: 6),
        composing: TextRange(start: 4, end: 6),
      );
      expect((input..apply(delta)).text, 'say yo');
    });

    test('non-text update changes selection/composing but not the text', () {
      final input = ComposingInput('say hi');
      final revision = input.revision;
      const delta = TextEditingDeltaNonTextUpdate(
        oldText: 'say hi',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 4, end: 6),
      );
      expect((input..apply(delta)).text, 'say hi');
      expect(input.revision, revision); // no text change
      expect(input.caret, 2);
      expect(input.isComposing, isTrue);
    });
  });

  group('composition', () {
    test('composing a word tracks the composing region each step', () {
      final input = ComposingInput('say ');
      expect(input.isComposing, isFalse);

      // Type 'h' — the IME starts a composing region.
      const h = TextEditingDeltaInsertion(
        oldText: 'say ',
        textInserted: 'h',
        insertionOffset: 4,
        selection: TextSelection.collapsed(offset: 5),
        composing: TextRange(start: 4, end: 5),
      );
      expect((input..apply(h)).text, 'say h');
      expect(input.isComposing, isTrue);
      expect(input.composing, const TextRange(start: 4, end: 5));

      // Android replaces the whole composing region as it grows: 'h' -> 'he'.
      const he = TextEditingDeltaReplacement(
        oldText: 'say h',
        replacementText: 'he',
        replacedRange: TextRange(start: 4, end: 5),
        selection: TextSelection.collapsed(offset: 6),
        composing: TextRange(start: 4, end: 6),
      );
      expect((input..apply(he)).text, 'say he');
      expect(input.composing, const TextRange(start: 4, end: 6));
    });

    test('committing a composition edits the buffer and clears composing', () {
      final input = ComposingInput('say ');

      const he = TextEditingDeltaReplacement(
        oldText: 'say ',
        replacementText: 'he',
        replacedRange: TextRange(start: 4, end: 4),
        selection: TextSelection.collapsed(offset: 6),
        composing: TextRange(start: 4, end: 6),
      );
      expect((input..apply(he)).isComposing, isTrue);
      expect(input.text, 'say he');

      // The user commits: the IME finalizes the word and clears the region.
      const commit = TextEditingDeltaNonTextUpdate(
        oldText: 'say he',
        selection: TextSelection.collapsed(offset: 6),
        composing: TextRange.empty,
      );
      expect((input..apply(commit)).text, 'say he');
      expect(input.isComposing, isFalse);
      expect(input.composing, TextRange.empty);
    });
  });

  group('caret and selection', () {
    test('caret is the collapsed selection offset', () {
      final input = ComposingInput('hello');
      expect(
        (input..setSelection(const TextSelection.collapsed(offset: 3))).caret,
        3,
      );
      expect(input.caretLine, 0);
    });

    test('caret is null when a range is selected', () {
      final input = ComposingInput('hello');
      expect(
        (input..setSelection(
              const TextSelection(baseOffset: 1, extentOffset: 4),
            ))
            .caret,
        isNull,
      );
    });

    test('setCaretAtLine lands the caret at the line start', () {
      final input = ComposingInput('one\ntwo\nthree');
      expect((input..setCaretAtLine(2)).caretLine, 2);
      expect(input.caret, 8);
    });
  });

  group('reset and value', () {
    test('reset re-anchors the buffer, caret and composing', () {
      final input = ComposingInput('old text');
      const delta = TextEditingDeltaNonTextUpdate(
        oldText: 'old text',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: 3),
      );
      expect(
        (input
              ..apply(delta)
              ..reset('brand new'))
            .text,
        'brand new',
      );
      expect(input.caret, 0);
      expect(input.isComposing, isFalse);
    });

    test('value materializes the current editing state', () {
      final input = ComposingInput('hi');
      final value =
          (input..setSelection(const TextSelection.collapsed(offset: 2))).value;
      expect(value.text, 'hi');
      expect(
        value.selection,
        const TextSelection.collapsed(offset: 2),
      );
      expect(value.composing, TextRange.empty);
    });
  });

  group('direct edits and IME lockstep', () {
    test(
      'a direct edit followed by commitDirectEdit applies deltas normally',
      () {
        final input = ComposingInput('old');
        const delta = TextEditingDeltaInsertion(
          oldText: 'new',
          textInserted: '!',
          insertionOffset: 3,
          selection: TextSelection.collapsed(offset: 4),
          composing: TextRange.empty,
        );
        input
          ..reset('new') // buffer = 'new', pending IME resync
          ..commitDirectEdit() // the view pushed `value` to the IME
          ..apply(delta);
        expect(input.text, 'new!'); // delta applied, no re-anchor
      },
    );

    test(
      'a direct edit without commitDirectEdit re-anchors (no corruption)',
      () {
        final input = ComposingInput('old');
        const delta = TextEditingDeltaInsertion(
          oldText: 'old',
          textInserted: '?',
          insertionOffset: 3,
          selection: TextSelection.collapsed(offset: 4),
          composing: TextRange.empty,
        );
        // The IME was never re-synced, so the delta is relative to its stale
        // copy ('old'): apply re-anchors to it (the 'new' edit is lost, but the
        // text is not corrupted).
        input
          ..reset('new')
          ..apply(delta);
        expect(input.text, 'old?');
      },
    );

    test('paste (replaceSelection) is a direct edit too', () {
      final input = ComposingInput('say hi');
      const delta = TextEditingDeltaInsertion(
        oldText: 'say yo',
        textInserted: '!',
        insertionOffset: 6,
        selection: TextSelection.collapsed(offset: 7),
        composing: TextRange.empty,
      );
      input
        ..setSelection(const TextSelection(baseOffset: 4, extentOffset: 6))
        ..replaceSelection('yo') // buffer = 'say yo', pending resync
        ..commitDirectEdit()
        ..apply(delta);
      expect(input.text, 'say yo!');
    });
  });

  group('revision', () {
    test('advances only on text changes', () {
      final input = ComposingInput('a');
      final start = input.revision;
      const insertion = TextEditingDeltaInsertion(
        oldText: 'a',
        textInserted: 'b',
        insertionOffset: 1,
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange.empty,
      );
      expect((input..apply(insertion)).revision, start + 1);
      const nonText = TextEditingDeltaNonTextUpdate(
        oldText: 'ab',
        selection: TextSelection.collapsed(offset: 0),
        composing: TextRange.empty,
      );
      expect((input..apply(nonText)).revision, start + 1); // no advance
    });
  });

  group('property: no lost or duplicated input', () {
    test('many edits on a long note keep the buffer exactly correct', () {
      final rand = Random(0xE4);
      final lines = List.generate(2000, (i) => 'line $i ${'w' * (i % 30)}');
      final initial = lines.join('\n');
      final input = ComposingInput(initial);
      var reference = initial;

      for (var i = 0; i < 300; i++) {
        final oldText = reference;
        final length = reference.length;
        final op = rand.nextInt(5);
        switch (op) {
          case 0: // typed character inside a composing region
            final off = rand.nextInt(length + 1);
            final ins = 'abcd'[rand.nextInt(4)];
            final delta = TextEditingDeltaInsertion(
              oldText: oldText,
              textInserted: ins,
              insertionOffset: off,
              selection: TextSelection.collapsed(offset: off + 1),
              composing: TextRange(start: off, end: off + 1),
            );
            input.apply(delta);
            reference = _splice(reference, off, ins);
          case 1: // backspace
            final off = rand.nextInt(length + 1);
            if (off < length) {
              final delta = TextEditingDeltaDeletion(
                oldText: oldText,
                deletedRange: TextRange(start: off, end: off + 1),
                selection: TextSelection.collapsed(offset: off),
                composing: TextRange.empty,
              );
              input.apply(delta);
              reference = _replaceIn(reference, off, off + 1, '');
            }
          case 2: // autocorrect replaces the composing region
            final start = rand.nextInt(length + 1);
            final end = start + rand.nextInt(5);
            if (end <= length) {
              final repl = 'zZ'[rand.nextInt(2)];
              final delta = TextEditingDeltaReplacement(
                oldText: oldText,
                replacementText: repl,
                replacedRange: TextRange(start: start, end: end),
                selection: TextSelection.collapsed(offset: start + repl.length),
                composing: TextRange(start: start, end: start + repl.length),
              );
              input.apply(delta);
              reference = _replaceIn(reference, start, end, repl);
            }
          default: // caret move / commit
            final off = rand.nextInt(length + 1);
            final delta = TextEditingDeltaNonTextUpdate(
              oldText: oldText,
              selection: TextSelection.collapsed(offset: off),
              composing: TextRange.empty,
            );
            input.apply(delta);
        }
        expect(input.text, reference);
      }
    });
  });

  group('undo/redo (E-U)', () {
    test('undo a typed insertion restores text + caret', () {
      final input = ComposingInput('say ');
      expect(
        (input
              ..setSelection(const TextSelection.collapsed(offset: 4))
              ..apply(_insertDelta('say ', 'hi', 4)))
            .text,
        'say hi',
      );
      input.undo();
      expect(input.text, 'say ');
      expect(input.caret, 4);
      expect(input.canUndo, isFalse);
    });

    test('redo re-applies an undone edit (text + caret)', () {
      final input = ComposingInput('say ');
      expect(
        (input
              ..setSelection(const TextSelection.collapsed(offset: 4))
              ..apply(_insertDelta('say ', 'hi', 4)))
            .text,
        'say hi',
      );
      input.undo();
      expect(input.text, 'say ');
      input.redo();
      expect(input.text, 'say hi');
      expect(input.caret, 6);
      expect(input.canRedo, isFalse);
    });

    test('undo a deletion restores the deleted text + selection', () {
      final input = ComposingInput('say hi');
      expect(
        (input
              ..setSelection(
                const TextSelection(baseOffset: 4, extentOffset: 6),
              )
              ..apply(
                const TextEditingDeltaDeletion(
                  oldText: 'say hi',
                  deletedRange: TextRange(start: 4, end: 6),
                  selection: TextSelection.collapsed(offset: 4),
                  composing: TextRange.empty,
                ),
              ))
            .text,
        'say ',
      );
      input.undo();
      expect(input.text, 'say hi');
      expect(input.selectionText, 'hi');
    });

    test('undo a cut (deleteSelection) restores text + selection', () {
      final input = ComposingInput('hello world');
      expect(
        (input
              ..setSelection(
                const TextSelection(baseOffset: 6, extentOffset: 11),
              )
              ..deleteSelection())
            .text,
        'hello ',
      );
      input.undo();
      expect(input.text, 'hello world');
      expect(input.hasSelection, isTrue);
      expect(input.selectionText, 'world');
    });

    test('undo a paste (replaceSelection) restores the original', () {
      final input = ComposingInput('a   c');
      expect(
        (input
              ..setSelection(
                const TextSelection(baseOffset: 1, extentOffset: 4),
              )
              ..replaceSelection('b'))
            .text,
        'abc',
      );
      input.undo();
      expect(input.text, 'a   c');
    });

    test('the stack is bounded (oldest edits dropped first)', () {
      final input = ComposingInput('', maxHistory: 3);
      for (final ch in const ['a', 'b', 'c', 'd', 'e']) {
        input.apply(_insertDelta(input.text, ch, input.textLength));
      }
      expect(input.text, 'abcde');
      input
        ..undo()
        ..undo()
        ..undo();
      expect(input.text, 'ab'); // 'a', 'b' were dropped from history
      expect(input.canUndo, isFalse);
    });

    test('reset (a new load) clears the history', () {
      final input = ComposingInput('ab');
      expect((input..apply(_insertDelta('ab', 'c', 2))).text, 'abc');
      input.reset('');
      expect(input.canUndo, isFalse);
      expect(input.canRedo, isFalse);
    });

    test('a new edit clears the redo branch', () {
      final input = ComposingInput('ab');
      expect(
        (input
              ..apply(_insertDelta('ab', 'c', 2))
              ..apply(_insertDelta('abc', 'd', 3)))
            .text,
        'abcd',
      );
      input.undo();
      expect(input.canRedo, isTrue);
      expect((input..apply(_insertDelta('abc', '!', 3))).text, 'abc!');
      expect(input.canRedo, isFalse);
      expect(input.canUndo, isTrue);
    });

    test(
      'undo re-syncs the IME (a following delta re-anchors, no lost input)',
      () {
        final input = ComposingInput('hello');
        expect((input..apply(_insertDelta('hello', '!', 5))).text, 'hello!');
        input.undo(); // direct edit → the resync flag is set
        expect(input.text, 'hello');
        // The IME still holds the pre-undo text ('hello!'); its next delta
        // carries that as oldText. apply must re-anchor to it and apply the
        // delta on it — the pending undo is lost, but the new input is kept
        // (and no assertion fires, because undo set the resync flag).
        expect((input..apply(_insertDelta('hello!', '?', 6))).text, 'hello!?');
      },
    );
  });
}

String _splice(String s, int at, String ins) =>
    '${s.substring(0, at)}$ins${s.substring(at)}';

String _replaceIn(String s, int start, int end, String repl) =>
    '${s.substring(0, start)}$repl${s.substring(end)}';

TextEditingDeltaInsertion _insertDelta(
  String oldText,
  String text,
  int offset,
) => TextEditingDeltaInsertion(
  oldText: oldText,
  textInserted: text,
  insertionOffset: offset,
  selection: TextSelection.collapsed(offset: offset + text.length),
  composing: TextRange.empty,
);
