/// Ranking and ordering a flowchart's nodes (#530): the first half of the
/// layout, in canonical space — ranks run downwards, the order within a
/// rank runs to the right.
///
/// A cycle is broken where a walk in the order the nodes were written
/// meets it again, so the node written first stays on top; the rest is
/// ranked by longest path and ordered within a rank by barycentre, to cut
/// crossings. Every step is linear in the chart, or a sort of one rank:
/// the read view lays a diagram out in build.
library;

import 'dart:math' as math;

import 'package:niman/src/diagrams/flow_model.dart';

/// How many down-and-up sweeps the ordering makes.
const int _sweeps = 4;

/// The nodes of [chart] in layers, one per rank, each ordered to cut
/// crossings.
///
/// A note tied to one node by an edge sits beside it, as a sequence's note
/// sits beside its lifeline: in its rank, right after it, the tie taking no
/// part in the ranking or the ordering. A note drawn a rank below fell in
/// whatever stood there — the box of a composite state, for one.
List<List<String>> flowLayers(Flowchart chart) {
  final ids = [for (final node in chart.nodes) node.id];
  final beside = _tiedNotes(chart);
  final out = <String, List<String>>{for (final id in ids) id: []};
  final incoming = <String, List<String>>{for (final id in ids) id: []};
  final seen = <(String, String)>{};
  for (final edge in chart.edges) {
    if (edge.from == edge.to || !seen.add((edge.from, edge.to))) continue;
    if (beside[edge.from] == edge.to || beside[edge.to] == edge.from) {
      continue;
    }
    out[edge.from]!.add(edge.to);
    incoming[edge.to]!.add(edge.from);
  }
  final rank = _ranks(ids, out);
  beside.forEach((note, target) => rank[note] = rank[target]!);
  final depth = rank.values.fold(0, math.max) + 1;
  final layers = List.generate(depth, (_) => <String>[]);
  for (final id in ids) {
    if (!beside.containsKey(id)) layers[rank[id]!].add(id);
  }
  _order(layers, incoming, out);
  // Each note right after the node it is tied to, once the rest is placed.
  for (final MapEntry(key: note, value: target) in beside.entries) {
    final layer = layers[rank[target]!];
    layer.insert(layer.indexOf(target) + 1, note);
  }
  return layers;
}

/// The notes tied to exactly one other node, and that node.
Map<String, String> _tiedNotes(Flowchart chart) {
  final notes = {
    for (final node in chart.nodes)
      if (node.shape == FlowNodeShape.note) node.id,
  };
  final ties = <String, Set<String>>{};
  for (final edge in chart.edges) {
    final (note, other) = notes.contains(edge.from)
        ? (edge.from, edge.to)
        : (edge.to, edge.from);
    if (!notes.contains(note) || notes.contains(other)) continue;
    (ties[note] ??= {}).add(other);
  }
  return {
    for (final MapEntry(key: note, value: others) in ties.entries)
      if (others.length == 1) note: others.single,
  };
}

/// The rank of every node of [ids], whose edges are [out]: the longest
/// path to it once the edges that close a cycle are set aside.
Map<String, int> _ranks(List<String> ids, Map<String, List<String>> out) {
  // An edge back to a node still on the walk's path closes a cycle.
  final onPath = <String>{};
  final done = <String>{};
  final forward = <String, List<String>>{for (final id in ids) id: []};
  for (final root in ids) {
    if (done.contains(root)) continue;
    final stack = <(String, int)>[(root, 0)];
    onPath.add(root);
    while (stack.isNotEmpty) {
      final (id, next) = stack.last;
      final targets = out[id]!;
      if (next == targets.length) {
        stack.removeLast();
        onPath.remove(id);
        done.add(id);
        continue;
      }
      stack.last = (id, next + 1);
      final target = targets[next];
      if (onPath.contains(target)) continue;
      forward[id]!.add(target);
      if (done.contains(target)) continue;
      onPath.add(target);
      stack.add((target, 0));
    }
  }
  final indegree = <String, int>{for (final id in ids) id: 0};
  for (final id in ids) {
    for (final target in forward[id]!) {
      indegree[target] = indegree[target]! + 1;
    }
  }
  final rank = <String, int>{for (final id in ids) id: 0};
  final queue = [
    for (final id in ids)
      if (indegree[id] == 0) id,
  ];
  for (var head = 0; head < queue.length; head++) {
    final id = queue[head];
    for (final target in forward[id]!) {
      rank[target] = math.max(rank[target]!, rank[id]! + 1);
      indegree[target] = indegree[target]! - 1;
      if (indegree[target] == 0) queue.add(target);
    }
  }
  return rank;
}

/// Orders each of [layers] by the barycentre of its neighbours in the rank
/// before it, then after it, a few sweeps down and up.
void _order(
  List<List<String>> layers,
  Map<String, List<String>> incoming,
  Map<String, List<String>> outgoing,
) {
  final position = <String, int>{};
  for (final layer in layers) {
    _place(layer, position);
  }
  for (var sweep = 0; sweep < _sweeps; sweep++) {
    for (var r = 1; r < layers.length; r++) {
      _sortBy(layers[r], incoming, position);
    }
    for (var r = layers.length - 2; r >= 0; r--) {
      _sortBy(layers[r], outgoing, position);
    }
  }
}

/// Sorts [layer] by the mean position of each node's [neighbours], keeping
/// the present order between equals, and records the new positions.
void _sortBy(
  List<String> layer,
  Map<String, List<String>> neighbours,
  Map<String, int> position,
) {
  final key = {
    for (final id in layer) id: _barycentre(id, neighbours, position),
  };
  layer.sort((a, b) {
    final cmp = key[a]!.compareTo(key[b]!);
    return cmp != 0 ? cmp : position[a]!.compareTo(position[b]!);
  });
  _place(layer, position);
}

void _place(List<String> layer, Map<String, int> position) {
  for (var i = 0; i < layer.length; i++) {
    position[layer[i]] = i;
  }
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
