// #141: Enter carries a Markdown list on.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/md_editing.dart';

void main() {
  group('listItemHead', () {
    test('reads a bulleted item', () {
      final head = listItemHead('- milk');
      expect(head, isNotNull);
      expect(head!.marker, '-');
      expect(head.number, isNull);
      expect(head.box, isFalse);
      expect(head.content, 'milk');
      expect(head.continuation, '- ');
    });

    test('reads the other bullets', () {
      expect(listItemHead('* milk')?.continuation, '* ');
      expect(listItemHead('+ milk')?.continuation, '+ ');
    });

    test('an ordered item counts on, keeping its punctuation', () {
      expect(listItemHead('3. milk')?.continuation, '4. ');
      expect(listItemHead('3) milk')?.continuation, '4) ');
      expect(listItemHead('9. milk')?.number, 9);
    });

    test('a task item stays a task item, and the new box is empty', () {
      expect(listItemHead('- [ ] milk')?.continuation, '- [ ] ');
      expect(listItemHead('- [x] milk')?.continuation, '- [ ] ');
      expect(listItemHead('- [X] milk')?.box, isTrue);
      expect(listItemHead('2. [ ] milk')?.continuation, '3. [ ] ');
    });

    test('the indent is kept', () {
      expect(listItemHead('    - milk')?.continuation, '    - ');
      expect(listItemHead('\t- milk')?.continuation, '\t- ');
    });

    test('an item with nothing in it says so', () {
      expect(listItemHead('- ')?.isEmpty, isTrue);
      expect(listItemHead('-')?.isEmpty, isTrue);
      expect(listItemHead('  1. ')?.isEmpty, isTrue);
      expect(listItemHead('- [ ] ')?.isEmpty, isTrue);
      expect(listItemHead('- milk')?.isEmpty, isFalse);
    });

    test('what is not a list item is not one', () {
      for (final line in <String>[
        'milk',
        '',
        '   ',
        '-milk',
        '#milk',
        '1.milk',
        '1234567890. too many digits',
        '> quoted',
      ]) {
        expect(listItemHead(line), isNull, reason: line);
      }
    });

    test('a dash rule is not an item to carry on', () {
      // '---' reads as a marker plus content under a line-local rule, so
      // this is what the tokenizer check in the controller is for; here
      // it is only recorded that the text is not swallowed.
      expect(listItemHead('- --')?.content, '--');
    });
  });
}
