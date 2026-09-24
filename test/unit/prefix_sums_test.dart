// The span index: offsets, lookups, the value update and the splice. The
// property tests at the end are the ones that matter — random spans, random
// edits, insertions and deletions across chunk boundaries, and every answer
// checked against a naive prefix sum.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/prefix_sums.dart';

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

/// Sums over integer spans, the shape the buffer gives them.
PrefixSums _sums(List<int> spans) =>
    PrefixSums(<double>[for (final span in spans) span.toDouble()]);

void main() {
  group('over fixed spans', () {
    const spans = <int>[3, 1, 4, 1, 5, 9, 2, 6];

    test('offsetOf is the prefix sum', () {
      final tree = _sums(spans);
      for (var i = 0; i <= spans.length; i++) {
        expect(tree.offsetOf(i), naiveOffset(spans, i), reason: 'index $i');
      }
    });

    test('total is the sum', () {
      expect(_sums(spans).total, 31);
    });

    test('spanAt recovers each span', () {
      final tree = _sums(spans);
      for (var i = 0; i < spans.length; i++) {
        expect(tree.valueAt(i), spans[i], reason: 'index $i');
      }
    });

    test('indexOf is the inverse of offsetOf, for every offset', () {
      final tree = _sums(spans);
      for (var offset = 0; offset <= tree.total; offset++) {
        expect(
          tree.indexOf(offset.toDouble()),
          naiveIndex(spans, offset),
          reason: 'offset $offset',
        );
      }
    });

    test('an offset at a boundary belongs to the span that starts there', () {
      final tree = _sums(<int>[2, 2, 2]);
      expect(tree.indexOf(0), 0);
      expect(tree.indexOf(1), 0);
      expect(tree.indexOf(2), 1);
      expect(tree.indexOf(4), 2);
      expect(tree.indexOf(6), 2, reason: 'one past the end clamps');
    });

    test('the shapes a buffer actually has behave', () {
      // `a\n` and `` are the two ends of it: a trailing empty line with no
      // terminator has a zero span, and an empty buffer is one zero span.
      final trailing = _sums(<int>[2, 0]);
      expect(trailing.total, 2);
      expect(trailing.indexOf(0), 0);
      expect(trailing.indexOf(1), 0, reason: 'inside the terminator');
      expect(
        trailing.indexOf(2),
        1,
        reason: 'the start of the empty last line',
      );

      final empty = _sums(<int>[0]);
      expect(empty.total, 0);
      expect(empty.indexOf(0), 0);
    });
  });

  group('updates', () {
    test('setSpan moves every later offset', () {
      final spans = <int>[3, 1, 4];
      final tree = _sums(spans)..setValue(1, 10);
      spans[1] = 10;
      for (var i = 0; i <= spans.length; i++) {
        expect(tree.offsetOf(i), naiveOffset(spans, i));
      }
      expect(tree.total, naiveOffset(spans, spans.length));
    });

    test('setSpan to the same value changes nothing', () {
      final tree = _sums(<int>[3, 1, 4])..setValue(1, 1);
      expect(tree.total, 8);
    });

    test('splice can grow and shrink the list', () {
      final tree = _sums(<int>[1, 2, 3])..splice(0, 3, <double>[5]);
      expect(tree.length, 1);
      expect(tree.total, 5);
      tree.splice(0, 1, List<double>.filled(10, 2));
      expect(tree.length, 10);
      expect(tree.total, 20);
      expect(tree.indexOf(19), 9);
      expect(tree.offsetOf(5), 10);
      tree.splice(0, 10, <double>[]);
      expect(tree.length, 0);
      expect(tree.total, 0);
      expect(tree.indexOf(0), 0);
    });
  });

  test('random spans and random edits agree with the naive answer', () {
    final random = Random(20260921);
    for (var round = 0; round < 40; round++) {
      final spans = <int>[
        for (var i = 0; i < 1 + random.nextInt(60); i++)
          if (random.nextInt(3) == 0) 0 else random.nextInt(200),
      ];
      final tree = _sums(spans);
      for (var step = 0; step < 30; step++) {
        if (random.nextBool()) {
          final index = random.nextInt(spans.length);
          final span = random.nextInt(200);
          spans[index] = span;
          tree.setValue(index, span.toDouble());
        } else {
          final at = random.nextInt(spans.length + 1);
          tree.splice(at, 0, <double>[]);
        }
        expect(tree.total, naiveOffset(spans, spans.length));
        for (var i = 0; i <= spans.length; i++) {
          expect(tree.offsetOf(i), naiveOffset(spans, i));
        }
        for (var offset = 0; offset <= tree.total; offset++) {
          expect(tree.indexOf(offset.toDouble()), naiveIndex(spans, offset));
        }
      }
    }
  });

  test(
    'insertions and deletions across chunks agree with the naive answer',
    () {
      // Thousands of values, so the edits cross the chunks' edges: an Enter is
      // one value in, a joined line one out, a paste many in, a cut many out.
      final random = Random(20260922);
      final spans = <int>[
        for (var i = 0; i < 5000; i++)
          if (random.nextInt(5) == 0) 0 else 1 + random.nextInt(80),
      ];
      final tree = _sums(spans);
      void check() {
        expect(tree.length, spans.length);
        expect(tree.total, naiveOffset(spans, spans.length));
        for (var probe = 0; probe < 200; probe++) {
          final index = random.nextInt(spans.length + 1);
          expect(
            tree.offsetOf(index),
            naiveOffset(spans, index),
            reason: 'offsetOf $index',
          );
          final offset = random.nextInt(naiveOffset(spans, spans.length) + 2);
          expect(
            tree.indexOf(offset.toDouble()),
            naiveIndex(spans, offset),
            reason: 'indexOf $offset',
          );
        }
      }

      for (var step = 0; step < 300; step++) {
        final first = random.nextInt(spans.length + 1);
        final removed = random.nextInt(4) == 0
            ? random.nextInt((spans.length - first) + 1)
            : random.nextInt(3).clamp(0, spans.length - first);
        final inserted = <int>[
          for (
            var i = 0;
            i <
                (random.nextInt(6) == 0
                    ? random.nextInt(3000)
                    : random.nextInt(3));
            i++
          )
            random.nextInt(80),
        ];
        spans.replaceRange(first, first + removed, inserted);
        tree.splice(first, removed, <double>[
          for (final span in inserted) span.toDouble(),
        ]);
        if (spans.isEmpty) {
          spans.add(3);
          tree.splice(0, 0, <double>[3]);
        }
        if (step % 10 == 0) check();
        final at = random.nextInt(spans.length);
        spans[at] = random.nextInt(80);
        tree.setValue(at, spans[at].toDouble());
      }
      check();
    },
  );
}
