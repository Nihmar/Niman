/// A subgraph's own direction (#530).
///
/// Mermaid honours the `direction` a subgraph declares only when nothing
/// crosses its border: then it is laid out on its own, as a chart of its
/// members with that direction, and placed in the chart as one box. A
/// subgraph with an edge to or from the outside is laid out with the rest
/// and its direction is ignored, and one that declares none keeps its
/// parent's.
///
/// [FlowDirectionSplit] cuts such subgraphs out of a chart: the chart it
/// leaves holds one placeholder node of the size of each one's own layout,
/// inside the subgraph, so the box, the padding and the title come from the
/// ordinary layout. [FlowDirectionSplit.merge] then puts the own layouts
/// into the placeholders' places.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_tied_notes.dart';

/// The room [layoutFlowchart](flowchart_layout.dart) keeps round a whole
/// drawing: what an own layout's size holds beyond its content.
const double flowLayoutMargin = 12;

/// The part of a chart laid out apart, and the chart left.
final class FlowDirectionSplit {
  new _(this._chart, this.outer, this.sizes, this._parts);

  /// Cuts the isolated subgraphs of [chart] that declare a direction other
  /// than the one they are laid out in out of it, laying each out with
  /// [layOut]; null if there are none.
  ///
  /// A subgraph is laid out in its parent's direction, and a parent that is
  /// itself cut out has its children cut out of its own layout in turn.
  static FlowDirectionSplit? of(
    Flowchart chart,
    DiagramLayout Function(Flowchart chart) layOut,
  ) {
    if (chart.subgraphs.every((s) => s.direction == null)) return null;
    final nodeIds = {for (final node in chart.nodes) node.id};
    final parents = {for (final sub in chart.subgraphs) sub.id: sub.parent};
    final tied = flowTiedNotes(chart);
    final held = _held(chart, tied);
    final nested = <String, Set<String>>{};
    for (final sub in chart.subgraphs) {
      for (var up = sub.parent; up != null; up = parents[up]) {
        (nested[up] ??= {}).add(sub.id);
      }
    }

    final cut = <_Part>[];
    final inside = <String>{};
    // Outermost first: the chart lists a subgraph after those inside it.
    for (final sub in chart.subgraphs.reversed) {
      final direction = sub.direction;
      if (direction == null || direction == chart.direction) continue;
      if (inside.contains(sub.id)) continue;
      final members = held[sub.id]!;
      if (members.isEmpty) continue;
      final within = {...members, ...?nested[sub.id]};
      if (!_isolated(chart, sub.id, within, nodeIds)) continue;
      final subs = [
        for (final s in chart.subgraphs)
          if (nested[sub.id]?.contains(s.id) ?? false) s,
      ];
      final edges = <int>[
        for (var i = 0; i < chart.edges.length; i++)
          if (within.contains(chart.edges[i].from)) i,
      ];
      final part = _Part(
        sub,
        members,
        edges,
        subs,
        layOut(
          Flowchart(
            direction: direction,
            nodes: [
              for (final node in chart.nodes)
                if (members.contains(node.id)) node,
            ],
            edges: [for (final i in edges) chart.edges[i]],
            subgraphs: [
              for (final s in subs)
                FlowSubgraph(
                  id: s.id,
                  title: s.title,
                  nodeIds: s.nodeIds,
                  direction: s.direction,
                  parent: s.parent == sub.id ? null : s.parent,
                  style: s.style,
                ),
            ],
          ),
        ),
      );
      cut.add(part);
      inside
        ..add(sub.id)
        ..addAll(nested[sub.id] ?? const {});
    }
    if (cut.isEmpty) return null;

    final removed = {for (final part in cut) ...part.members};
    final holder = {for (final part in cut) part.sub.id: part};
    final nodes = <FlowNode>[];
    final placed = <String>{};
    for (final node in chart.nodes) {
      if (!removed.contains(node.id)) {
        nodes.add(node);
        continue;
      }
      final part = cut.firstWhere((p) => p.members.contains(node.id));
      if (placed.add(part.sub.id)) {
        nodes.add(
          FlowNode(id: part.placeholder, label: '', shape: FlowNodeShape.rect),
        );
      }
    }
    final size = {
      for (final part in cut)
        part.placeholder: Size(
          part.layout.size.width - 2 * flowLayoutMargin,
          part.layout.size.height - 2 * flowLayoutMargin,
        ),
    };
    final cutEdges = {for (final part in cut) ...part.edges};
    final outer = Flowchart(
      direction: chart.direction,
      nodes: nodes,
      edges: [
        for (var i = 0; i < chart.edges.length; i++)
          if (!cutEdges.contains(i)) chart.edges[i],
      ],
      subgraphs: [
        for (final sub in chart.subgraphs)
          if (!inside.contains(sub.id) || holder.containsKey(sub.id))
            FlowSubgraph(
              id: sub.id,
              title: sub.title,
              nodeIds: [
                if (holder[sub.id] != null)
                  holder[sub.id]!.placeholder
                else
                  for (final id in sub.nodeIds)
                    if (!removed.contains(id)) id,
              ],
              direction: sub.direction,
              parent: sub.parent,
              style: sub.style,
            ),
      ],
    );
    return FlowDirectionSplit._(chart, outer, size, cut);
  }

