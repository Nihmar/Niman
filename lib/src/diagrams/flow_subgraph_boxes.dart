/// The boxes drawn round a flowchart's subgraphs (#530).
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_layered_graph.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/layered_box.dart';

/// The box of each subgraph of [flow]'s chart that holds a node, once its
/// graph is laid out, outermost first so a drawing can paint them in order.
///
/// The layout keeps a subgraph's nodes together in a box that holds the
/// boxes of the subgraphs written inside it, title band and all, so nested
/// boxes nest and boxes side by side do not touch. The chart lists a
/// subgraph after those inside it, so painted last to first a child's box
/// lies over its parent's.
List<LaidOutSubgraph> flowSubgraphBoxes(
  FlowLayeredGraph flow,
  DiagramStyle style,
) => [
  for (final subgraph in flow.chart.subgraphs.reversed)
    if (flow.clusters[subgraph.id] case final key?)
      _laidOut(subgraph, flow.graph.cluster(key)!.box, style),
];

LaidOutSubgraph _laidOut(
  FlowSubgraph subgraph,
  LayeredBox box,
  DiagramStyle style,
) {
  final rect = Rect.fromLTRB(box.left, box.top, box.right, box.bottom);
  return LaidOutSubgraph(
    subgraph: subgraph,
    rect: rect,
    title: subgraph.title,
    titleRect: Rect.fromLTWH(
      rect.left + 8,
      rect.top + 4,
      DiagramMetrics.textWidth(subgraph.title, style.fontSize),
      style.fontSize * style.lineHeight,
    ),
  );
}
