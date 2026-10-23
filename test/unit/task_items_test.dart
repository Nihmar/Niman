// Move to tasks (#1152): which lines of a note are checkbox items that can
// be moved, read off the block scan.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/task_items.dart';
import 'package:niman/src/markdown/source_buffer.dart';

List<TaskItem> itemsIn(String text, {int first = 0, int? last}) {
  final buffer = SourceBuffer.fromText(text);
  return taskItemsIn(
    buffer: buffer,
    first: first,
    last: last ?? buffer.lineCount - 1,
  );
}

void main() {
  group('markers and boxes', () {
    test('every bullet and an ordered marker', () {
      final items = itemsIn(
        '- [ ] dash\n* [ ] star\n+ [ ] plus\n1. [ ] dot\n2) [ ] paren\n',
      );
      expect(items.map((i) => i.text), [
        'dash',
        'star',
        'plus',
        'dot',
        'paren',
      ]);
      expect(items.every((i) => i.movable && !i.checked), isTrue);
    });

    test('a ticked box, either case', () {
      final items = itemsIn('- [x] low\n- [X] high\n- [ ] open\n');
      expect(items.map((i) => i.checked), [true, true, false]);
    });

    test('any indent, a nested item without children included', () {
      final items = itemsIn('- [ ] top\n  - [ ] nested\n');
      expect(items.map((i) => i.text), ['top', 'nested']);
      expect(items[0].hasSubItems, isTrue);
      expect(items[1].movable, isTrue);
    });

    test('the words keep their inline Markdown', () {
      final items = itemsIn('- [ ] Call **Marco** about [[Roof]] `now`\n');
      expect(items.single.text, 'Call **Marco** about [[Roof]] `now`');
    });

    test('continuation lines join the words on one line', () {
      final items = itemsIn('- [ ] first part\n  second   part\n- [ ] next\n');
      expect(items.first.text, 'first part second part');
      expect(items.first.line, 0);
      expect(items.first.endLine, 2);
    });

    test('a plain list item, a box without words and a paragraph are not', () {
      expect(itemsIn('- plain\n'), isEmpty);
      expect(itemsIn('- [ ] \n').single.movable, isFalse);
      expect(itemsIn('- [ ]\n'), isEmpty);
      expect(itemsIn('[ ] not in a list\n'), isEmpty);
      expect(itemsIn('- [y] not a box\n'), isEmpty);
      expect(itemsIn('- [x]glued\n'), isEmpty);
    });
  });

  group('what is code or quote', () {
    test('a fenced block is never read', () {
      expect(itemsIn('```\n- [ ] in a fence\n```\n'), isEmpty);
      expect(itemsIn('~~~md\n- [x] in a tilde fence\n~~~\n'), isEmpty);
    });

    test('an indented code block and front matter are never read', () {
      expect(itemsIn('para\n\n    - [ ] code\n'), isEmpty);
      expect(itemsIn('---\ntitle: - [ ] x\n---\n- [ ] real\n'), hasLength(1));
    });

    test('an item inside a quote is left alone', () {
      expect(itemsIn('> - [ ] quoted\n'), isEmpty);
    });

    test('an item after a fence is read', () {
      final items = itemsIn('```\n- [ ] no\n```\n- [ ] yes\n');
      expect(items.single.text, 'yes');
      expect(items.single.line, 3);
    });
  });

  group('sub-items', () {
    test('an item with a nested item or a held paragraph is blocked', () {
      expect(itemsIn('- [ ] a\n  - [ ] b\n').first.hasSubItems, isTrue);
      expect(itemsIn('- [ ] a\n  - plain\n').first.hasSubItems, isTrue);
      expect(itemsIn('- [ ] a\n\n  para\n').first.hasSubItems, isTrue);
      expect(
        itemsIn('- [ ] a\n  ```\n  code\n  ```\n').first.hasSubItems,
        isTrue,
      );
    });

    test('a sibling, or text after the list, is not a sub-item', () {
      expect(itemsIn('- [ ] a\n- [ ] b\n').first.hasSubItems, isFalse);
      expect(itemsIn('- [ ] a\n\n- [ ] b\n').first.hasSubItems, isFalse);
      expect(itemsIn('- [ ] a\n\nafter\n').first.hasSubItems, isFalse);
      expect(itemsIn('- [ ] a\n').first.hasSubItems, isFalse);
    });

    test('an ordered item with a nested one is blocked', () {
      expect(itemsIn('1. [ ] a\n   - [x] b\n').first.hasSubItems, isTrue);
    });
  });

  group('the range', () {
    const text = '- [ ] a\n- [ ] b\n- [x] c\n\nplain\n';

    test('one line is one item', () {
      expect(itemsIn(text, first: 1, last: 1).single.text, 'b');
    });

    test('a selection covers the items it touches, in order', () {
      expect(itemsIn(text, first: 1, last: 4).map((i) => i.text), ['b', 'c']);
    });

    test('a continuation line is its item', () {
      final items = itemsIn('- [ ] a\n  more\n- [ ] b\n', first: 1, last: 1);
      expect(items.single.text, 'a more');
    });

    test('a range past the note is clamped', () {
      expect(itemsIn(text, first: 2, last: 99).map((i) => i.text), ['c']);
    });
  });
}
