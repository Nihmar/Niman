/// Keeping a subgraph's box to its own nodes (#530).
///
/// A rank is packed node after node, and a subgraph's box is drawn round
/// its nodes in every rank they sit in, so a node that is not in the
/// subgraph but shares a rank with it could fall inside the box — an
/// external system drawn within the enterprise boundary it is outside.
/// Two steps keep it out. In every rank the members of a subgraph sit side
/// by side, at every depth of nesting, and the subgraphs and the nodes
/// beside them keep one order in every rank, so no outsider stands among
/// a subgraph's members and no box is left of another in one rank and
/// right of it in the next. Then, once the ranks are packed, one sweep in
/// that order moves each node right until it is clear of everything
/// before it — the nodes, and the boxes it is not in.
///
/// The sweep only ever moves a node right, and each node once: an earlier
/// version pushed an outsider out of a box on either side, each push
/// widening another box, and three subgraphs side by side with a node
/// among them spread the chart over 42 000 px.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_subgraph_boxes.dart';

/// One thing a box (or the drawing) holds: a node, or the box of a
/// subgraph written inside it.
typedef _Item = ({String id, bool box});

/// What a placed item takes up beside the items after it: its extent along
/// the ranks, and its right edge.
typedef _Placed = ({double top, double bottom, double right});

/// The subgraphs each node of [chart] is in, outermost first: the
/// innermost one that lists it, and those it is written inside.
Map<String, List<String>> _chains(Flowchart chart) {
  final parent = {for (final s in chart.subgraphs) s.id: s.parent};
  int depth(String id) {
    var d = 0;
    for (var p = parent[id]; p != null; p = parent[p]) {
      d++;
    }
    return d;
  }

  final innermost = <String, String>{};
  for (final subgraph in chart.subgraphs) {
    for (final id in subgraph.nodeIds) {
      final held = innermost[id];
      if (held == null || depth(subgraph.id) > depth(held)) {
        innermost[id] = subgraph.id;
      }
    }
  }
  return {
    for (final MapEntry(key: id, value: inner) in innermost.entries)
      id: [for (String? s = inner; s != null; s = parent[s]) s].reversed
          .toList(),
  };
}

/// Where each subgraph of [chains] stands: the mean of [at] over every node
/// it holds, at any depth.
Map<String, double> _means(
  Map<String, List<String>> chains,
  Map<String, double> at,
) {
  final sum = <String, double>{};
  final count = <String, int>{};
  for (final MapEntry(key: id, value: chain) in chains.entries) {
    final value = at[id];
    if (value == null) continue;
    for (final subgraph in chain) {
      sum[subgraph] = (sum[subgraph] ?? 0) + value;
      count[subgraph] = (count[subgraph] ?? 0) + 1;
    }
  }
  return {for (final id in sum.keys) id: sum[id]! / count[id]!};
}

/// [items] in the order of [key], the first written first between equals.
List<T> _sorted<T>(List<T> items, double Function(T item) key) {
  final index = {for (var i = 0; i < items.length; i++) items[i]: i};
  return [...items]..sort((a, b) {
    final cmp = key(a).compareTo(key(b));
    return cmp != 0 ? cmp : index[a]!.compareTo(index[b]!);
  });
}

/// Reorders each rank of [layers] so the members of every subgraph of
/// [chart] sit side by side, keeping the order the ranks had as far as
/// that allows. A group goes by where its members stand on average over
/// every rank — each node's place a share of its rank, so ranks of any
/// length compare — and that one order serves every rank.
void groupSubgraphMembers(List<List<String>> layers, Flowchart chart) {
  if (chart.subgraphs.isEmpty) return;
  final chains = _chains(chart);
  final place = <String, double>{
    for (final layer in layers)
      for (var i = 0; i < layer.length; i++) layer[i]: (i + 0.5) / layer.length,
  };
  final where = _means(chains, place);
  double key(_Item item) => item.box ? where[item.id]! : place[item.id]!;

  List<String> arrange(List<String> ids, int depth) {
    final groups = <_Item, List<String>>{};
    for (final id in ids) {
      final chain = chains[id];
      // A node in no subgraph this deep is a group of its own.
      final group = chain != null && depth < chain.length
          ? (id: chain[depth], box: true)
          : (id: id, box: false);
      (groups[group] ??= []).add(id);
    }
    return [
      for (final group in _sorted(groups.keys.toList(), key))
        if (group.box) ...arrange(groups[group]!, depth + 1) else group.id,
    ];
  }

  for (var r = 0; r < layers.length; r++) {
    layers[r] = arrange(layers[r], 0);
  }
}

