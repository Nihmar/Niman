import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diff/line_diff.dart';

/// Rebuilds both texts from a diff: the property every diff must hold.
(String, String) sides(List<DiffLine> diff) => (
  [
    for (final l in diff)
      if (l.kind != DiffKind.added) l.text,
  ].join('\n'),
  [
    for (final l in diff)
      if (l.kind != DiffKind.removed) l.text,
  ].join('\n'),
);

String render(List<DiffLine> diff) => diff.map((l) => '$l').join('|');

void main() {
  test('identical texts are all unchanged', () {
    final diff = diffLines('a\nb\n', 'a\nb');
    expect(render(diff), ' a| b');
    expect(DiffSummary.of(diff).identical, isTrue);
  });

  test('a changed line reads as removed then added', () {
    expect(render(diffLines('a\nb\nc', 'a\nB\nc')), ' a|-b|+B| c');
  });

  test('insertions and deletions keep their line numbers', () {
    final diff = diffLines('one\ntwo\nthree', 'zero\none\nthree\nfour');
    expect(render(diff), '+zero| one|-two| three|+four');
    final two = diff.firstWhere((l) => l.text == 'two');
    expect(two.oldLine, 2);
    expect(two.newLine, isNull);
    final four = diff.firstWhere((l) => l.text == 'four');
    expect(four.newLine, 4);
  });

  test('empty sides', () {
    expect(render(diffLines('', 'x\ny')), '+x|+y');
    expect(render(diffLines('x', '')), '-x');
    expect(diffLines('', ''), isEmpty);
  });

  test('CRLF and LF compare equal', () {
    expect(DiffSummary.of(diffLines('a\r\nb', 'a\nb')).identical, isTrue);
  });

  test('random edits always rebuild both texts', () {
    final random = Random(56);
    for (var round = 0; round < 200; round++) {
      final a = [
        for (var i = 0; i < random.nextInt(30); i++) 'l${random.nextInt(8)}',
      ];
      final b = [
        for (final line in a)
          if (random.nextInt(4) != 0) line,
      ];
      for (var i = 0; i < random.nextInt(6); i++) {
        b.insert(random.nextInt(b.length + 1), 'n${random.nextInt(8)}');
      }
      final diff = diffLines(a.join('\n'), b.join('\n'));
      expect(sides(diff), (a.join('\n'), b.join('\n')), reason: 'round $round');
    }
  });

  test('past the edit limit the middle is replaced wholesale', () {
    final a = [for (var i = 0; i < 50; i++) 'a$i'].join('\n');
    final b = [for (var i = 0; i < 50; i++) 'b$i'].join('\n');
    final diff = diffLines('head\n$a\ntail', 'head\n$b\ntail', maxEdits: 10);
    expect(sides(diff), ('head\n$a\ntail', 'head\n$b\ntail'));
    expect(diff.first.kind, DiffKind.same);
    expect(diff[1].kind, DiffKind.removed);
  });

  group('summary', () {
    test('folds long unchanged runs between hunks', () {
      final old = [for (var i = 1; i <= 30; i++) 'line $i'];
      final changed = [...old]
        ..[1] = 'line 2 edited'
        ..[24] = 'line 25 edited';
      final summary = DiffSummary.of(
        diffLines(old.join('\n'), changed.join('\n')),
      );
      expect(summary.hunks, hasLength(2));
      expect(summary.added, 2);
      expect(summary.removed, 2);
      expect(summary.hunks.first.oldStart, 1);
      expect(summary.hunks.first.oldEnd, 5);
      expect(summary.gaps, [0, 16, 2]);
    });

    test('nearby changes share one hunk', () {
      final summary = DiffSummary.of(
        diffLines('a\nb\nc\nd\ne', 'A\nb\nc\nd\nE'),
      );
      expect(summary.hunks, hasLength(1));
    });
  });

  group('compose', () {
    // Two changes far enough apart to be separate hunks: line 1 and
    // line 25 of a 30-line note.
    DiffSummary twoHunks() {
      final old = [for (var i = 1; i <= 30; i++) 'line $i'];
      final changed = [...old]
        ..[0] = 'line 1 now'
        ..[24] = 'line 25 now';
      return DiffSummary.of(diffLines(old.join('\n'), changed.join('\n')));
    }

    test('takes the new text when nothing is picked', () {
      final summary = twoHunks();
      expect(summary.hunks, hasLength(2));
      expect(summary.compose(const {}), contains('line 1 now'));
      expect(summary.compose(const {}), contains('line 25 now'));
      expect(summary.compose(const {}), isNot(contains('line 1\n')));
    });

    test('takes the old text in the hunks picked, and only those', () {
      final summary = twoHunks();
      final text = summary.compose(const {0});
      expect(text, contains('line 1\n'));
      expect(text, isNot(contains('line 1 now')));
      // The other hunk is untouched.
      expect(text, contains('line 25 now'));
      expect(text, isNot(contains('line 25\n')));
    });

    test('every hunk picked rebuilds the old text', () {
      final old = [for (var i = 1; i <= 30; i++) 'line $i'].join('\n');
      final summary = twoHunks();
      expect(summary.compose(const {0, 1}), '$old\n');
    });

    test('keeps the line ending and the trailing break it is given', () {
      final summary = DiffSummary.of(diffLines('a\nb', 'A\nb'));
      expect(summary.compose(const {}, lineEnding: '\r\n'), 'A\r\nb\r\n');
      expect(summary.compose(const {}, trailingNewline: false), 'A\nb');
    });

    test('an added-only hunk drops the addition when the old side wins', () {
      final summary = DiffSummary.of(diffLines('a\n', 'a\nnew\n'));
      expect(summary.compose(const {}), 'a\nnew\n');
      expect(summary.compose(const {0}), 'a\n');
    });

    test('a removed-only hunk brings the line back', () {
      final summary = DiffSummary.of(diffLines('a\ngone\n', 'a\n'));
      expect(summary.compose(const {}), 'a\n');
      expect(summary.compose(const {0}), 'a\ngone\n');
    });
  });
}
