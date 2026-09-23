// The folded record of a block list's splices: replayed over the list as it
// was, it has to give the list as it is — every block it keeps being one the
// old list had, in order, which is what lets the read pane keep its heights.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block_changes.dart';

void main() {
  test('replayed over the old list, the stretches give the new one', () {
    final random = Random(1);
    var next = 0;
    for (var round = 0; round < 300; round++) {
      final old = [for (var at = 0; at < 200; at++) next++];
      final now = List<int>.of(old);
      final changes = BlockChanges();
      final splices = 1 + random.nextInt(round.isEven ? 4 : 40);
      for (var splice = 0; splice < splices; splice++) {
        // Mostly where the last one was, as a writer types; now and then
        // somewhere else in the note.
        final index = random.nextInt(now.length + 1);
        final removed = min(now.length - index, random.nextInt(4));
        final inserted = random.nextInt(4);
        now.replaceRange(index, index + removed, [
          for (var at = 0; at < inserted; at++) next++,
        ]);
        changes.record(index, removed, inserted);
      }
      final stretches = changes.stretches!;
      final replayed = List<int>.of(old);
      var previousEnd = 0;
      for (final stretch in stretches) {
        expect(stretch.start, greaterThanOrEqualTo(previousEnd));
        replayed.replaceRange(
          stretch.start,
          stretch.start + stretch.removed,
          now.sublist(stretch.start, stretch.start + stretch.inserted),
        );
        previousEnd = stretch.start + stretch.inserted;
      }
      expect(replayed, now, reason: 'round $round: $stretches');
    }
  });

  test('edits in one place stay one stretch', () {
    final changes = BlockChanges();
    // Typing in a paragraph, then an Enter in it, then a line joined back.
    for (var key = 0; key < 50; key++) {
      changes.record(10, 1, 1);
    }
    changes
      ..record(10, 1, 2)
      ..record(10, 2, 1);
    expect(changes.stretches, [(start: 10, removed: 1, inserted: 1)]);
  });

  test('edits all over the note are not worth replaying', () {
    final changes = BlockChanges();
    for (var at = 0; at <= BlockChanges.limit; at++) {
      changes.record(at * 10, 1, 1);
    }
    expect(changes.stretches, isNull);
  });
}
