// The caret and the selection in source offsets, and the one thing that has to
// move them without a map: §8.6.0's atomic ranges, so a press crosses a hidden
// `**` instead of stopping inside a marker the reader cannot see.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/visible_text.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The hidden ranges of the first block of [document], as the renderer computes
/// them — the same list `live` mode's caret has to step over.
List<(int, int)> _hiddenRanges(String document) {
  final buffer = SourceBuffer.fromText(document);
  final scanner = BlockScanner(buffer);
  final parsed = BlockParser().parse(scanner.index.blocks.first, buffer);
  return hiddenRangesOf(parsed);
}

void main() {
  group('a selection in source offsets', () {
    test('normalizes whichever way it was dragged', () {
      const backwards = SelectionModel(anchor: 9, extent: 3);
      expect(backwards.start, 3);
      expect(backwards.end, 9);
      expect(backwards.caret, 3);
      expect(backwards.isCollapsed, isFalse);

      const caret = SelectionModel.at(4);
      expect(caret.isCollapsed, isTrue);
      expect(caret.start, caret.end);
      expect(const SelectionModel.all(12).start, 0);
      expect(const SelectionModel.all(12).end, 12);
    });

    test('clamps both ends into the document', () {
      const selection = SelectionModel(anchor: -4, extent: 40);
      expect(selection.clampTo(10).anchor, 0);
      expect(selection.clampTo(10).extent, 10);

      // A caret stays a caret, and a selection inside the document is left
      // alone.
      expect(const SelectionModel.at(40).clampTo(10).isCollapsed, isTrue);
      expect(const SelectionModel(anchor: 2, extent: 5).clampTo(10).extent, 5);
    });

    test('collapsing and extending keep the anchor where a writer expects', () {
      const selection = SelectionModel(anchor: 2, extent: 8);
      expect(selection.collapsedTo(5).isCollapsed, isTrue);
      expect(selection.collapsedTo(5).anchor, 5);

      // Extending moves the far end and leaves the anchor alone, so a selection
      // dragged past its own start shrinks from there rather than flipping.
      expect(selection.extendedTo(11).anchor, 2);
      expect(selection.extendedTo(11).extent, 11);
      expect(selection.extendedTo(1).start, 1);
      expect(selection.extendedTo(1).anchor, 2);
    });
  });

  group('atomic motion', () {
    // `**` at 5..7 and `**` at 11..13, as `hiddenRangesOf` reports them.
    const runs = <(int, int)>[(5, 7), (11, 13)];

    test('a press forward steps over the whole run', () {
      expect(SelectionModel.snap(from: 4, to: 5, runs: runs), 5);
      expect(SelectionModel.snap(from: 5, to: 6, runs: runs), 7);
      expect(SelectionModel.snap(from: 5, to: 7, runs: runs), 7);
    });

    test('a press backward steps over it the other way', () {
      expect(SelectionModel.snap(from: 8, to: 7, runs: runs), 7);
      expect(SelectionModel.snap(from: 8, to: 6, runs: runs), 5);
    });

    test('a destination outside every run is left alone', () {
      expect(SelectionModel.snap(from: 3, to: 4, runs: runs), 4);
      expect(SelectionModel.snap(from: 8, to: 10, runs: runs), 10);
      expect(SelectionModel.snap(from: 0, to: 100, runs: const []), 100);
    });

    test('a run edge is not inside the run', () {
      expect(SelectionModel.snap(from: 4, to: 5, runs: runs), 5);
      expect(SelectionModel.snap(from: 8, to: 7, runs: runs), 7);
      expect(SelectionModel.snap(from: 12, to: 13, runs: runs), 13);
    });

    test('with no direction to travel in, the nearer edge wins', () {
      // A tie — dead centre of a two-character marker — goes to the earlier
      // edge, so the caret lands before the marker rather than after it.
      expect(SelectionModel.snap(from: 6, to: 6, runs: runs), 5);
      expect(SelectionModel.snap(from: 12, to: 12, runs: runs), 11);
      // And an off-centre one goes to whichever is nearer.
      expect(SelectionModel.snap(from: 6, to: 7, runs: runs), 7);
    });

    test('the anchor stays while the caret crosses a marker', () {
      const selection = SelectionModel(anchor: 4, extent: 5);
      final moved = selection.snappedTo(to: 6, runs: runs);
      expect(moved.anchor, 4);
      expect(moved.extent, 7);
    });
  });

  group('the runs come from the renderer, not from a second rule', () {
    test('a hidden `**` is one press wide', () {
      // `a **bold** word`: the two markers are the only hidden characters, and
      // the words either side are ordinary offsets to be walked one by one.
      final runs = _hiddenRanges('a **bold** word');
      expect(SelectionModel.snap(from: 1, to: 2, runs: runs), 2);
      expect(SelectionModel.snap(from: 2, to: 3, runs: runs), 4);
      expect(SelectionModel.snap(from: 4, to: 5, runs: runs), 5);
      expect(SelectionModel.snap(from: 9, to: 9, runs: runs), 8);
    });

    test('a one-character marker has no inside to stop in', () {
      // `a `code` word`: both markers are single backticks, so no destination
      // falls strictly inside one and nothing needs stepping over — and the
      // code between them is text at its own offsets, which is what approach B
      // buys. Only a marker with an interior, like `**`, can trap a caret.
      final runs = _hiddenRanges('a `code` word');
      for (var to = 0; to <= 12; to++) {
        expect(SelectionModel.snap(from: to - 1, to: to, runs: runs), to);
        expect(SelectionModel.snap(from: to + 1, to: to, runs: runs), to);
      }
    });
  });
}
