import 'package:copist/src/editor/composing_input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('selectionText', () {
    test('returns the selected range', () {
      final input = ComposingInput('hello world');
      expect(
        (input..setSelection(
              const TextSelection(baseOffset: 0, extentOffset: 5),
            ))
            .selectionText,
        'hello',
      );
    });

    test('spans multiple lines', () {
      final input = ComposingInput('one\ntwo\nthree');
      // Offsets: o0 n1 e2 \n3 t4 w5 o6 \n7 t8 h9 r10 e11 e12
      expect(
        (input..setSelection(
              const TextSelection(baseOffset: 2, extentOffset: 10),
            ))
            .selectionText,
        'e\ntwo\nth',
      );
    });

    test('is empty when collapsed', () {
      final input = ComposingInput('hello');
      expect(input.selectionText, '');
    });
  });

  group('hasSelection', () {
    test('true for a range, false for a caret', () {
      final input = ComposingInput('hello');
      expect(input.hasSelection, isFalse);
      expect(
        (input..setSelection(
              const TextSelection(baseOffset: 1, extentOffset: 4),
            ))
            .hasSelection,
        isTrue,
      );
    });
  });

  group('extendSelectionTo', () {
    test('keeps the anchor and moves the focus', () {
      final input = ComposingInput('hello world');
      expect(
        (input
              ..setSelection(const TextSelection.collapsed(offset: 6))
              ..extendSelectionTo(11))
            .selectionText,
        'world',
      );
    });

    test('extends across lines', () {
      final input = ComposingInput('ab\ncd');
      // Offsets: a0 b1 \n2 c3 d4; focus 5 = end of text
      expect(
        (input
              ..setSelection(const TextSelection.collapsed(offset: 1))
              ..extendSelectionTo(5))
            .selectionText,
        'b\ncd',
      );
    });
  });

  group('collapseSelection', () {
    test('collapses to the focus', () {
      final input = ComposingInput('hello world');
      expect(
        (input
              ..setSelection(
                const TextSelection(baseOffset: 0, extentOffset: 5),
              )
              ..collapseSelection())
            .selection,
        const TextSelection.collapsed(offset: 5),
      );
      expect(input.hasSelection, isFalse);
    });
  });

  group('deleteSelection (cut)', () {
    test('updates the buffer and caret, returns the text', () {
      final input = ComposingInput('say hello there');
      final removed =
          (input..setSelection(
                const TextSelection(baseOffset: 4, extentOffset: 9),
              ))
              .deleteSelection();
      expect(removed, 'hello');
      expect(input.text, 'say  there');
      expect(input.caret, 4);
      expect(input.hasSelection, isFalse);
    });

    test('spans multiple lines', () {
      final input = ComposingInput('one\ntwo\nthree');
      // Offsets: o0 n1 e2 \n3 t4 w5 o6 \n7 t8 ...; [4,8) = 'two\n'
      final removed =
          (input..setSelection(
                const TextSelection(baseOffset: 4, extentOffset: 8),
              ))
              .deleteSelection();
      expect(removed, 'two\n');
      expect(input.text, 'one\nthree');
      expect(input.caret, 4);
    });

    test('is a no-op when collapsed', () {
      final input = ComposingInput('hello');
      final revision = input.revision;
      expect(input.deleteSelection(), '');
      expect(input.text, 'hello');
      expect(input.revision, revision);
    });
  });

  group('replaceSelection (paste / replace)', () {
    test('inserts at the caret when collapsed', () {
      final input = ComposingInput('helo');
      expect(
        (input
              ..setSelection(const TextSelection.collapsed(offset: 2))
              ..replaceSelection('l'))
            .text,
        'hello',
      );
      expect(input.caret, 3);
    });

    test('replaces the selection when one exists', () {
      final input = ComposingInput('say hi there');
      expect(
        (input
              ..setSelection(
                const TextSelection(baseOffset: 4, extentOffset: 6),
              )
              ..replaceSelection('yo'))
            .text,
        'say yo there',
      );
      expect(input.caret, 6);
    });

    test('replaces a multi-line selection', () {
      final input = ComposingInput('ab\ncd\nef');
      expect(
        (input
              ..setSelection(
                const TextSelection(baseOffset: 3, extentOffset: 7),
              )
              ..replaceSelection('X'))
            .text,
        'ab\nXf',
      );
      expect(input.caret, 4);
    });
  });

  group('copy/paste round-trip', () {
    test('select, copy, paste preserves the text', () {
      final input = ComposingInput('one two three');
      final copied =
          (input..setSelection(
                const TextSelection(baseOffset: 4, extentOffset: 7),
              ))
              .selectionText;
      expect(copied, 'two');
      expect(
        (input
              ..setSelection(const TextSelection.collapsed(offset: 0))
              ..replaceSelection(copied))
            .text,
        'twoone two three',
      );
    });
  });
}