/// Moves nodes of [layers], at [rects], right until none stands in the box
/// of a subgraph of [chart] it is not in, nor on another node.
///
/// The drawing and every box hold items — nodes and the boxes inside them
/// — in the order [groupSubgraphMembers] gave the ranks. The items are
/// placed in that order, depth first, so a box is whole before what comes
/// after it: each node goes as far right as the items before it in every
/// box it is in demand, of those that share its item's extent along the
/// ranks, with the nodes' gap between and the padding of each box it is
/// in, and no further left than it was packed.
void clearSubgraphBoxes(
  Flowchart chart,
  List<List<String>> layers,
  Map<String, Rect> rects,
  DiagramStyle style,
) {
  if (chart.subgraphs.isEmpty) return;
  final chains = _chains(chart);
  final outlines = {
    for (final box in flowSubgraphBoxes(chart, rects, style))
      box.subgraph.id: box.rect,
  };
  // What a box takes left of its nodes: its padding, and the title band a
  // chart drawn across puts there (`flowSubgraphBoxes`).
  final lead =
      style.subgraphPadding +
      (chart.direction.isVertical ? 0 : style.fontSize * style.lineHeight + 8);

  final items = <String?, List<_Item>>{};
  final opened = <String>{};
  for (final layer in layers) {
    for (final id in layer) {
      String? container;
      for (final box in chains[id] ?? const <String>[]) {
        if (opened.add(box)) {
          (items[container] ??= []).add((id: box, box: true));
        }
        container = box;
      }
      (items[container] ??= []).add((id: id, box: false));
    }
  }
  final centre = {for (final id in rects.keys) id: rects[id]!.center.dx};
  final where = _means(chains, centre);
  List<_Item> ordered(String? container) => _sorted(
    items[container] ?? const [],
    (item) => item.box ? where[item.id]! : centre[item.id]!,
  );

  Rect extent(_Item item) => item.box ? outlines[item.id]! : rects[item.id]!;
  final placed = <String?, List<_Placed>>{};

  // The leftmost a node may stand at the end of [path]: each step a box
  // (or the drawing) and the item of it that holds the node.
  double lowest(List<({String? container, _Item item})> path) {
    var bound = double.negativeInfinity;
    for (var k = 0; k < path.length; k++) {
      final (:container, :item) = path[k];
      final span = extent(item);
      var right = double.negativeInfinity;
      for (final before in placed[container] ?? const <_Placed>[]) {
        if (before.top < span.bottom && span.top < before.bottom) {
          right = math.max(right, before.right);
        }
      }
      if (right == double.negativeInfinity) continue;
      final boxes = path.skip(k).where((step) => step.item.box).length;
      bound = math.max(bound, right + style.nodeGap + boxes * lead);
    }
    return bound;
  }

  // Places [item] of [container] and returns its right edge.
  double place(
    String? container,
    _Item item,
    List<({String? container, _Item item})> above,
  ) {
    final path = [...above, (container: container, item: item)];
    var right = double.negativeInfinity;
    if (item.box) {
      for (final child in ordered(item.id)) {
        right = math.max(right, place(item.id, child, path));
      }
      right += style.subgraphPadding;
    } else {
      final rect = rects[item.id]!;
      final dx = math.max<double>(0, lowest(path) - rect.left);
      rects[item.id] = rect.translate(dx, 0);
      right = rect.right + dx;
    }
    final span = extent(item);
    (placed[container] ??= []).add((
      top: span.top,
      bottom: span.bottom,
      right: right,
    ));
    return right;
  }

  for (final item in ordered(null)) {
    place(null, item, const []);
  }
}
