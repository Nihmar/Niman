// T-TK-03/04: the list parser — task items, nesting, byte-stable edits.
import 'package:copist/src/frontmatter/parser.dart';
import 'package:copist/src/ui/kinds/list_note.dart';
import 'package:copist/src/ui/kinds/list_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseListItems', () {
    test('parses - [ ] and - [x] items with line and text', () {
      final items = parseListItems('# T\n- [ ] one\n- [x] two\n');
      expect(items, hasLength(2));
      expect(items[0].line, 1);
      expect(items[0].depth, 0);
      expect(items[0].checked, isFalse);
      expect(items[0].text, 'one');
      expect(items[1].line, 2);
      expect(items[1].checked, isTrue);
      expect(items[1].text, 'two');
    });

    test('indentation defines nesting depth', () {
      final items = parseListItems('- [ ] a\n  - [ ] b\n  - [ ] c\n- [ ] d\n');
      expect(items.map((i) => i.depth).toList(), [0, 1, 1, 0]);
    });

    test('*, + and numbered markers count too', () {
      final items = parseListItems('* [ ] one\n+ [x] two\n1. [ ] three\n');
      expect(items.map((i) => i.text).toList(), ['one', 'two', 'three']);
      expect(items.map((i) => i.checked).toList(), [false, true, false]);
    });

    test('prose, headings and boxless list lines are not items', () {
      final items = parseListItems(
        '# Head\nprose\n- plain\n- [ ] task\n- no box then [ ] later\n',
      );
      expect(items, hasLength(1));
      expect(items.single.text, 'task');
    });

    test('fences and the frontmatter block are not items', () {
      final items = parseListItems(
        '---\ntype: list\n---\n```\n- [ ] in fence\n```\n- [ ] real\n',
      );
      expect(items, hasLength(1));
      expect(items.single.text, 'real');
    });

    test('a prose-only note is an empty checklist', () {
      expect(parseListItems('just prose\nand more\n'), isEmpty);
      expect(parseListItems(''), isEmpty);
    });
  });

  group('flipListItem', () {
    test('flips only the box character, byte-stable otherwise', () {
      const text = 'prose\n- [ ] one\n  - [x] two\nmore\n';
      final items = parseListItems(text);
      expect(
        flipListItem(text, items[0]),
        'prose\n- [x] one\n  - [x] two\nmore\n',
      );
      // Flipping twice restores the note.
      expect(
        flipListItem(flipListItem(text, items[0]), items[0]),
        text,
      );
      expect(
        flipListItem(text, items[1]),
        'prose\n- [ ] one\n  - [ ] two\nmore\n',
      );
    });
  });

  group('appendListItem', () {
    test('appends an unchecked item line', () {
      expect(appendListItem('', 'x'), '- [ ] x\n');
      expect(appendListItem('a\n', 'x'), 'a\n- [ ] x\n');
      expect(appendListItem('a', 'x'), 'a\n- [ ] x\n');
    });
  });

  group('listNoteContent', () {
    test('is a closed type: list frontmatter block', () {
      expect(listNoteContent(), '---\ntype: list\n---\n');
      expect(frontmatterTypeOf(listNoteContent()), 'list');
    });
  });
}
