/// Keeping an edge's label clear of what is drawn round it (#530).
///
/// A label sits halfway along its edge, and there it could cover what
/// another part put in the same place: a subgraph's title, crossed by an
/// edge into a composite state ("invia" over "Revisione"); a node; the cap
/// at another edge's end — a requirement's circled cross under «satisfies»;
/// another edge's label, two edges crossing at their middles; or a
/// subgraph's outline, where an edge into it crosses — a label is wholly
/// in a box or wholly out of it. Once the drawing is turned to its
/// direction, such a label slides along its own curve to the nearest point
/// where it covers none of them, the labels placed in the order the edges
/// were written. A label with nowhere free on its curve stays at the
/// middle.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';

/// The points along a curve a label may move to, nearest the middle first.
const List<double> _stops = [0.4, 0.6, 0.33, 0.67, 0.25, 0.75, 0.18, 0.82];

/// How far round an edge's end its cap may reach: the longest, a crow's
/// foot and its ring, is 22 from the point.
const double _capReach = 22;

/// [edges] with their labels moved along them off every title and
/// outline in [subgraphs], every node in [nodes], every other edge's caps
/// and end texts, and every label placed before them, each label's
/// background [padding] wider than its box.
List<LaidOutEdge> placeEdgeLabels(
  List<LaidOutEdge> edges,
  List<LaidOutSubgraph> subgraphs,
  List<Rect> nodes, {
  required double padding,
}) {
  final fixed = <Rect>[
    for (final sub in subgraphs) sub.titleRect.inflate(2),
    ...nodes,
    for (final edge in edges) ...[?edge.startLabelBox, ?edge.endLabelBox],
  ];
  List<Rect> caps(LaidOutEdge edge) => [
    if (edge.edge.start.isMarked)
      Rect.fromCircle(center: edge.start, radius: _capReach),
    if (edge.edge.end.isMarked)
      Rect.fromCircle(center: edge.end, radius: _capReach),
  ];
  final placed = <Rect>[];
  final result = <LaidOutEdge>[];
  for (var i = 0; i < edges.length; i++) {
    final edge = edges[i];
    final box = edge.labelBox;
    if (box == null) {
      result.add(edge);
      continue;
    }
    final taken = [
      ...fixed,
      ...placed,
      for (var j = 0; j < edges.length; j++)
        if (j != i) ...caps(edges[j]),
    ];
    // What is checked is what is drawn: the label's background reaches
    // [padding] past its box.
    bool free(Rect r) {
      final drawn = r.inflate(padding);
      return !taken.any((t) => t.overlaps(drawn)) &&
          !subgraphs.any((sub) => _straddles(drawn, sub.rect));
    }

    var chosen = box;
    if (!free(box)) {
      for (final t in _stops) {
        final moved = Rect.fromCenter(
          center: _at(edge, t),
          width: box.width,
          height: box.height,
        );
        if (free(moved)) {
          chosen = moved;
          break;
        }
      }
    }
    placed.add(chosen);
    result.add(
      chosen == box
          ? edge
          : LaidOutEdge(
              edge: edge.edge,
              start: edge.start,
              control1: edge.control1,
              control2: edge.control2,
              end: edge.end,
              label: edge.label,
              labelBox: chosen,
              startLabelBox: edge.startLabelBox,
              endLabelBox: edge.endLabelBox,
            ),
    );
  }
  return result;
}

/// Whether [label] lies across [box]'s outline: partly in, partly out.
bool _straddles(Rect label, Rect box) {
  if (!label.overlaps(box)) return false;
  final inside = box.inflate(0.01);
  return !(inside.contains(label.topLeft) &&
      inside.contains(label.bottomRight));
}

/// The point at [t] along [edge]'s cubic.
Offset _at(LaidOutEdge edge, double t) {
  final u = 1 - t;
  return edge.start * (u * u * u) +
      edge.control1 * (3 * u * u * t) +
      edge.control2 * (3 * u * t * t) +
      edge.end * (t * t * t);
}
