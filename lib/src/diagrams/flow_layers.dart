/// Ranking and ordering a flowchart's nodes (#530): the first half of the
/// layout, in canonical space — ranks run downwards, the order within a
/// rank runs to the right.
///
/// Nodes are ranked by longest path and ordered within a rank by
/// barycentre, to cut crossings.
library;

import 'dart:math' as math;

import 'package:niman/src/diagrams/flow_model.dart';

/// The nodes of [chart] in layers, one per rank, each ordered to cut
/// crossings.
List<List<String>> flowLayers(Flowchart chart) =>
    _orderedLayers(chart, _ranks(chart));

/// The rank of every node, cycle-safe.
Map<String, int> _ranks(Flowchart chart) {
  final order = [for (final node in chart.nodes) node.id];
  final out = <String, Set<String>>{for (final id in order) id: <String>{}};
  final incoming = <String, Set<String>>{
    for (final id in order) id: <String>{},
  };
  for (final edge in chart.edges) {
    if (edge.from == edge.to) continue;
    if (out[edge.from]!.add(edge.to)) incoming[edge.to]!.add(edge.from);
  }

  final rank = <String, int>{for (final id in order) id: 0};
  final indegree = <String, int>{
    for (final id in order) id: incoming[id]!.length,
  };
  final queue = [
    for (final id in order)
      if (indegree[id] == 0) id,
  ];
  final processed = <String>{};
  for (var head = 0; head < queue.length; head++) {
    final id = queue[head];
    processed.add(id);
    for (final next in out[id]!) {
      rank[next] = math.max(rank[next]!, rank[id]! + 1);
      indegree[next] = indegree[next]! - 1;
      if (indegree[next] == 0) queue.add(next);
    }
  }
  final remaining = [
    for (final id in order)
      if (!processed.contains(id)) id,
  ];
  if (remaining.isNotEmpty) {
    final rest = remaining.toSet();
    for (final id in remaining) {
      var best = 0;
      for (final pred in incoming[id]!) {
        if (!rest.contains(pred)) best = math.max(best, rank[pred]! + 1);
      }
      rank[id] = best;
    }
    for (var pass = 0; pass < remaining.length; pass++) {
      var changed = false;
      for (final id in remaining) {
        for (final next in out[id]!) {
          if (!rest.contains(next)) continue;
          if (rank[next]! <= rank[id]!) {
            rank[next] = rank[id]! + 1;
            changed = true;
          }
        }
      }
      if (!changed) break;
    }
  }

  final distinct = rank.values.toSet().toList()..sort();
  final index = <int, int>{
    for (var i = 0; i < distinct.length; i++) distinct[i]: i,
  };
  return {for (final id in order) id: index[rank[id]]!};
}

/// The nodes grouped by rank, ordered to cut crossings.
List<List<String>> _orderedLayers(Flowchart chart, Map<String, int> ranks) {
  final depth = ranks.values.fold(0, math.max) + 1;
  final layers = List.generate(depth, (_) => <String>[]);
  for (final node in chart.nodes) {
    layers[ranks[node.id]!].add(node.id);
  }
  final incoming = <String, List<String>>{};
  final outgoing = <String, List<String>>{};
  for (final node in chart.nodes) {
    incoming[node.id] = [];
    outgoing[node.id] = [];
  }
  for (final edge in chart.edges) {
    if (edge.from == edge.to) continue;
    outgoing[edge.from]!.add(edge.to);
    incoming[edge.to]!.add(edge.from);
  }

  final position = <String, int>{};
  void reindex() {
    for (final layer in layers) {
      for (var i = 0; i < layer.length; i++) {
        position[layer[i]] = i;
      }
    }
  }

  reindex();
  for (var pass = 0; pass < 4; pass++) {
    for (var r = 1; r < depth; r++) {
      _sortBy(layers[r], incoming, position);
      reindex();
    }
    for (var r = depth - 2; r >= 0; r--) {
      _sortBy(layers[r], outgoing, position);
      reindex();
    }
  }
  return layers;
}

void _sortBy(
  List<String> layer,
  Map<String, List<String>> neighbours,
  Map<String, int> position,
) {
  final base = {for (var i = 0; i < layer.length; i++) layer[i]: i};
  layer.sort((a, b) {
    final cmp = _barycentre(
      a,
      neighbours,
      position,
    ).compareTo(_barycentre(b, neighbours, position));
    return cmp != 0 ? cmp : base[a]!.compareTo(base[b]!);
  });
}

double _barycentre(
  String id,
  Map<String, List<String>> neighbours,
  Map<String, int> position,
) {
  final list = neighbours[id]!;
  if (list.isEmpty) return -1;
  var sum = 0;
  for (final other in list) {
    sum += position[other] ?? 0;
  }
  return sum / list.length;
}
