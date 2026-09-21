/// The caret and the selection, in **source offsets**
/// (`docs/dev/unified-surface.md` §8.7.2).
///
/// One selection for the whole document, whichever blocks it spans. Source
/// offsets are the point of approach B (§8.6.0): the rendered text *is* the
/// source text there — a hidden marker is a style, not a removal — so an offset
/// means the same thing to the buffer, to the IME, to the clipboard, to the
/// parser and to the renderer, and a selection crossing three blocks is just a
/// wider range.
///
/// The type stays Dart-only, like the rest of the engine: the widget layer
/// adapts it to Flutter's `TextSelection` at the edge.
library;

import 'package:meta/meta.dart';

/// A caret or a selection, in source offsets.
@immutable
final class SelectionModel {
  /// A selection from [anchor] to [extent].
  const new({required this.anchor, required this.extent});

  /// The whole of a document of [length] characters.
  const new all(int length) : anchor = 0, extent = length;

  /// A caret at [offset], with nothing selected.
  const new at(int offset) : anchor = offset, extent = offset;

  /// Where the selection was anchored.
  ///
  /// A drag or a shift-arrow moves [extent] and leaves this alone, which is
  /// what makes a selection shrink again from the end it was extended from
  /// rather than jumping to the other side.
  final int anchor;

  /// The moving end, and with it the caret's position.
  final int extent;

  /// Whether nothing is selected.
  bool get isCollapsed => anchor == extent;

  /// The smaller of the two ends.
  int get start => anchor < extent ? anchor : extent;

  /// The larger of the two ends.
  int get end => anchor < extent ? extent : anchor;

  /// The caret: where an edit lands.
  int get caret => extent;

  /// Both ends pulled inside a document of [length] characters.
  ///
  /// A caret stays a caret: the two ends are clamped one by one rather than the
  /// range being reordered.
  SelectionModel clampTo(int length) => SelectionModel(
    anchor: _fit(anchor, length),
    extent: _fit(extent, length),
  );

  /// The caret at [offset], with the selection dropped.
  SelectionModel collapsedTo(int offset) => SelectionModel.at(offset);

  /// The moving end at [offset], with the anchor kept.
  SelectionModel extendedTo(int offset) =>
      SelectionModel(anchor: anchor, extent: offset);

  /// [snap] applied to the moving end, with the anchor kept.
  SelectionModel snappedTo({required int to, required List<(int, int)> runs}) =>
      SelectionModel(
        anchor: anchor,
        extent: snap(from: extent, to: to, runs: runs),
      );

  /// Where a caret moving from [from] to [to] really lands, given the [runs] it
  /// has to step over rather than stop inside.
  ///
  /// §8.6.0's atomic ranges: a destination inside a hidden run snaps past it in
  /// the direction of travel, so one arrow press crosses `**` instead of
  /// spending two presses inside a marker the reader cannot see. A destination
  /// that is not inside a run — including one exactly on a run's edge — is
  /// returned unchanged, and with no direction to travel in the nearer edge
  /// wins, a tie going to the earlier one.
  ///
  /// [runs] are half-open `(start, end)` source ranges, which is the shape
  /// `hiddenRangesOf` reports a block's markers in.
  static int snap({
    required int from,
    required int to,
    required List<(int, int)> runs,
  }) {
    for (final (start, end) in runs) {
      if (to <= start || to >= end) continue;
      if (to > from) return end;
      if (to < from) return start;
      return to - start <= end - to ? start : end;
    }
    return to;
  }

  static int _fit(int offset, int length) => offset < 0
      ? 0
      : offset > length
      ? length
      : offset;

  @override
  bool operator ==(Object other) =>
      other is SelectionModel &&
      other.anchor == anchor &&
      other.extent == extent;

  @override
  int get hashCode => Object.hash(anchor, extent);

  @override
  String toString() =>
      isCollapsed ? 'caret@$anchor' : '$start..$end (anchor $anchor)';
}
