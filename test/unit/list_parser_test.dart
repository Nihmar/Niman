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

  group('listLineCount', () {
    test('a trailing newline is not a line', () {
      expect(listLineCount(''), 0);
      expect(listLineCount('a'), 1);
      expect(listLineCount('a\n'), 1);
      expect(listLineCount('a\n\n'), 2);
    });
  });

  group('subtreeEnd', () {
    test('the subtree runs to the next smaller-or-equal item', () {
      final items = parseListItems(
        '- [ ] a\n  - [ ] b\nprose\n- [ ] c\n',
      );
      expect(
          subtreeEnd(
              items, 0, listLineCount('- [ ] a\n  - [ ] b\nprose\n- [ ] c\n')),
          3);
      expect(subtreeEnd(items, 2, 4), 4);
    });
  });

  group('resolveListDrop', () {
    test('before/after/under resolve to sibling indents', () {
      const text = '- [ ] a\n- [ ] b\n';
      final items = parseListItems(text);
      final n = listLineCount(text);
      expect(
        resolveListDrop(items, 0, 1, ListDropMode.before, n),
        (insertLine: 1, indent: 0),
      );
      expect(
        resolveListDrop(items, 0, 1, ListDropMode.after, n),
        (insertLine: 2, indent: 0),
      );
      expect(
        resolveListDrop(items, 0, 1, ListDropMode.under, n),
        (insertLine: 2, indent: 2),
      );
    });

    test('the list edges resolve to root level', () {
      const text = '- [ ] a\n- [ ] b\n';
      final items = parseListItems(text);
      final n = listLineCount(text);
      expect(
        resolveListDrop(items, 1, -1, ListDropMode.before, n),
        (insertLine: 0, indent: 0),
      );
      expect(
        resolveListDrop(items, 0, items.length, ListDropMode.after, n),
        (insertLine: 2, indent: 0),
      );
    });

    test('dropping on itself or its own child is a no-op', () {
      const text = '- [ ] a\n  - [ ] b\n';
      final items = parseListItems(text);
      final n = listLineCount(text);
      expect(resolveListDrop(items, 0, 0, ListDropMode.under, n), isNull);
      expect(resolveListDrop(items, 0, 1, ListDropMode.under, n), isNull);
      expect(
        resolveListDrop(items, 0, 1, ListDropMode.before, n),
        isNull,
      );
    });
  });

  group('moveSubtree', () {
    test('reordering keeps every line byte-identical', () {
      const text = '- [ ] a\n- [ ] b\n';
      final items = parseListItems(text);
      final drop = resolveListDrop(
        items,
        0,
        1,
        ListDropMode.after,
        listLineCount(text),
      )!;
      expect(
        moveSubtree(
          text,
          items,
          0,
          insertLine: drop.insertLine,
          indent: drop.indent,
        ),
        '- [ ] b\n- [ ] a\n',
      );
    });

    test('a moved item takes its children and prose with it', () {
      const text = '- [ ] a\n  - [ ] b\nprose\n- [ ] c\n';
      final items = parseListItems(text);
      final drop = resolveListDrop(
        items,
        0,
        2,
        ListDropMode.after,
        listLineCount(text),
      )!;
      expect(
        moveSubtree(
          text,
          items,
          0,
          insertLine: drop.insertLine,
          indent: drop.indent,
        ),
        '- [ ] c\n- [ ] a\n  - [ ] b\nprose\n',
      );
    });

    test('dropping under re-indents the whole subtree', () {
      const text = '- [ ] a\n  - [ ] b\n- [ ] c\n';
      final items = parseListItems(text);
      final drop = resolveListDrop(
        items,
        0,
        2,
        ListDropMode.under,
        listLineCount(text),
      )!;
      expect(
        moveSubtree(
          text,
          items,
          0,
          insertLine: drop.insertLine,
          indent: drop.indent,
        ),
        '- [ ] c\n  - [ ] a\n    - [ ] b\n',
      );
    });

    test('dropping before a shallower item outdents the subtree', () {
      const text = '- [ ] a\n  - [ ] b\n- [ ] c\n';
      final items = parseListItems(text);
      final drop = resolveListDrop(
        items,
        1,
        2,
        ListDropMode.before,
        listLineCount(text),
      )!;
      expect(
        moveSubtree(
          text,
          items,
          1,
          insertLine: drop.insertLine,
          indent: drop.indent,
        ),
        '- [ ] a\n- [ ] b\n- [ ] c\n',
      );
    });

    test('a trailing newline is preserved', () {
      const text = '- [ ] a\n- [ ] b\n';
      final items = parseListItems(text);
      final drop = resolveListDrop(
        items,
        1,
        -1,
        ListDropMode.before,
        listLineCount(text),
      )!;
      expect(
        moveSubtree(
          text,
          items,
          1,
          insertLine: drop.insertLine,
          indent: drop.indent,
        ),
        '- [ ] b\n- [ ] a\n',
      );
    });
  });

  group('editItemText', () {
    test('replaces only the item text, byte-stable otherwise', () {
      const text = 'prose\n- [ ] one\n- [x] two\n';
      final items = parseListItems(text);
      expect(
        editItemText(text, items[0], 'one edited'),
        'prose\n- [ ] one edited\n- [x] two\n',
      );
      expect(
        editItemText(text, items[1], ''),
        'prose\n- [ ] one\n- [x] \n',
      );
    });
  });

  group('listNoteContent', () {
    test('is a closed type: list frontmatter block', () {
      expect(listNoteContent(), '---\ntype: list\n---\n');
      expect(frontmatterTypeOf(listNoteContent()), 'list');
    });
  });
}