  final Flowchart _chart;

  /// The chart left once the subgraphs are cut out, a placeholder node in
  /// each.
  final Flowchart outer;

  /// The size of each placeholder, by id, as it is drawn.
  final Map<String, Size> sizes;

  final List<_Part> _parts;

  /// The whole drawing: [layout] of [outer] with every part laid out apart
  /// put into its placeholder's place, in the chart's own order.
  DiagramLayout merge(DiagramLayout layout) {
    final nodes = <String, LaidOutNode>{};
    final edges = List<LaidOutEdge?>.filled(_chart.edges.length, null);
    final lines = <String, List<String>>{};
    final subgraphs = <LaidOutSubgraph>[];
    final original = {for (final sub in _chart.subgraphs) sub.id: sub};
    final byHolder = {for (final part in _parts) part.sub.id: part};
    final byPlaceholder = {for (final part in _parts) part.placeholder: part};

    // Where each part's own drawing goes: its placeholder's top left, less
    // the margin round that drawing.
    final shifts = <String, Offset>{};
    for (final node in layout.nodes) {
      final part = byPlaceholder[node.node.id];
      if (part != null) {
        shifts[part.sub.id] =
            node.rect.topLeft -
            const Offset(flowLayoutMargin, flowLayoutMargin);
      } else {
        nodes[node.node.id] = node;
      }
    }
    layout.lines.forEach((id, text) {
      if (!byPlaceholder.containsKey(id)) lines[id] = text;
    });
    final apart = {for (final part in _parts) ...part.edges};
    final outerEdges = [
      for (var i = 0; i < _chart.edges.length; i++)
        if (!apart.contains(i)) i,
    ];
    for (var k = 0; k < outerEdges.length; k++) {
      edges[outerEdges[k]] = layout.edges[k];
    }
    for (final sub in layout.subgraphs) {
      subgraphs.add(
        LaidOutSubgraph(
          subgraph: original[sub.subgraph.id]!,
          rect: sub.rect,
          titleRect: sub.titleRect,
          title: sub.title,
        ),
      );
      final part = byHolder[sub.subgraph.id];
      if (part == null) continue;
      final shift = shifts[part.sub.id]!;
      for (final node in part.layout.nodes) {
        nodes[node.node.id] = LaidOutNode(
          node: node.node,
          rect: node.rect.shift(shift),
        );
      }
      for (var k = 0; k < part.edges.length; k++) {
        edges[part.edges[k]] = part.layout.edges[k].shifted(shift);
      }
      part.layout.lines.forEach((id, text) => lines[id] = text);
      for (final inner in part.layout.subgraphs) {
        subgraphs.add(
          LaidOutSubgraph(
            subgraph: original[inner.subgraph.id]!,
            rect: inner.rect.shift(shift),
            titleRect: inner.titleRect.shift(shift),
            title: inner.title,
          ),
        );
      }
    }
    return DiagramLayout(
      size: layout.size,
      nodes: [for (final node in _chart.nodes) nodes[node.id]!],
      edges: [for (final edge in edges) edge!],
      subgraphs: subgraphs,
      lines: lines,
    );
  }

  /// The ids of the nodes each subgraph holds, those of the subgraphs
  /// written inside it included, and a note tied to one of them.
  static Map<String, Set<String>> _held(
    Flowchart chart,
    Map<String, String> tied,
  ) {
    final held = <String, Set<String>>{};
    // The chart lists a subgraph after those inside it.
    for (final sub in chart.subgraphs) {
      final own = (held[sub.id] ??= {})
        ..addAll([
          for (final id in sub.nodeIds)
            if (!tied.containsKey(id)) id,
        ]);
      final parent = sub.parent;
      if (parent != null) (held[parent] ??= {}).addAll(own);
    }
    for (final MapEntry(key: note, value: target) in tied.entries) {
      for (final members in held.values) {
        if (members.contains(target)) members.add(note);
      }
    }
    return held;
  }

  /// Whether no edge crosses the border of the subgraph [id], whose
  /// members and nested subgraphs are [within]: none has one end among
  /// them and the other outside, and none names the subgraph itself.
  static bool _isolated(
    Flowchart chart,
    String id,
    Set<String> within,
    Set<String> nodeIds,
  ) {
    bool names(String end) => end == id && !nodeIds.contains(end);
    for (final edge in chart.edges) {
      if (names(edge.from) || names(edge.to)) return false;
      if (within.contains(edge.from) != within.contains(edge.to)) return false;
    }
    return true;
  }
}

/// A subgraph laid out apart.
final class _Part {
  new(this.sub, this.members, this.edges, this.nested, this.layout);

  /// The subgraph.
  final FlowSubgraph sub;

  /// The ids of the nodes it holds.
  final Set<String> members;

  /// The indices in the whole chart of the edges inside it, in order.
  final List<int> edges;

  /// The subgraphs inside it, any depth.
  final List<FlowSubgraph> nested;

  /// Its own layout.
  final DiagramLayout layout;

  /// The id of the node that stands for it in the chart left.
  String get placeholder => '\u0002${sub.id}';
}
