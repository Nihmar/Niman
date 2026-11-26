/// A flowchart as the compound layered layout's graph (#530).
///
/// Nodes are boxes of their sizes in canonical space (a chart drawn across
/// has them on their sides), subgraphs are clusters whose padding holds the
/// title band on the side the turn puts at the top, and edges carry the
/// room their labels, caps and end texts need. A note tied to one node
/// ([flowTiedNotes]) is laid out as one box with it.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_edge_route.dart' show endTextGap;
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_tied_notes.dart';
import 'package:niman/src/diagrams/layered_edge.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_options.dart';

/// The length of the longest cap an edge ends with (a crow's foot and its
/// ring), and a little air.
const double _capRoom = 26;

/// The graph the layout runs on, and how to read its result back as the
/// chart's own parts.
final class FlowLayeredGraph {
  /// Builds the graph of [chart], its nodes' canonical sizes by id.
  new(this.chart, this._sizes, this.style) {
    _addClusters();
    _addNodes();
    _addEdges();
  }

  /// The chart.
  final Flowchart chart;

  /// The style it is laid out in.
  final DiagramStyle style;

  final Map<String, Size> _sizes;

  /// The graph to lay out.
  final LayeredGraph graph = LayeredGraph();

  /// The notes tied to a node, and that node.
  late final Map<String, String> tied = flowTiedNotes(chart);

  /// Each node that has notes tied to it, with them.
  final Map<String, FlowTiedGroup> groups = {};

  /// The graph's id for each subgraph of the chart that holds a node: a
  /// subgraph that holds none has no box and no end for an edge.
  final Map<String, String> clusters = {};

  /// The layout's edge for each edge of the chart, by index; null where the
  /// chart's edge is not the layout's to route: a self loop, a tie between
  /// a note and its node, and an edge to a subgraph without a box.
  final List<LayeredEdge?> routes = [];

  /// How the layout spaces things: the chart's gaps, and half the node gap
  /// beside the points an edge passes through, so edges do not push the
  /// nodes apart.
  LayeredOptions get options => LayeredOptions(
    rankGap: style.rankGap,
    nodeGap: style.nodeGap,
    edgeGap: style.nodeGap / 2,
  );

  /// Whether the drawing is turned across: its canonical x then is the
  /// chart's top to bottom.
  bool get across => !chart.direction.isVertical;

  /// Where each node of the chart is, once the graph is laid out.
  Map<String, Rect> nodeRects() {
    final rects = <String, Rect>{};
    for (final node in chart.nodes) {
      if (tied.containsKey(node.id)) continue;
      final placed = graph.node(node.id)!;
      final centre = Offset(placed.x, placed.y);
      final group = groups[node.id];
      if (group == null) {
        final size = _sizes[node.id]!;
        rects[node.id] = Rect.fromCenter(
          center: centre,
          width: size.width,
          height: size.height,
        );
      } else {
        rects.addAll(group.split(centre));
      }
    }
    return rects;
  }

  /// The graph's id for the subgraph [id]: one no node's id can be.
  static String clusterKey(String id) => '\u0001$id';

  void _addClusters() {
    final holding = _holdingSubgraphs();
    final children = <String?, List<FlowSubgraph>>{};
    for (final sub in chart.subgraphs) {
      if (!holding.contains(sub.id)) continue;
      final parent = sub.parent != sub.id && holding.contains(sub.parent)
          ? sub.parent
          : null;
      (children[parent] ??= []).add(sub);
    }
    final pad = style.subgraphPadding;
    final band = style.fontSize * style.lineHeight + 8;
    // The title's band is on the side the turn to the chart's direction
    // puts at the top: the canonical top, but the bottom for a chart drawn
    // up and the left for one drawn across.
    final top = chart.direction == FlowDirection.topDown ? band : 0;
    final bottom = chart.direction == FlowDirection.bottomUp ? band : 0;
    final left = across ? band : 0;
    // A cluster comes before what is in it, and a parent before its
    // children.
    void add(FlowSubgraph sub, String? parent) {
      if (clusters.containsKey(sub.id)) return;
      final key = clusterKey(sub.id);
      graph.addCluster(
        key,
        parent: parent,
        padTop: pad + top,
        padBottom: pad + bottom,
        padLeft: pad + left,
        padRight: pad,
      );
      clusters[sub.id] = key;
      for (final child in children[sub.id] ?? const <FlowSubgraph>[]) {
        add(child, key);
      }
    }

    for (final sub in children[null] ?? const <FlowSubgraph>[]) {
      add(sub, null);
    }
  }

