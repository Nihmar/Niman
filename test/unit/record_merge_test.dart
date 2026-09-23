import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diff/record_merge.dart';

String lines(List<String> l) => '${l.join('\n')}\n';

void main() {
  test('a task added on each device keeps both', () {
    expect(
      mergeRecords(
        lines(['buy milk', 'call mum']),
        lines(['buy milk', 'call mum', 'pay rent']),
        lines(['buy milk', 'call mum', 'book dentist']),
      ),
      lines(['buy milk', 'call mum', 'pay rent', 'book dentist']),
    );
  });

  test('neighbouring tasks removed on different devices both go', () {
    expect(
      mergeRecords(
        lines(['a', 'b', 'c', 'd']),
        lines(['a', 'c', 'd']),
        lines(['a', 'b', 'd']),
      ),
      lines(['a', 'd']),
    );
  });

  test('a task removed here and one added there', () {
    expect(
      mergeRecords(lines(['a', 'b']), lines(['a']), lines(['a', 'b', 'c'])),
      lines(['a', 'c']),
    );
  });

  test('the same task added on both sides lands once', () {
    expect(
      mergeRecords(
        lines(['x 2026-09-20 old']),
        lines(['x 2026-09-20 old', 'x 2026-09-21 milk', 'x 2026-09-21 mine']),
        lines(['x 2026-09-20 old', 'x 2026-09-21 milk']),
      ),
      lines(['x 2026-09-20 old', 'x 2026-09-21 milk', 'x 2026-09-21 mine']),
    );
  });

  test('a task edited differently on both sides keeps both edits', () {
    expect(
      mergeRecords(
        lines(['a', 'task', 'b']),
        lines(['a', 'task due:2026-09-30', 'b']),
        lines(['a', '(A) task', 'b']),
      ),
      lines(['a', 'task due:2026-09-30', '(A) task', 'b']),
    );
  });

  test('without a common version it is the union, local order first', () {
    expect(
      mergeRecords(
        '',
        lines(['mine one', 'shared', 'mine two']),
        lines(['shared', 'theirs']),
      ),
      lines(['mine one', 'shared', 'mine two', 'theirs']),
    );
  });

  test('the local line endings and trailing break are kept', () {
    expect(
      mergeRecords('a\r\n', 'a\r\nb\r\n', 'a\r\nc\r\n'),
      'a\r\nb\r\nc\r\n',
    );
    expect(mergeRecords('', 'a', 'b\n'), 'a\nb');
  });

  test('both sides emptied is empty', () {
    expect(mergeRecords(lines(['a']), '', ''), '');
  });
}
