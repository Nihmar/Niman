// The height map: the estimator behind the read view's sliver. What a layout
// asks it is "where does block 4 000 start", before anything has been laid out
// — and the answer has to move as measurements land, because the map is also
// where those measurements go.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';

/// A map over [count] paragraph blocks, each estimated at 10 pixels.
BlockHeightMap _map(int count) =>
    BlockHeightMap(count: count, estimate: (index) => 10);

void main() {
  test('offsets are the estimates until a frame measures one', () {
    final map = _map(4);
    expect(map.length, 4);
    expect(map.totalExtent, 40);
    expect(map.offsetOf(0), 0);
    expect(map.offsetOf(2), 20);
    expect(map.offsetOf(4), 40, reason: 'one past the end is the total');
    expect(map.measuredCount, 0);
  });

  test('a splice keeps the measurements of the blocks it does not touch', () {
    // An Enter adds a line: the heights a frame measured above and below it
    // are still true, and throwing them away moved everything on screen.
    final map = _map(4)
      ..measured(0, 30)
      ..measured(3, 50)
      ..splice(1, 1, 2, (index) => 7);
    expect(map.length, 5);
    expect(map.extentFor(0), 30, reason: 'measured, above the edit');
    expect(map.extentFor(1), 7, reason: 'new, estimated');
    expect(map.extentFor(2), 7);
    expect(map.extentFor(3), 10, reason: 'untouched, still estimated');
    expect(map.extentFor(4), 50, reason: 'measured, below the edit');
    expect(map.offsetOf(4), 30 + 7 + 7 + 10);
    expect(map.measuredCount, 2);
    expect(map.indexAt(43), 2);
    expect(map.indexAt(44), 3, reason: 'the boundary belongs to the next one');
    expect(map.indexAt(54), 4);
    // And a line removed takes its measurement with it.
    map.splice(0, 1, 0, (index) => 0);
    expect(map.length, 4);
    expect(map.measuredCount, 1);
    expect(map.offsetOf(0), 0);
    expect(map.totalExtent, 7 + 7 + 10 + 50);
  });

  test('indexAt finds the block an offset lands in', () {
    final map = _map(4);
    expect(map.indexAt(0), 0);
    expect(map.indexAt(9.9), 0);
    expect(map.indexAt(10), 1, reason: 'the boundary belongs to the next one');
    expect(map.indexAt(25), 2);
    expect(map.indexAt(39.9), 3);
    expect(map.indexAt(40), isNull, reason: 'past the end');
    expect(map.indexAt(-1), isNull);
  });

  test('a measurement moves everything after it', () {
    final map = _map(4)..measured(1, 100);
    expect(map.measuredCount, 1);
    expect(map.extentFor(1), 100);
    expect(map.totalExtent, 130);
    expect(map.offsetOf(0), 0);
    expect(map.offsetOf(1), 10);
    expect(map.offsetOf(2), 110, reason: 'the block after a taller one moved');
    expect(map.indexAt(105), 1);
    expect(map.indexAt(110), 2);
  });

  test('measuring the same block again replaces, not adds', () {
    final map = _map(4)
      ..measured(2, 50)
      ..measured(2, 30);
    expect(map.totalExtent, closeTo(60, 0.001), reason: '10 + 10 + 30 + 10');
    expect(map.extentFor(2), 30);
    expect(map.measuredCount, 1);
  });

  test('a measurement of nothing is ignored', () {
    // A block laid out at zero height is a delegate that drew nothing; writing
    // it would make the block unmeasurable rather than empty.
    final map = _map(2)
      ..measured(0, 0)
      ..measured(-1, 10)
      ..measured(9, 10);
    expect(map.totalExtent, 20);
    expect(map.measuredCount, 0);
  });

  test('a long note answers without walking it', () {
    // The point of the tree: a jump asks for an offset, and the answer must not
    // be a pass over 7 530 blocks per frame.
    final map = _map(20000);
    for (var at = 0; at < 20000; at += 7) {
      map.measured(at, 11);
    }
    expect(map.totalExtent, closeTo(20000 * 10 + 2858, 0.001));
    expect(map.offsetOf(19999), closeTo(19999 * 10 + 2857, 0.001));
    // The pair has to agree: asking for a block's offset and back finds it.
    for (final at in <int>[0, 1, 1234, 12345, 19999]) {
      expect(map.indexAt(map.offsetOf(at)), at);
    }
  });
}
