// The list, numbered list and quote commands toggle: the second press takes
// the mark off again, and an item with another marker has it swapped (#1340).
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';

typedef _Command = MarkdownEdit Function(String text, TextSelection selection);

_Command _bullet = (text, selection) =>
    toggleBulletList(text: text, selection: selection);
_Command _ordered = (text, selection) =>
    orderedList(text: text, selection: selection);
_Command _quote = (text, selection) =>
    toggleQuote(text: text, selection: selection);
_Command _task = (text, selection) =>
    toggleTaskList(text: text, selection: selection);

/// The note after [command] over all of [text], and then over what it made.
(String, String) _twice(_Command command, String text) {
  final all = TextSelection(baseOffset: 0, extentOffset: text.length);
  final once = command(text, all);
  final again = command(
    once.text,
    TextSelection(baseOffset: 0, extentOffset: once.text.length),
  );
  return (once.text, again.text);
}

void main() {
  test('over plain lines each command is undone by its second press', () {
    final random = Random(20261127);
    for (var round = 0; round < 300; round++) {
      final eol = random.nextBool() ? '\n' : '\r\n';
      final text = [
        for (var at = 0; at < 1 + random.nextInt(6); at++)
          switch (random.nextInt(4)) {
            0 => '',
            1 => '  indented ${random.nextInt(9)}',
            _ => 'plain words ${random.nextInt(99)}',
          },
      ].join(eol);
      final from = random.nextInt(text.length + 1);
      final to = random.nextInt(text.length + 1);
      final selection = TextSelection(baseOffset: from, extentOffset: to);
      for (final MapEntry(key: name, value: command) in <String, _Command>{
        'bullet': _bullet,
        'numbers': _ordered,
        'quote': _quote,
        'checklist': _task,
      }.entries) {
        final once = command(text, selection);
        final again = command(once.text, once.selection);
        // Blank lines among several are left alone, and so is a line the
        // selection ends at the start of.
        expect(
          again.text,
          text,
          reason: '$name on ${text.replaceAll('\n', r'\n')} at $from..$to',
        );
      }
    }
  });

  group('the bullet list', () {
    test('a second press takes the bullets off', () {
      expect(_twice(_bullet, 'a\nb'), ('- a\n- b', 'a\nb'));
    });

    test('a bullet on an item that has one changes nothing', () {
      final edit = _bullet('- a', const TextSelection.collapsed(offset: 0));
      expect(edit.text, 'a');
      expect(edit.selection, const TextSelection.collapsed(offset: 0));
    });

    test('an indent and a marker as written are kept, or taken whole', () {
      expect(_twice(_bullet, '  a'), ('  - a', '  a'));
      // Bullets of any kind count: the first press takes them off.
      expect(_twice(_bullet, '* a\n+ b'), ('a\nb', '- a\n- b'));
    });

    test('some lines bulleted, some not: all become bulleted', () {
      expect(_twice(_bullet, '- a\nb\n- c'), ('- a\n- b\n- c', 'a\nb\nc'));
    });

    test('a numbered item swaps its number for a bullet', () {
      expect(_twice(_bullet, '1. a\n2. b'), ('- a\n- b', 'a\nb'));
      expect(
        _bullet('3. [ ] a', const TextSelection.collapsed(offset: 0)).text,
        '- a',
      );
    });

    test('a task swaps its box for nothing, keeping the bullet', () {
      expect(
        _bullet('- [ ] a', const TextSelection.collapsed(offset: 0)).text,
        '- a',
      );
      expect(_twice(_bullet, '* [x] a\n- [ ] b'), ('* a\n- b', 'a\nb'));
    });

    test('a blank line among several is left alone', () {
      expect(_twice(_bullet, 'a\n\nb'), ('- a\n\n- b', 'a\n\nb'));
    });

    test('behind quote marks', () {
      expect(_twice(_bullet, '> a\n> b'), ('> - a\n> - b', '> a\n> b'));
    });

    test('a CRLF note keeps its line endings', () {
      expect(_twice(_bullet, 'a\r\nb\r\n'), ('- a\r\n- b\r\n', 'a\r\nb\r\n'));
    });

    test('a caret stays on its text', () {
      final on = _bullet('abc', const TextSelection.collapsed(offset: 2));
      expect(on.selection, const TextSelection.collapsed(offset: 4));
      final off = _bullet(on.text, on.selection);
      expect(off.text, 'abc');
      expect(off.selection, const TextSelection.collapsed(offset: 2));
    });
  });

  group('the numbered list', () {
    test('a second press takes the numbers off', () {
      expect(_twice(_ordered, 'a\nb\nc'), ('1. a\n2. b\n3. c', 'a\nb\nc'));
    });

    test('a bullet swaps for a number, a task keeps its box', () {
      expect(_twice(_ordered, '- a\n- b'), ('1. a\n2. b', 'a\nb'));
      expect(
        _ordered('- [ ] a', const TextSelection.collapsed(offset: 0)).text,
        '1. [ ] a',
      );
    });

    test('numbers written by hand count as numbers, and go off', () {
      expect(_twice(_ordered, '3. a\n7. b'), ('a\nb', '1. a\n2. b'));
    });

    test('a numbered item among others is numbered anew', () {
      expect(_twice(_ordered, '3. a\nb'), ('1. a\n2. b', 'a\nb'));
    });

    test('blank lines among several are left alone and not counted', () {
      expect(_twice(_ordered, 'a\n\nb'), ('1. a\n\n2. b', 'a\n\nb'));
    });

    test('behind quote marks, and keeping an indent', () {
      expect(_twice(_ordered, '> a\n> b'), ('> 1. a\n> 2. b', '> a\n> b'));
      expect(_twice(_ordered, '  a'), ('  1. a', '  a'));
    });

    test('a CRLF note keeps its line endings', () {
      expect(_twice(_ordered, 'a\r\nb\r\n'), (
        '1. a\r\n2. b\r\n',
        'a\r\nb\r\n',
      ));
    });
  });

  group('the quote', () {
    test('a second press takes one level off', () {
      expect(_twice(_quote, 'a\nb'), ('> a\n> b', 'a\nb'));
    });

    test('a line already quoted is not quoted again', () {
      expect(_twice(_quote, '> a\nb'), ('> a\n> b', 'a\nb'));
    });

    test('a deeper quote loses one level only', () {
      expect(_twice(_quote, '> > a'), ('> a', 'a'));
      expect(
        _quote('>> a', const TextSelection.collapsed(offset: 0)).text,
        '> a',
      );
    });

    test('the mark goes before a list item and its indent', () {
      expect(_twice(_quote, '- a\n  - b'), ('> - a\n>   - b', '- a\n  - b'));
    });

    test('a mark with its spaces before it goes whole', () {
      expect(
        _quote('  > a', const TextSelection.collapsed(offset: 0)).text,
        'a',
      );
      expect(_quote('>a', const TextSelection.collapsed(offset: 0)).text, 'a');
    });

    test('a CRLF note keeps its line endings', () {
      expect(_twice(_quote, 'a\r\nb\r\n'), ('> a\r\n> b\r\n', 'a\r\nb\r\n'));
    });
  });

  group('the swaps between bullet, number and task', () {
    test('around the circle: bullet, number, task, and back', () {
      const caret = TextSelection.collapsed(offset: 0);
      var edit = _bullet('item', caret);
      expect(edit.text, '- item');
      edit = _ordered(edit.text, edit.selection);
      expect(edit.text, '1. item');
      edit = _task(edit.text, edit.selection);
      expect(edit.text, '1. [ ] item');
      edit = _bullet(edit.text, edit.selection);
      expect(edit.text, '- item');
    });
  });

  group('several lines, the selection as the surface keeps it', () {
    test('the bullets are put on and taken off on a selection model', () {
      const selection = SelectionModel(anchor: 0, extent: 5);
      final on = _bullet(
        'a\nb\nc',
        TextSelection(
          baseOffset: selection.anchor,
          extentOffset: selection.extent,
        ),
      );
      expect(on.text, '- a\n- b\n- c');
      expect(
        on.selection,
        const TextSelection(baseOffset: 2, extentOffset: 11),
      );
    });
  });
}
