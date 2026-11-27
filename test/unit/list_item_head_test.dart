// What a line says about the list item it may be: the head Enter, the indent
// and the checklist read (#142, #1341, #1342).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/list_item_head.dart';

void main() {
  group('a thematic break is not an item (#1341)', () {
    for (final line in <String>[
      '- - -',
      '* * *',
      '-  -  -',
      '- --',
      '  - - -',
      '- - - -',
      '- - -  ',
      '***',
      '---',
      '_ _ _',
    ]) {
      test(line, () => expect(listItemHead(line), isNull));
    }

    test('an item that merely starts with dashes still is one', () {
      expect(listItemHead('- - a')!.content, '- a');
      expect(listItemHead('- --a')!.content, '--a');
      expect(listItemHead('* * a')!.content, '* a');
      expect(listItemHead('- -')!.content, '-');
    });
  });

  group('a task box at the end of the line is an empty task (#1342)', () {
    test('with and without the space after it', () {
      for (final line in <String>['- [ ]', '- [ ] ', '- [x]', '1. [X]\t']) {
        final head = listItemHead(line)!;
        expect(head.box, isTrue, reason: line);
        expect(head.isEmpty, isTrue, reason: line);
      }
    });

    test('a box with text glued to it is text', () {
      final head = listItemHead('- [ ]x')!;
      expect(head.box, isFalse);
      expect(head.content, '[ ]x');
    });

    test('a box with text after it is a task', () {
      final head = listItemHead('- [ ] a')!;
      expect(head.box, isTrue);
      expect(head.content, 'a');
    });
  });

  group('the marker of another number keeps the padding (#1342)', () {
    for (final (line, number, expected) in <(String, int, String)>[
      ('01. a', 2, '02.'),
      ('09. a', 10, '10.'),
      ('009) a', 10, '010)'),
      ('9. a', 10, '10.'),
      ('10. a', 3, '3.'),
      ('1. a', 7, '7.'),
    ]) {
      test('$line as $number', () {
        expect(listItemHead(line)!.markerFor(number), expected);
      });
    }

    test('a bulleted item has its own marker', () {
      expect(listItemHead('* a')!.markerFor(4), '*');
    });
  });
}
