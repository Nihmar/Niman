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
