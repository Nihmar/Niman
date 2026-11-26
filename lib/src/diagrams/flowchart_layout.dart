/// Laying a flowchart out (#530): ranks, order, coordinates and curves.
///
/// The work is the compound layered layout's (`layered_layout.dart`): the
/// chart becomes its graph (`flow_layered_graph.dart`) — subgraphs are
/// clusters, a note tied to one node is one box with it — and what comes
/// back is read as the chart's own parts: node rectangles, subgraph boxes
/// and one curve for each edge. It runs in canonical space (ranks
/// downwards, cross axis to the right) and the result is turned to the
/// chart's direction at the end, so the four directions share one
/// implementation.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_edge_ports.dart';
import 'package:niman/src/diagrams/flow_edge_route.dart';
import 'package:niman/src/diagrams/flow_label_clearance.dart';
import 'package:niman/src/diagrams/flow_layered_graph.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_node_size.dart';
import 'package:niman/src/diagrams/flow_orientation.dart';
import 'package:niman/src/diagrams/flow_subgraph_boxes.dart';
import 'package:niman/src/diagrams/flow_subgraph_direction.dart';
import 'package:niman/src/diagrams/layered_layout.dart';

/// Lays [chart] out with [style].
///
/// An isolated subgraph that declares a direction of its own is laid out
/// apart ([FlowDirectionSplit]) and placed as one box in the rest.
DiagramLayout layoutFlowchart(Flowchart chart, DiagramStyle style) {
  final split = FlowDirectionSplit.of(
    chart,
    (apart) => layoutFlowchart(apart, style),
  );
  if (split == null) return _layOut(chart, style, const {});
  return split.merge(_layOut(split.outer, style, split.sizes));
}

/// Lays [chart] out in its own direction; [fixed] are the sizes, as drawn,
/// of the nodes whose size is not their label's.
DiagramLayout _layOut(
  Flowchart chart,
  DiagramStyle style,
  Map<String, Size> fixed,
) {
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
    final size = fixed[node.id] ?? flowNodeSize(node, labelLines, style);
    // The layout runs top-down and is turned at the end: a chart drawn
    // across lays its nodes out on their sides, so the turn stands them up.
    // A bar is the one laid out as it is: it lies across the flow, and the
    // turn is what puts it there.
    sizes[node.id] = across && node.shape != FlowNodeShape.bar
        ? size.flipped
        : size;
  }

  final flow = FlowLayeredGraph(chart, sizes, style);
  layOutLayered(flow.graph, flow.options);
  final rects = flow.nodeRects();
  final subgraphs = flowSubgraphBoxes(flow, style);

  // Where an edge's ends are: a node, or the box of a subgraph it names.
  final ends = <String, FlowEnd>{
    for (final box in subgraphs) box.subgraph.id: (rect: box.rect, box: true),
    for (final MapEntry(:key, :value) in rects.entries)
      key: (rect: value, box: false),
  };
  final ports = flowPorts(chart.edges, flow.routes, rects);
  final edges = [
    for (var i = 0; i < chart.edges.length; i++)
      routeFlowEdge(
        chart.edges[i],
        ends[chart.edges[i].from],
        ends[chart.edges[i].to],
        flow.routes[i],
        style,
        across: across,
        startX: ports.starts[i],
        endX: ports.ends[i],
      ),
  ];

  // The drawing's own bounds, then the direction's turn.
  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
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
    // node, or goes round a loop, is drawn whole.
    for (final point in edge.path) {
      include(Rect.fromCircle(center: point, radius: 0));
    }
  }
  minX -= flowLayoutMargin;
  minY -= flowLayoutMargin;
  maxX += flowLayoutMargin;
  maxY += flowLayoutMargin;

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
      padding: style.edgeLabelPadding.left,
    ),
    subgraphs: turned,
    lines: lines,
  );
}
