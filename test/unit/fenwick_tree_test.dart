// The span index: offsets, lookups and the two update paths. The property
// test at the end is the one that matters — random spans, random edits, and
// every answer checked against a naive prefix sum.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/fenwick_tree.dart';

/// The naive answer for a list of spans: the offset of [index].
int naiveOffset(List<int> spans, int index) {
  var sum = 0;
  for (var i = 0; i < index; i++) {
    sum += spans[i];
  }
  return sum;
}

/// The naive answer for a list of spans: the span containing [offset], under
/// the contract in the docs — offset 0 belongs to index 0, and one past the end
/// clamps to the last index.
int naiveIndex(List<int> spans, int offset) {
  if (offset <= 0) return 0;
  var found = 0;
  var sum = 0;
  for (var i = 0; i < spans.length; i++) {
    if (sum <= offset) found = i;
    sum += spans[i];
  }
  return found;
}

void main() {
  group('over fixed spans', () {
    const spans = <int>[3, 1, 4, 1, 5, 9, 2, 6];

    test('offsetOf is the prefix sum', () {
      final tree = FenwickTree.fromSpans(spans);
      for (var i = 0; i <= spans.length; i++) {
        expect(tree.offsetOf(i), naiveOffset(spans, i), reason: 'index $i');
      }
    });

    test('total is the sum', () {
      expect(FenwickTree.fromSpans(spans).total, 31);
    });

    test('spanAt recovers each span', () {
      final tree = FenwickTree.fromSpans(spans);
      for (var i = 0; i < spans.length; i++) {
        expect(tree.spanAt(i), spans[i], reason: 'index $i');
      }
    });

    test('indexOf is the inverse of offsetOf, for every offset', () {
      final tree = FenwickTree.fromSpans(spans);
      for (var offset = 0; offset <= tree.total; offset++) {
        expect(
          tree.indexOf(offset),
          naiveIndex(spans, offset),
          reason: 'offset $offset',
        );
      }
    });

    test('an offset at a boundary belongs to the span that starts there', () {
      final tree = FenwickTree.fromSpans(<int>[2, 2, 2]);
      expect(tree.indexOf(0), 0);
      expect(tree.indexOf(1), 0);
      expect(tree.indexOf(2), 1);
      expect(tree.indexOf(4), 2);
      expect(tree.indexOf(6), 2, reason: 'one past the end clamps');
    });

    test('the shapes a buffer actually has behave', () {
      // `a\n` and `` are the two ends of it: a trailing empty line with no
      // terminator has a zero span, and an empty buffer is one zero span.
      final trailing = FenwickTree.fromSpans(<int>[2, 0]);
      expect(trailing.total, 2);
      expect(trailing.indexOf(0), 0);
      expect(trailing.indexOf(1), 0, reason: 'inside the terminator');
      expect(
        trailing.indexOf(2),
        1,
        reason: 'the start of the empty last line',
      );

      final empty = FenwickTree.fromSpans(<int>[0]);
      expect(empty.total, 0);
      expect(empty.indexOf(0), 0);
    });
  });

  group('updates', () {
    test('setSpan moves every later offset', () {
      final spans = <int>[3, 1, 4];
      final tree = FenwickTree.fromSpans(spans)..setSpan(1, 10);
      spans[1] = 10;
      for (var i = 0; i <= spans.length; i++) {
        expect(tree.offsetOf(i), naiveOffset(spans, i));
      }
      expect(tree.total, naiveOffset(spans, spans.length));
    });

    test('setSpan to the same value changes nothing', () {
      final tree = FenwickTree.fromSpans(<int>[3, 1, 4])..setSpan(1, 1);
      expect(tree.total, 8);
    });

    test('reset can grow and shrink the tree', () {
      final tree = FenwickTree.fromSpans(<int>[1, 2, 3])..reset(<int>[5]);
      expect(tree.length, 1);
      expect(tree.total, 5);
      tree.reset(<int>[2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
      expect(tree.length, 10);
      expect(tree.total, 20);
      expect(tree.indexOf(19), 9);
      expect(tree.offsetOf(5), 10);
    });
  });

  test('random spans and random edits agree with the naive answer', () {
    final random = Random(20260921);
    for (var round = 0; round < 40; round++) {
      final spans = <int>[
        for (var i = 0; i < 1 + random.nextInt(60); i++)
          if (random.nextInt(3) == 0) 0 else random.nextInt(200),
      ];
      final tree = FenwickTree.fromSpans(spans);
      for (var step = 0; step < 30; step++) {
        if (random.nextBool()) {
          final index = random.nextInt(spans.length);
          final span = random.nextInt(200);
          spans[index] = span;
          tree.setSpan(index, span);
        } else {
          tree.reset(spans);
        }
        expect(tree.total, naiveOffset(spans, spans.length));
        for (var i = 0; i <= spans.length; i++) {
          expect(tree.offsetOf(i), naiveOffset(spans, i));
        }
        for (var offset = 0; offset <= tree.total; offset++) {
          expect(tree.indexOf(offset), naiveIndex(spans, offset));
        }
      }
    }
  });
}
