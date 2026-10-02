/// Keeping a subgraph's box to its own nodes (#530).
///
/// A rank is packed node after node, and a subgraph's box is drawn round
/// its nodes in every rank they sit in, so a node that is not in the
/// subgraph but shares a rank with it could fall inside the box — an
/// external system drawn within the enterprise boundary it is outside.
/// Two steps keep it out. In every rank the members of a subgraph sit side
/// by side, at every depth of nesting, so no outsider stands among them.
/// Then, once the ranks are packed, an outsider still inside a box — the
/// box being wider in another rank — is pushed out on its side, with every
/// node beyond it in its rank, until no box holds a node it does not own.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_subgraph_boxes.dart';

/// The subgraphs each node of [chart] is in, outermost first.
Map<String, List<String>> _chains(Flowchart chart) {
  final parent = {for (final s in chart.subgraphs) s.id: s.parent};
  int depth(String id) {
    var d = 0;
    for (var p = parent[id]; p != null; p = parent[p]) {
      d++;
    }
    return d;
  }

  final chains = <String, List<String>>{};
  for (final subgraph in chart.subgraphs) {
    for (final id in subgraph.nodeIds) {
      (chains[id] ??= []).add(subgraph.id);
    }
  }
  for (final chain in chains.values) {
    chain.sort((a, b) => depth(a).compareTo(depth(b)));
  }
  return chains;
}

/// Reorders each rank of [layers] so the members of every subgraph of
/// [chart] sit side by side, keeping the order the ranks had as far as
/// that allows: groups go by where their members stood on average.
void groupSubgraphMembers(List<List<String>> layers, Flowchart chart) {
  if (chart.subgraphs.isEmpty) return;
  final chains = _chains(chart);
  for (var r = 0; r < layers.length; r++) {
    final at = {for (var i = 0; i < layers[r].length; i++) layers[r][i]: i};
    List<String> arrange(List<String> ids, int depth) {
      final groups = <Object, List<String>>{};
      for (final id in ids) {
        final chain = chains[id];
        // A node in no subgraph this deep is a group of its own.
        final key = chain != null && depth < chain.length ? chain[depth] : id;
        (groups[key] ??= []).add(id);
      }
      double mean(List<String> group) =>
          group.fold<int>(0, (sum, id) => sum + at[id]!) / group.length;
      final ordered = groups.entries.toList()
        ..sort((a, b) => mean(a.value).compareTo(mean(b.value)));
      return [
        for (final MapEntry(:key, value: group) in ordered)
          if (group.length == 1 && key == group.single)
            group.single
          else
            ...arrange(group, depth + 1),
      ];
    }

    layers[r] = arrange(layers[r], 0);
  }
}

/// Moves nodes of [layers], at [rects], out of the box of every subgraph
/// of [chart] they are not in, each push taking the nodes beyond it in its
/// rank along so the rank keeps its order and its gaps.
void clearSubgraphBoxes(
  Flowchart chart,
  List<List<String>> layers,
  Map<String, Rect> rects,
  DiagramStyle style,
) {
  if (chart.subgraphs.isEmpty) return;
  final members = {
    for (final subgraph in chart.subgraphs)
      subgraph.id: subgraph.nodeIds.toSet(),
  };
  final gap = style.nodeGap;
  // Each push moves one node clear of one box for good unless another box
  // sends it back; the bound stops two boxes passing a node to and fro.
  final rounds = rects.length * chart.subgraphs.length + 1;
  for (var round = 0; round < rounds; round++) {
    final boxes = flowSubgraphBoxes(chart, rects, style);
    var pushed = false;
    for (final box in boxes) {
      final own = members[box.subgraph.id]!;
      for (final layer in layers) {
        for (var k = 0; k < layer.length; k++) {
          final id = layer[k];
          final rect = rects[id]!;
          if (own.contains(id) || !rect.overlaps(box.rect)) continue;
          // The side it stands on: past the box's own nodes in its rank,
          // or past the box's middle where the rank holds none of them.
          final first = layer.indexWhere(own.contains);
          final right = first < 0
              ? rect.center.dx >= box.rect.center.dx
              : k > first;
          if (right) {
            final dx = box.rect.right + gap - rect.left;
            for (var j = k; j < layer.length; j++) {
              rects[layer[j]] = rects[layer[j]]!.translate(dx, 0);
            }
          } else {
            final dx = rect.right - (box.rect.left - gap);
            for (var j = 0; j <= k; j++) {
              rects[layer[j]] = rects[layer[j]]!.translate(-dx, 0);
            }
          }
          pushed = true;
          break;
        }
        if (pushed) break;
      }
      if (pushed) break;
    }
    if (!pushed) return;
  }
}
