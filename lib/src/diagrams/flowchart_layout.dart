/// Laying a flowchart out (#530): ranks, order, coordinates and curves.
///
/// The algorithm is a small Sugiyama: nodes are ranked by longest path,
/// ordered within a rank by barycentre to cut crossings, then placed and
/// joined by cubic curves. It runs in canonical space (ranks downwards,
/// cross axis to the right) and the result is turned to the chart's
/// direction at the end, so the four directions share one implementation.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_edge_route.dart';
import 'package:niman/src/diagrams/flow_label_clearance.dart';
import 'package:niman/src/diagrams/flow_layers.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_node_size.dart';
import 'package:niman/src/diagrams/flow_orientation.dart';
import 'package:niman/src/diagrams/flow_subgraph_boxes.dart';

/// The room kept round the whole drawing.
const double _margin = 12;

/// The length of the longest cap an edge ends with (a crow's foot and its
/// ring), and a little air.
const double _capRoom = 26;

/// Lays [chart] out with [style].
DiagramLayout layoutFlowchart(Flowchart chart, DiagramStyle style) {
  if (chart.nodes.isEmpty) {
    return const DiagramLayout(
      size: Size.zero,
      nodes: [],
      edges: [],
      subgraphs: [],
      lines: {},
    );
  }
  final across = !chart.direction.isVertical;
  final sizes = <String, Size>{};
  final lines = <String, List<String>>{};
  for (final node in chart.nodes) {
    final labelLines = DiagramMetrics.lines(node.label);
    lines[node.id] = labelLines;
    final size = flowNodeSize(node, labelLines, style);
    // The layout runs top-down and is turned at the end: a chart drawn
    // across lays its nodes out on their sides, so the turn stands them up.
    // A bar is the one laid out as it is: it lies across the flow, and the
    // turn is what puts it there.
    sizes[node.id] = across && node.shape != FlowNodeShape.bar
        ? size.flipped
        : size;
  }

  final layers = flowLayers(chart);

  // Main-axis (y) positions, one band per rank.
  final rankMain = List<double>.filled(layers.length, 0);
  for (var r = 0; r < layers.length; r++) {
    var tallest = 0.0;
    for (final id in layers[r]) {
      tallest = math.max(tallest, sizes[id]!.height);
    }
    rankMain[r] = tallest;
  }
  final gaps = _rankGaps(chart, layers, style, across: across);
  final rankTop = List<double>.filled(layers.length, 0);
  var cursor = 0.0;
  for (var r = 0; r < layers.length; r++) {
    rankTop[r] = cursor;
    cursor += rankMain[r] + gaps[r];
  }

  // Cross-axis (x) positions: each rank centred and packed.
  final rects = <String, Rect>{};
  for (var r = 0; r < layers.length; r++) {
    final ids = layers[r];
    var width = 0.0;
    for (final id in ids) {
      width += sizes[id]!.width;
    }
    width += style.nodeGap * (ids.length - 1);
    var x = -width / 2;
    final centreY = rankTop[r] + rankMain[r] / 2;
    for (final id in ids) {
      final size = sizes[id]!;
      rects[id] = Rect.fromLTWH(
        x,
        centreY - size.height / 2,
        size.width,
        size.height,
      );
      x += size.width + style.nodeGap;
    }
  }

  final rankOf = <String, int>{
    for (var r = 0; r < layers.length; r++)
      for (final id in layers[r]) id: r,
  };
  // The nodes of the ranks an edge passes, which it bends round.
  Iterable<Rect> passing(FlowEdge edge) {
    final from = rankOf[edge.from];
    final to = rankOf[edge.to];
    if (from == null || to == null || from == to) return const [];
    final (first, last) = to > from ? (from + 1, to - 1) : (to, from);
    return [
      for (var r = first; r <= last; r++)
        for (final id in layers[r]) rects[id]!,
    ];
  }

  // A first routing says which way each edge leaves and arrives — round a
  // node in its way, it comes from the side it bent to — and so where on
  // the shared side it should be put.
  final draft = [
    for (final edge in chart.edges)
      routeFlowEdge(edge, rects, style, across: across, passing: passing(edge)),
  ];
  final ports = _ports(chart.edges, rankOf, rects, draft);
  final edges = [
    for (var i = 0; i < chart.edges.length; i++)
      routeFlowEdge(
        chart.edges[i],
        rects,
        style,
        across: across,
        passing: passing(chart.edges[i]),
        startX: ports.starts[i],
        endX: ports.ends[i],
      ),
  ];
  final subgraphs = flowSubgraphBoxes(chart, rects, style);

  // The drawing's own bounds, then the direction's turn.
  var minX = 0.0;
  var minY = 0.0;
  var maxX = 0.0;
  var maxY = 0.0;
  void include(Rect rect) {
    minX = math.min(minX, rect.left);
    minY = math.min(minY, rect.top);
    maxX = math.max(maxX, rect.right);
    maxY = math.max(maxY, rect.bottom);
  }

  rects.values.forEach(include);
  for (final sub in subgraphs) {
    include(sub.rect);
  }
  for (final edge in edges) {
    for (final box in [edge.labelBox, edge.startLabelBox, edge.endLabelBox]) {
      if (box != null) include(box);
    }
    // A curve stays inside its control points: an edge that bends round a
    // node, or a cycle's way back, is drawn whole.
    for (final point in [edge.control1, edge.control2]) {
      include(Rect.fromCircle(center: point, radius: 0));
    }
  }
  minX -= _margin;
  minY -= _margin;
  maxX += _margin;
  maxY += _margin;

  final transformer = FlowOrientation(
    direction: chart.direction,
    minX: minX,
    minY: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
  final turned = [for (final sub in subgraphs) transformer.subgraph(sub)];
  final nodes = [
    for (final node in chart.nodes)
      LaidOutNode(node: node, rect: transformer.rect(rects[node.id]!)),
  ];
  return DiagramLayout(
    size: transformer.size,
    nodes: nodes,
    edges: placeEdgeLabels(
      [for (final edge in edges) transformer.edge(edge)],
      turned,
      [for (final node in nodes) node.rect],
    ),
    subgraphs: turned,
    lines: lines,
  );
}

/// The gap below each rank: the style's, or more where an edge to the next
/// rank carries a label, end texts or caps that need the room — a label
/// on a short edge sat on its caps and on the texts at its ends.
List<double> _rankGaps(
  Flowchart chart,
  List<List<String>> layers,
  DiagramStyle style, {
  required bool across,
}) {
  final rank = <String, int>{
    for (var r = 0; r < layers.length; r++)
      for (final id in layers[r]) id: r,
  };
  final line = style.fontSize * style.lineHeight;
  // How far a text reaches along the edge: its height, or its width once
  // the drawing is turned across.
  double reach(String? text) {
    if (text == null || text.isEmpty) return 0;
    return across ? DiagramMetrics.textWidth(text, style.fontSize) : line;
  }

  // What an end of an edge takes along it: its cap, or the text beside it
  // and the gap the router leaves before it (`_endBox`).
  double end(FlowEdgeEnd cap, String? text) {
    final room = text == null || text.isEmpty
        ? 0.0
        : reach(text) + endTextGap + 4;
    return math.max(cap.isMarked ? _capRoom : 0, room);
  }

  final gaps = List<double>.filled(layers.length, style.rankGap);
  for (final edge in chart.edges) {
    final r = rank[edge.from];
    if (r == null || rank[edge.to] != r + 1) continue;
    final label = reach(edge.label);
    final ends = math.max(
      end(edge.start, edge.startLabel),
      end(edge.end, edge.endLabel),
    );
    // The label sits halfway: clear of the larger end on both sides.
    final need = label == 0
        ? end(edge.start, edge.startLabel) + end(edge.end, edge.endLabel)
        : 2 * ends + label + style.edgeLabelPadding.vertical + 4;
    gaps[r] = math.max(gaps[r], need);
  }
  return gaps;
}

/// Where each downward edge leaves its node's bottom and reaches the other
/// node's top, by edge index: the edges sharing a side spread along its
/// middle three fifths, each where it comes from or goes to — the edge
/// heading furthest left leaving from the leftmost point — so neither
/// their lines nor the marks at their ends lie on one another. Which way
/// an edge heads is read off its [draft] routing. A side with one edge
/// keeps its middle (null).
({Map<int, double> starts, Map<int, double> ends}) _ports(
  List<FlowEdge> edges,
  Map<String, int> rankOf,
  Map<String, Rect> rects,
  List<LaidOutEdge> draft,
) {
  final leaving = <String, List<int>>{};
  final reaching = <String, List<int>>{};
  for (var i = 0; i < edges.length; i++) {
    final edge = edges[i];
    final from = rankOf[edge.from];
    final to = rankOf[edge.to];
    if (from == null || to == null || to <= from) continue;
    (leaving[edge.from] ??= []).add(i);
    (reaching[edge.to] ??= []).add(i);
  }
  // Where an edge heads from its start, and comes from at its end: its
  // bend when it goes round a node, its other end when it runs straight.
  double heading(int i) {
    final edge = draft[i];
    return edge.control1.dx != edge.start.dx ? edge.control1.dx : edge.end.dx;
  }

  double approach(int i) {
    final edge = draft[i];
    return edge.control2.dx != edge.end.dx ? edge.control2.dx : edge.start.dx;
  }

  Map<int, double> spread(
    Map<String, List<int>> sides,
    double Function(int i) towards,
  ) {
    final ports = <int, double>{};
    for (final MapEntry(key: id, value: indices) in sides.entries) {
      if (indices.length < 2) continue;
      final rect = rects[id]!;
      indices.sort((a, b) => towards(a).compareTo(towards(b)));
      final span = rect.width * 0.6;
      for (var k = 0; k < indices.length; k++) {
        ports[indices[k]] =
            rect.center.dx - span / 2 + span * k / (indices.length - 1);
      }
    }
    return ports;
  }

  return (starts: spread(leaving, heading), ends: spread(reaching, approach));
}
