import 'dart:math';

import 'package:copist/src/editor/line_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('typing and deleting', () {
    test('type inserts at the caret and advances it', () {
      final editor = LineEditor('hello');
      expect(
        (editor
              ..moveRight()
              ..type('i'))
            .text,
        'hiello',
      );
      expect(editor.caret, 2);
    });

    test('backspace deletes before the caret', () {
      final editor = LineEditor('abc');
      expect(
        (editor
              ..moveRight()
              ..moveRight()
              ..backspace())
            .text,
        'ac',
      );
      expect(editor.caret, 1);
    });

    test('deleteForward removes after the caret', () {
      final editor = LineEditor('abc');
      expect((editor..deleteForward()).text, 'bc');
      expect(editor.caret, 0);
    });

    test('type a newline splits the line', () {
      final editor = LineEditor('ab');
      expect(
        (editor
              ..moveEnd()
              ..type('\ncd'))
            .text,
        'ab\ncd',
      );
      expect(editor.lineCount, 2);
    });

    test('backspace at the start of a line joins the lines', () {
      final editor = LineEditor('a\nb');
      expect(
        (editor
              ..placeCaretAtLine(1)
              ..backspace())
            .text,
        'ab',
      );
      expect(editor.lineCount, 1);
      expect(editor.caret, 1);
    });

    test('empty type is a no-op', () {
      final editor = LineEditor('x');
      expect((editor..type('')).text, 'x');
      expect(editor.caret, 0);
    });

    test('backspace at the start and deleteForward at the end are no-ops', () {
      final editor = LineEditor('x');
      expect(
        (editor
              ..backspace()
              ..moveRight()
              ..deleteForward())
            .text,
        'x',
      );
    });
  });

  group('caret movement', () {
    test('left and right clamp at the ends', () {
      final editor = LineEditor('ab');
      expect(
        (editor
              ..moveLeft()
              ..moveRight()
              ..moveRight()
              ..moveRight())
            .caret,
        2,
      );
    });

    test('up and down move by logical line, keeping the column', () {
      final editor = LineEditor('aaaa\nbb');
      expect(
        (editor
              ..placeCaretAtLine(1)
              ..moveRight()
              ..moveUp())
            .caretLine,
        0,
      );
      expect(editor.caret, 1); // col 1 on line 0
      expect((editor..moveDown()).caretLine, 1);
      expect(editor.caret, 6); // back to col 1 on line 1
    });

    test('down clamps the column to the shorter target line', () {
      final editor = LineEditor('abcd\ne');
      expect(
        (editor
              ..placeCaretAtLine(0)
              ..moveEnd()
              ..moveDown())
            .caretLine,
        1,
      );
      expect(editor.caret, 6); // col clamped to the end of line 1
    });

    test('up at the first line and down at the last line stop', () {
      final editor = LineEditor('a\nb');
      expect(
        (editor
              ..moveUp()
              ..moveDown()
              ..moveDown())
            .caretLine,
        1,
      );
      expect((editor..moveDown()).caretLine, 1); // stays on the last line
    });

    test('home and end jump within the line', () {
      final editor = LineEditor('abc\ndef');
      expect(
        (editor
              ..placeCaretAtLine(1)
              ..moveEnd())
            .caret,
        7,
      );
      expect((editor..moveHome()).caret, 4);
    });

    test('placeCaretAtLine lands at the line start', () {
      final editor = LineEditor('one\ntwo\nthree');
      expect((editor..placeCaretAtLine(2)).caretLine, 2);
      final (line, col) = editor.buffer.locationOf(editor.caret);
      expect(line, 2);
      expect(col, 0);
    });
  });

  group('change stream', () {
    test('fires on text and caret changes, not on no-ops', () {
      final editor = LineEditor('ab');
      var changes = 0;
      editor.addListener(() => changes++);
      expect((editor..type('c')).text, 'cab');
      expect(changes, 1);
      expect((editor..moveLeft()).caret, 0);
      expect(changes, 2);
      expect((editor..moveLeft()).caret, 0); // no-op at the start
      expect(changes, 2);
      expect((editor..moveRight()).caret, 1);
      expect(changes, 3);
    });

    test('removeListener stops notifications', () {
      final editor = LineEditor('a');
      var changes = 0;
      void listener() => changes++;
      editor
        ..addListener(listener)
        ..removeListener(listener);
      expect(
        (editor
              ..moveEnd()
              ..type('b'))
            .text,
        'ab',
      );
      expect(changes, 0);
    });
  });

  group('property: buffer == composed text', () {
    test('random keystroke sequences match a reference string', () {
      final rand = Random(0xE3);
      final editor = LineEditor('start\nline');
      var reference = 'start\nline';

      for (var i = 0; i < 400; i++) {
        final caret = editor.caret;
        final length = reference.length;
        final op = rand.nextInt(6);
        switch (op) {
          case 0:
            editor.type('x');
            reference = _splice(reference, caret, 'x');
          case 1:
            editor.type('y\n');
            reference = _splice(reference, caret, 'y\n');
          case 2:
            editor.backspace();
            if (caret > 0) {
              reference =
                  reference.substring(0, caret - 1) +
                  reference.substring(caret);
            }
          case 3:
            editor.deleteForward();
            if (caret < length) {
              reference =
                  reference.substring(0, caret) +
                  reference.substring(caret + 1);
            }
          case 4:
            editor.moveLeft();
          default:
            editor.moveRight();
        }
        expect(editor.text, reference);
      }
    });
  });
}

/// Inserts [ins] at position [at] of [s].
String _splice(String s, int at, String ins) =>
    '${s.substring(0, at)}$ins${s.substring(at)}';
