/// Keeping an edge's label off a subgraph's title (#530).
///
/// A label sits halfway along its edge, and an edge into a subgraph — into
/// a composite state, say — crosses the subgraph's title band right there:
/// the label was drawn over the title ("invia" over "Revisione"). Once the
/// drawing is turned to its direction, such a label slides along its own
/// curve to the nearest point where it covers no title.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';

/// The points along a curve a label may move to, nearest the middle first.
const List<double> _stops = [0.4, 0.6, 0.33, 0.67, 0.25, 0.75, 0.18, 0.82];

/// [edge], its label moved along it off every title in [subgraphs].
LaidOutEdge clearOfTitles(LaidOutEdge edge, List<LaidOutSubgraph> subgraphs) {
  final box = edge.labelBox;
  if (box == null || !_coversTitle(box, subgraphs)) return edge;
  for (final t in _stops) {
    final moved = Rect.fromCenter(
      center: _at(edge, t),
      width: box.width,
      height: box.height,
    );
    if (_coversTitle(moved, subgraphs)) continue;
    return LaidOutEdge(
      edge: edge.edge,
      start: edge.start,
      control1: edge.control1,
      control2: edge.control2,
      end: edge.end,
      label: edge.label,
      labelBox: moved,
      startLabelBox: edge.startLabelBox,
      endLabelBox: edge.endLabelBox,
    );
  }
  return edge;
}

bool _coversTitle(Rect box, List<LaidOutSubgraph> subgraphs) =>
    subgraphs.any((sub) => sub.titleRect.inflate(2).overlaps(box));

/// The point at [t] along [edge]'s cubic.
Offset _at(LaidOutEdge edge, double t) {
  final u = 1 - t;
  return edge.start * (u * u * u) +
      edge.control1 * (3 * u * u * t) +
      edge.control2 * (3 * u * t * t) +
      edge.end * (t * t * t);
}