  /// The ids of the subgraphs that hold a node, or hold one that does. The
  /// chart lists a subgraph after those written inside it.
  Set<String> _holdingSubgraphs() {
    final nodes = {for (final node in chart.nodes) node.id};
    final holding = <String>{};
    for (final sub in chart.subgraphs) {
      if (sub.nodeIds.any(nodes.contains) || holding.contains(sub.id)) {
        holding.add(sub.id);
        final parent = sub.parent;
        if (parent != null) holding.add(parent);
      }
    }
    return holding;
  }

  /// The subgraph each node is in: the first the chart lists that holds it,
  /// which is the innermost.
  Map<String, String> _homes() {
    final home = <String, String>{};
    for (final sub in chart.subgraphs) {
      final key = clusters[sub.id];
      if (key == null) continue;
      for (final id in sub.nodeIds) {
        home.putIfAbsent(id, () => key);
      }
    }
    return home;
  }

  void _addNodes() {
    final home = _homes();
    for (final MapEntry(key: note, value: target) in tied.entries) {
      (groups[target] ??= FlowTiedGroup(
        target,
        [],
        _sizes,
        style.nodeGap,
      )).notes.add(note);
    }
    for (final node in chart.nodes) {
      if (tied.containsKey(node.id)) continue;
      final group = groups[node.id];
      final size = group == null
          ? _sizes[node.id]!
          : Size(group.width, group.height);
      graph.addNode(
        node.id,
        width: size.width,
        height: size.height,
        parent: home[node.id],
      );
    }
  }

  void _addEdges() {
    final nodes = {for (final node in chart.nodes) node.id};
    final line = style.fontSize * style.lineHeight;
    // How far a text reaches along the edge: its height, or its width once
    // the drawing is turned across.
    double reach(String? text) {
      if (text == null || text.isEmpty) return 0;
      return across ? DiagramMetrics.textWidth(text, style.fontSize) : line;
    }

    // What an end of an edge takes along it: its cap, or the text beside it
    // and the gap the router leaves before it.
    double room(FlowEdgeEnd cap, String? text) {
      final beside = text == null || text.isEmpty
          ? 0.0
          : reach(text) + endTextGap + 4;
      return math.max(cap.isMarked ? _capRoom : 0, beside);
    }

    // The graph's end for an id of the chart: a node (a tied note is its
    // node's box), or the box of a subgraph.
    String? endOf(String id) {
      if (nodes.contains(id)) return tied[id] ?? id;
      return clusters[id];
    }

    for (var i = 0; i < chart.edges.length; i++) {
      final edge = chart.edges[i];
      final from = endOf(edge.from);
      final to = endOf(edge.to);
      // A self loop and a tie are drawn beside their node: nothing to rank.
      if (from == null || to == null || from == to) {
        routes.add(null);
        continue;
      }
      final label = edge.label == null || edge.label!.isEmpty
          ? null
          : edge.label;
      final size = label == null
          ? Size.zero
          : Size(
              DiagramMetrics.textWidth(label, style.fontSize) +
                  style.edgeLabelPadding.horizontal,
              line + style.edgeLabelPadding.vertical,
            );
      routes.add(
        graph.addEdge(
          from,
          to,
          // Laid out across, the label's box is turned with the drawing.
          labelWidth: across ? size.height : size.width,
          labelHeight: across ? size.width : size.height,
          tailRoom: room(edge.start, edge.startLabel),
          headRoom: room(edge.end, edge.endLabel),
          source: i,
        ),
      );
    }
  }
}
