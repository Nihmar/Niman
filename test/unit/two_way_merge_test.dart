import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diff/three_way.dart';
import 'package:niman/src/diff/two_way_merge.dart';

String lines(List<String> l) => '${l.join('\n')}\n';

void main() {
  test('shared lines stand, every difference is a choice', () {
    final merge = mergeTwoWay(
      lines(['# Title', 'mine', 'shared', 'only here']),
      lines(['# Title', 'theirs', 'shared']),
    );
    expect(merge.conflicts.length, 2, reason: merge.describe());
    expect(
      merge.chunks.where((c) => c.kind != MergeKind.conflict),
      everyElement(
        isA<MergeChunk>().having((c) => c.kind, 'kind', MergeKind.unchanged),
      ),
    );
    expect(merge.text(), lines(['# Title', 'mine', 'shared', 'only here']));
    expect(
      merge.text([MergeChoice.remote, MergeChoice.remote]),
      lines(['# Title', 'theirs', 'shared']),
    );
    expect(
      merge.text([MergeChoice.both, MergeChoice.local]),
      lines(['# Title', 'mine', 'theirs', 'shared', 'only here']),
    );
  });

  test('a difference only one copy has leaves the other side empty', () {
    final merge = mergeTwoWay(lines(['a']), lines(['a', 'b']));
    final chunk = merge.conflicts.single;
    expect(chunk.base, isEmpty);
    expect(chunk.local, isEmpty);
    expect(chunk.remote, ['b']);
  });

  test('two unrelated copies are one choice', () {
    final merge = mergeTwoWay('mine\n', 'theirs\n');
    expect(merge.conflicts.single.local, ['mine']);
    expect(merge.text([MergeChoice.both]), 'mine\ntheirs\n');
  });

  test('line endings and trailing break follow the local copy', () {
    expect(mergeTwoWay('a\r\nb', 'a\r\nc\r\n').text(), 'a\r\nb');
  });
}
