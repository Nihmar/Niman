/// Edges that join a subgraph's box rather than a node (#530).
///
/// Mermaid lets an edge name a subgraph (`A --> S`, `S1 --> S2`): it
/// joins the box, not a node of it. The drawing routes such an edge to
/// the box's outline; the ranking reads it as joining every node the box
/// holds, so the box comes wholly after what leads to it and wholly
/// before what it leads to — subgraphs chained by their names stack.
library;

import 'package:niman/src/diagrams/flow_model.dart';

/// Every node the box of each subgraph of [chart] holds, by subgraph id:
/// its own and those of the subgraphs written inside it.
Map<String, Set<String>> flowBoxMembers(Flowchart chart) {
  final held = <String, Set<String>>{};
  // The chart lists a subgraph after those inside it.
  for (final subgraph in chart.subgraphs) {
    final own = (held[subgraph.id] ??= {})..addAll(subgraph.nodeIds);
    final parent = subgraph.parent;
    if (parent != null) (held[parent] ??= {}).addAll(own);
  }
  return held;
}

/// One pair of nodes an edge of a flowchart ties for the ranking.
typedef FlowRankedEdge = ({FlowEdge edge, String from, String to});

/// The edges of [chart] between nodes: an edge naming a subgraph stands
/// for one to or from each node its box holds ([held], from
/// [flowBoxMembers]). A node keeps its id when a subgraph shares it.
Iterable<FlowRankedEdge> flowRankedEdges(
  Flowchart chart,
  Map<String, Set<String>> held,
) sync* {
  final nodes = {for (final node in chart.nodes) node.id};
  Iterable<String> ends(String id) =>
      nodes.contains(id) ? [id] : held[id] ?? const [];
  for (final edge in chart.edges) {
    for (final from in ends(edge.from)) {
      for (final to in ends(edge.to)) {
        yield (edge: edge, from: from, to: to);
      }
    }
  }
}
