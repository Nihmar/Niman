import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diff/three_way.dart';

String lines(List<String> l) => '${l.join('\n')}\n';

void main() {
  test('edits in different places merge without asking', () {
    final result = mergeThreeWay(
      lines(['# Shopping', 'bread', 'milk', 'coffee']),
      lines(['# Shopping', 'bread', 'milk', 'coffee', 'tea']),
      lines(['# Shopping list', 'bread', 'milk', 'coffee']),
    );
    expect(result.clean, isTrue, reason: result.describe());
    expect(
      result.text(),
      lines(['# Shopping list', 'bread', 'milk', 'coffee', 'tea']),
    );
    expect(result.changesLocal, isTrue, reason: 'the title came from there');
  });

  test('the same edit on both sides lands once', () {
    final result = mergeThreeWay(
      lines(['a', 'b']),
      lines(['a', 'B!']),
      lines(['a', 'B!']),
    );
    expect(result.clean, isTrue);
    expect(result.text(), lines(['a', 'B!']));
    expect(result.changesLocal, isFalse);
  });

  test('a line changed on both sides is a conflict with its three sides', () {
    final result = mergeThreeWay(
      lines(['intro', 'price: 10', 'end']),
      lines(['intro', 'price: 12', 'end']),
      lines(['intro', 'price: 15', 'end']),
    );
    expect(result.clean, isFalse);
    final conflict = result.conflicts.single;
    expect(conflict.base, ['price: 10']);
    expect(conflict.local, ['price: 12']);
    expect(conflict.remote, ['price: 15']);

    expect(result.text(), lines(['intro', 'price: 12', 'end']));
    expect(
      result.text([MergeChoice.remote]),
      lines(['intro', 'price: 15', 'end']),
    );
    expect(
      result.text([MergeChoice.both]),
      lines(['intro', 'price: 12', 'price: 15', 'end']),
    );
  });

  test('a deletion against an edit is a conflict', () {
    final result = mergeThreeWay(
      lines(['keep', 'doomed', 'keep too']),
      lines(['keep', 'keep too']),
      lines(['keep', 'doomed, but edited', 'keep too']),
    );
    final conflict = result.conflicts.single;
    expect(conflict.local, isEmpty);
    expect(conflict.remote, ['doomed, but edited']);
    expect(
      result.text([MergeChoice.remote]),
      lines(['keep', 'doomed, but edited', 'keep too']),
    );
    expect(result.text(), lines(['keep', 'keep too']));
  });

  test('a deletion on one side alone goes through', () {
    final result = mergeThreeWay(
      lines(['a', 'b', 'c']),
      lines(['a', 'b', 'c']),
      lines(['a', 'c']),
    );
    expect(result.clean, isTrue);
    expect(result.text(), lines(['a', 'c']));
  });

  test('additions at the end of both sides conflict', () {
    final result = mergeThreeWay(
      lines(['a']),
      lines(['a', 'mine']),
      lines(['a', 'theirs']),
    );
    expect(result.clean, isFalse);
    expect(result.text([MergeChoice.both]), lines(['a', 'mine', 'theirs']));
  });

  test('several regions keep their order and their own choices', () {
    final result = mergeThreeWay(
      lines(['1', '2', '3', '4', '5', '6', '7', '8', '9']),
      lines(['1', 'two (mine)', '3', '4', '5', '6', '7', 'eight (mine)', '9']),
      lines(['1', 'two (theirs)', '3', '4', '5', '6', '7', 'eight', '9']),
    );
    expect(result.conflicts, hasLength(2));
    expect(
      result.text([MergeChoice.remote, MergeChoice.local]),
      lines([
        '1',
        'two (theirs)',
        '3',
        '4',
        '5',
        '6',
        '7',
        'eight (mine)',
        '9',
      ]),
    );
  });

  test('the local line endings and trailing break survive', () {
    final result = mergeThreeWay(
      'a\nb\n',
      'a\r\nb\r\nlocal\r\n',
      'a\nb\nremote\n',
    );
    expect(result.text([MergeChoice.both]), 'a\r\nb\r\nlocal\r\nremote\r\n');
    final noBreak = mergeThreeWay('a\n', 'a\nx', 'a\n');
    expect(noBreak.text(), 'a\nx');
  });

  test('a file created on both sides is one conflict', () {
    final result = mergeThreeWay('', lines(['mine']), lines(['theirs']));
    expect(result.conflicts.single.base, isEmpty);
    expect(result.text(), lines(['mine']));
  });

  test('nothing changed anywhere', () {
    final result = mergeThreeWay(lines(['a']), lines(['a']), lines(['a']));
    expect(result.clean, isTrue);
    expect(result.changesLocal, isFalse);
    expect(result.text(), lines(['a']));
    expect(result.describe(), 'unchanged 1');
  });
}
