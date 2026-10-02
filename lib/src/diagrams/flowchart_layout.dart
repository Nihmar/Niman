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
import 'package:niman/src/diagrams/flow_layers.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_orientation.dart';
import 'package:niman/src/diagrams/flow_subgraph_boxes.dart';

/// The room kept round the whole drawing.
const double _margin = 12;

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
    final size = _nodeSize(node, labelLines, style);
    // The layout runs top-down and is turned at the end: a chart drawn
    // across lays its nodes out on their sides, so the turn stands them up.
    sizes[node.id] = across ? size.flipped : size;
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
  final rankTop = List<double>.filled(layers.length, 0);
  var cursor = 0.0;
  for (var r = 0; r < layers.length; r++) {
    rankTop[r] = cursor;
    cursor += rankMain[r] + style.rankGap;
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

  final edges = [
    for (final edge in chart.edges)
      routeFlowEdge(edge, rects, style, across: across),
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
    if (edge.labelBox != null) include(edge.labelBox!);
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
  return DiagramLayout(
    size: transformer.size,
    nodes: [
      for (final node in chart.nodes)
        LaidOutNode(node: node, rect: transformer.rect(rects[node.id]!)),
    ],
    edges: [for (final edge in edges) transformer.edge(edge)],
    subgraphs: [for (final sub in subgraphs) transformer.subgraph(sub)],
    lines: lines,
  );
}

/// The size of one node's box, text plus padding, widened for its shape.
Size _nodeSize(FlowNode node, List<String> lines, DiagramStyle style) {
  var text = 0.0;
  for (final line in lines) {
    text = math.max(text, DiagramMetrics.textWidth(line, style.fontSize));
  }
  var width = text + style.nodePadding.horizontal;
  var height =
      lines.length * style.fontSize * style.lineHeight +
      style.nodePadding.vertical;
  switch (node.shape) {
    case FlowNodeShape.circle:
      final diameter = math.max(width, height) * 1.3;
      width = diameter;
      height = diameter;
    case FlowNodeShape.diamond:
      width *= 1.7;
      height *= 1.9;
    case FlowNodeShape.hexagon:
      width *= 1.35;
    case FlowNodeShape.stadium:
      width += height * 0.4;
    case FlowNodeShape.subroutine:
      width += 12;
    case FlowNodeShape.database:
      height += 10;
    case FlowNodeShape.asymmetric:
    case FlowNodeShape.rect:
    case FlowNodeShape.round:
    case FlowNodeShape.parallelogram:
    case FlowNodeShape.parallelogramAlt:
    case FlowNodeShape.trapezoid:
    case FlowNodeShape.trapezoidAlt:
      break;
  }
  return Size(math.max(width, 34), math.max(height, 28));
}
