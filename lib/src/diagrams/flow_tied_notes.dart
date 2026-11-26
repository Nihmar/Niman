/// Notes tied to one node (#530): a note that sits beside the node it
/// annotates, as a sequence's note sits beside its lifeline.
library;

import 'dart:ui';

import 'package:niman/src/diagrams/flow_model.dart';

/// The notes tied to exactly one other node by an edge, and that node.
///
/// Such a note sits beside it: in its rank, right after it, the tie taking
/// no part in the ranking. A note drawn a rank below fell in whatever stood
/// there — the box of a composite state, for one. An edge between two notes
/// is no tie, and a note tied to two nodes is laid out as any node.
Map<String, String> flowTiedNotes(Flowchart chart) {
  final notes = {
    for (final node in chart.nodes)
      if (node.shape == FlowNodeShape.note) node.id,
  };
  final ties = <String, Set<String>>{};
  for (final edge in chart.edges) {
    final (note, other) = notes.contains(edge.from)
        ? (edge.from, edge.to)
        : (edge.to, edge.from);
    if (!notes.contains(note) || notes.contains(other)) continue;
    (ties[note] ??= {}).add(other);
  }
  return {
    for (final MapEntry(key: note, value: others) in ties.entries)
      if (others.length == 1) note: others.single,
  };
}

/// A node and the notes tied to it, laid out as one box: the node on the
/// left and each note right after it, a [gap] apart, all centred on the
/// rank. The layout places the whole; [split] gives each its own rectangle
/// back.
final class FlowTiedGroup {
  /// Groups [target] and [notes], by their [sizes] in canonical space.
  new(this.target, this.notes, Map<String, Size> sizes, this.gap)
    : _sizes = sizes;

  /// The node the notes are tied to.
  final String target;

  /// The notes, in the chart's order.
  final List<String> notes;

  /// The room between one and the next.
  final double gap;

  final Map<String, Size> _sizes;

  /// How wide the whole is.
  double get width {
    var sum = _sizes[target]!.width;
    for (final note in notes) {
      sum += gap + _sizes[note]!.width;
    }
    return sum;
  }

  /// How tall the whole is: the tallest of its parts.
  double get height {
    var tallest = _sizes[target]!.height;
    for (final note in notes) {
      tallest = tallest < _sizes[note]!.height ? _sizes[note]!.height : tallest;
    }
    return tallest;
  }

  /// The rectangle of each part once the whole is centred on [centre].
  Map<String, Rect> split(Offset centre) {
    final rects = <String, Rect>{};
    var left = centre.dx - width / 2;
    for (final id in [target, ...notes]) {
      final size = _sizes[id]!;
      rects[id] = Rect.fromLTWH(
        left,
        centre.dy - size.height / 2,
        size.width,
        size.height,
      );
      left += size.width + gap;
    }
    return rects;
  }
}
