// #326: ticking a checklist item carries the tick down its branch — the
// items nested under it, at any depth — as one edit; a checklist-looking
// line inside a fenced code block is never one of them.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/task_cascade.dart';

/// [text] with the tick on [line] carried down its branch.
String _ticked(String text, int line, {bool ticked = true}) {
  final buffer = SourceBuffer.fromText(text);
  final edit = checklistTickEdit(
    buffer: buffer,
    blocks: BlockScanner(buffer).index.blocks,
    line: line,
    ticked: ticked,
  );
  expect(edit, isNotNull, reason: 'no edit for line $line');
  return buffer.substring(0, edit!.start) +
      edit.text +
      buffer.substring(edit.end, buffer.length);
}

void main() {
  group('taskBoxOffset', () {
    test('finds the state character of a task box', () {
      expect(taskBoxOffset('- [ ] todo'), 3);
      expect(taskBoxOffset('- [x] todo'), 3);
      expect(taskBoxOffset('  - [X] nested'), 5);
      expect(taskBoxOffset('1. [ ] numbered'), 4);
      expect(taskBoxOffset('- [x]'), 3);
    });

    test('finds the box behind the quote marks', () {
      // The read view hands over the raw line of a quoted task item.
      expect(taskBoxOffset('> - [ ] quoted'), 5);
      expect(taskBoxOffset('>- [x] tight'), 4);
      expect(taskBoxOffset('> > 1. [ ] deeper'), 8);
      expect(taskBoxOffset('   >   - [ ] indented'), 10);
      expect(taskBoxOffset('> plain [ ] text'), isNull);
    });

    test('is null off a task box', () {
      expect(taskBoxOffset('- plain'), isNull);
      expect(taskBoxOffset('a [ ] text'), isNull);
      expect(taskBoxOffset(''), isNull);
    });
  });

  group('checklistTickEdit', () {
    test('ticks the item and everything nested under it', () {
      const text =
          '- [ ] parent\n'
          '  - [ ] child\n'
          '    - [x] grandchild\n'
          '- [ ] sibling\n'
          '  - [ ] child of sibling';
      expect(
        _ticked(text, 0),
        '- [x] parent\n'
        '  - [x] child\n'
        '    - [x] grandchild\n'
        '- [ ] sibling\n'
        '  - [ ] child of sibling',
      );
    });

    test('a leaf ticks alone', () {
      const text =
          '- [ ] parent\n'
          '  - [ ] child\n'
          '- [ ] sibling';
      expect(
        _ticked(text, 1),
        '- [ ] parent\n'
        '  - [x] child\n'
        '- [ ] sibling',
      );
    });

    test('a quoted parent takes a quoted child with it (#361)', () {
      // A list inside a quote is one `quote` block to the scanner, so the
      // cascade reads the quote's own lines with their marks off: the child
      // is the item nested under the parent, and the sibling is not.
      const text = '> - [ ] parent\n>   - [ ] child\n> - [ ] sibling';
      expect(
        _ticked(text, 0),
        '> - [x] parent\n>   - [x] child\n> - [ ] sibling',
      );
    });

    test('a quoted item below the first line takes its own children', () {
      // The whole quoted list is one `quote` block: an item on any of its
      // lines carries the items nested under it, and only them.
      const text =
          '> - [ ] a\n'
          '>   - [ ] a1\n'
          '> - [ ] b\n'
          '>   - [ ] b1\n'
          '>     - [ ] b11\n'
          '> - [ ] c';
      expect(
        _ticked(text, 2),
        '> - [ ] a\n'
        '>   - [ ] a1\n'
        '> - [x] b\n'
        '>   - [x] b1\n'
        '>     - [x] b11\n'
        '> - [ ] c',
      );
      expect(
        _ticked(text, 3),
        '> - [ ] a\n'
        '>   - [ ] a1\n'
        '> - [ ] b\n'
        '>   - [x] b1\n'
        '>     - [x] b11\n'
        '> - [ ] c',
      );
    });

    test("the children past a quote are its last item's alone", () {
      // Indented items after a quoted head continue its last item: a
      // sibling above it in the quote does not take them.
      const text = '> - [ ] a\n> - [ ] b\n  - [ ] child';
      expect(_ticked(text, 0), '> - [x] a\n> - [ ] b\n  - [ ] child');
      expect(_ticked(text, 1), '> - [ ] a\n> - [x] b\n  - [x] child');
    });

    test('a quote in a quote is read through to its items', () {
      const text = '> intro\n> > - [ ] a\n> >   - [ ] a1\n> > - [ ] b';
      expect(
        _ticked(text, 1),
        '> intro\n> > - [x] a\n> >   - [x] a1\n> > - [ ] b',
      );
    });

    test('a quoted line that is not an item carries nothing', () {
      const text = '> text\n> - [ ] a';
      final buffer = SourceBuffer.fromText(text);
      expect(
        checklistBranch(
          buffer: buffer,
          blocks: BlockScanner(buffer).index.blocks,
          line: 0,
        ),
        isEmpty,
      );
    });

    test('a checklist line in a fenced code block is not a child', () {
      const text =
          '- [ ] parent\n'
          '  - [ ] child\n'
          '  ```\n'
          '  - [ ] not a task\n'
          '  ```\n'
          '- [ ] sibling';
      expect(
        _ticked(text, 0),
        '- [x] parent\n'
        '  - [x] child\n'
        '  ```\n'
        '  - [ ] not a task\n'
        '  ```\n'
        '- [ ] sibling',
      );
    });

    test('a list under a different container is not in the branch', () {
      const text =
          '- [ ] parent\n'
          '  - [ ] child\n'
          '\n'
          'Paragraph.\n'
          '\n'
          '- [ ] sibling\n'
          '  - [ ] child of sibling';
      expect(
        _ticked(text, 0),
        '- [x] parent\n'
        '  - [x] child\n'
        '\n'
        'Paragraph.\n'
        '\n'
        '- [ ] sibling\n'
        '  - [ ] child of sibling',
      );
    });

    test('no edit when nothing changes', () {
      const text = '- [x] parent\n  - [x] child';
      final buffer = SourceBuffer.fromText(text);
      expect(
        checklistTickEdit(
          buffer: buffer,
          blocks: BlockScanner(buffer).index.blocks,
          line: 0,
          ticked: true,
        ),
        isNull,
      );
    });

    test('the edit is one contiguous span from parent to last child', () {
      const text = '- [ ] parent\n  - [ ] child\n- [ ] sibling';
      final buffer = SourceBuffer.fromText(text);
      final edit = checklistTickEdit(
        buffer: buffer,
        blocks: BlockScanner(buffer).index.blocks,
        line: 0,
        ticked: true,
      )!;
      expect(edit.start, 0);
      expect(edit.end, text.indexOf('- [ ] sibling') - 1);
    });
  });
}
