// Move to tasks (#1152): the edit that takes items out of a note and the one
// that puts them back.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/task_items.dart';
import 'package:niman/src/editor/task_items_edit.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

List<TaskItem> itemsOf(SourceBuffer buffer, [Iterable<int>? lines]) {
  final all = taskItemsIn(buffer: buffer, first: 0, last: buffer.lineCount - 1);
  return [
    for (final item in all)
      if (lines == null || lines.contains(item.line)) item,
  ];
}

String apply(String text, NoteSpanEdit edit) =>
    text.replaceRange(edit.start, edit.end, edit.text);

/// Takes the items on [lines] out of [text]: the note after, and what was
/// taken.
(String, TakenTaskItems) takeOut(String text, Iterable<int> lines) {
  final buffer = SourceBuffer.fromText(text);
  final plan = takeOutTaskItems(buffer, itemsOf(buffer, lines))!;
  return (apply(text, plan.edit), plan.taken);
}

String putBack(String text, TakenTaskItems taken) {
  final buffer = SourceBuffer.fromText(text);
  final edit = restoreTaskItems(buffer, taken, BlockScanner(buffer).blockAt)!;
  return apply(text, edit);
}

void main() {
  group('taking out', () {
    test('a middle item goes with its line break', () {
      final (after, taken) = takeOut('# a\n- [ ] x\n# b\n', [1]);
      expect(after, '# a\n# b\n');
      expect(taken.count, 1);
    });

    test('several items, apart, are one edit and keep what is between', () {
      final (after, taken) = takeOut(
        '- [ ] one\n# text\n- [x] two\n\n- [ ] three\n# end\n',
        [0, 2, 4],
      );
      expect(after, '# text\n\n# end\n');
      expect(taken.count, 3);
      expect(taken.runs, hasLength(3));
    });

    test('items that follow each other are one run', () {
      final (after, taken) = takeOut('# a\n- [ ] x\n- [ ] y\n# b', [1, 2]);
      expect(after, '# a\n# b');
      expect(taken.runs, hasLength(1));
    });

    test('the last line of a note takes the break before it', () {
      final (after, _) = takeOut('# a\n- [ ] x', [1]);
      expect(after, '# a');
    });

    test('the only line leaves an empty note', () {
      final (after, _) = takeOut('- [ ] x\n', [0]);
      expect(after, '');
      final (after2, _) = takeOut('- [ ] x', [0]);
      expect(after2, '');
    });

    test('a CRLF note keeps its line endings', () {
      final (after, _) = takeOut('# a\r\n- [ ] x\r\n# b\r\n', [1]);
      expect(after, '# a\r\n# b\r\n');
    });

    test('an item whose lines changed is not taken', () {
      final buffer = SourceBuffer.fromText('- [ ] x\n- [ ] y\n');
      final items = itemsOf(buffer);
      final changed = SourceBuffer.fromText('- [ ] x edited\n- [ ] y\n');
      final plan = takeOutTaskItems(changed, items)!;
      expect(apply(changed.text, plan.edit), '- [ ] x edited\n');
      expect(plan.taken.count, 1);
    });

    test('nothing is taken when nothing is where it was', () {
      final buffer = SourceBuffer.fromText('- [ ] x\n');
      final items = itemsOf(buffer);
      expect(takeOutTaskItems(SourceBuffer.fromText('other\n'), items), isNull);
    });
  });

  group('putting back', () {
    test('at the same place when the note is as it was', () {
      const text = '# a\n- [ ] x\n- [x] y\n# b\n- [ ] z\n# end\n';
      final (after, taken) = takeOut(text, [1, 2, 4]);
      expect(putBack(after, taken), text);
    });

    test('the last line of a note', () {
      const text = '# a\n- [ ] x';
      final (after, taken) = takeOut(text, [1]);
      expect(putBack(after, taken), text);
    });

    test('the only line of a note', () {
      for (final text in ['- [ ] x\n', '- [ ] x']) {
        final (after, taken) = takeOut(text, [0]);
        expect(putBack(after, taken), text);
      }
    });

    test('a CRLF note', () {
      const text = '# a\r\n- [ ] x\r\n# b\r\n';
      final (after, taken) = takeOut(text, [1]);
      expect(putBack(after, taken), text);
    });

    test('lines added above move the place with them', () {
      final (after, taken) = takeOut('# a\n- [ ] x\n# b\n', [1]);
      expect(
        putBack('# new\n# new2\n$after', taken),
        '# new\n# new2\n# a\n- [ ] x\n# b\n',
      );
    });

    test('the line below edited: after its predecessor', () {
      final (after, taken) = takeOut('# a\n- [ ] x\n# b\n', [1]);
      expect(
        putBack(after.replaceFirst('# b', '# b edited'), taken),
        '# a\n- [ ] x\n# b edited\n',
      );
    });

    test('the line above edited: before its successor', () {
      final (after, taken) = takeOut('# a\n- [ ] x\n# b\n', [1]);
      expect(
        putBack(after.replaceFirst('# a', '# a edited'), taken),
        '# a edited\n- [ ] x\n# b\n',
      );
    });

    test('both neighbours gone: at a block start, never inside a fence', () {
      final (after, taken) = takeOut('# a\n- [ ] x\n# b\n', [1]);
      expect(after, '# a\n# b\n');
      final put = putBack('# p\n# q\n```\ncode\n```\n', taken);
      expect(put, contains('- [ ] x\n'));
      expect(put, isNot(contains('code\n- [ ] x')));
      expect(put, isNot(contains('```\n- [ ] x')));
    });

    test('into an empty note', () {
      final (_, taken) = takeOut('# a\n- [ ] x\n# b\n', [1]);
      expect(putBack('', taken), '- [ ] x\n');
    });
  });
}
