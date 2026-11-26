/// Settling what the barycentres want against what the clusters need
/// (#530).
///
/// After Forster, "A Fast and Simple Heuristic for Constrained Two-Level
/// Crossing Reduction", as dagre's `resolveConflicts` has it. Sorting by
/// barycentre alone could put cluster B left of cluster A in this rank when
/// an earlier rank put A left of B, and the boxes would then cross. When an
/// entry would end up on the wrong side of one it is constrained against, the
/// two are merged into one entry that keeps the constraint's order and takes
/// the weighted mean of their barycentres.
library;

import 'package:niman/src/diagrams/layered_constraints.dart';

/// Something to place in a rank: a node, or a cluster already sorted inside.
final class LayeredEntry {
  /// Creates an entry for [vertex], standing in position [index] among the
  /// entries of its rank, holding the nodes [nodes] in the order they will
  /// be placed. It has no barycentre unless [barycenter] says so.
  new(this.vertex, this.index, this.nodes, {this.barycenter, this.weight = 0});

  /// The node, or the cluster as the layers number it, it stands for.
  final int vertex;

  /// The lowest position among the entries it stands for.
  int index;

  /// The nodes, in the order they will be placed: just the node, or the
  /// cluster's sorted nodes, or several entries' once they are merged.
  List<int> nodes;

  /// The mean position of its neighbours in the rank next to it, or null if
  /// it has none: then it keeps its place.
  double? barycenter;

  /// How much the barycentre counts for.
  double weight;

  int _before = 0;
  final List<LayeredEntry> _after = [];
  final List<LayeredEntry> _behind = [];
  bool _merged = false;
}

/// Entries of [entries] in an order that keeps every constraint of
/// [constraints] among them: the same entries when nothing is constrained,
/// else fewer, merged where an entry's barycentre put it the wrong way.
///
/// [firstCluster] is the vertex number of the first cluster, the only
/// vertices that can be constrained.
List<LayeredEntry> resolveConflicts(
  List<LayeredEntry> entries,
  LayeredConstraints constraints,
  int firstCluster,
) {
  if (constraints.isEmpty || !entries.any((e) => e.vertex >= firstCluster)) {
    return entries;
  }
  final byVertex = {
    for (final entry in entries)
      if (entry.vertex >= firstCluster) entry.vertex: entry,
  };
  for (final entry in byVertex.values) {
    for (final right in constraints.successors(
      entry.vertex,
      byVertex.containsKey,
    )) {
      final other = byVertex[right]!;
      other._before++;
      entry._after.add(other);
    }
  }
  final sources = [
    for (final entry in entries)
      if (entry._before == 0) entry,
  ];
  final done = <LayeredEntry>[];
  while (sources.isNotEmpty) {
    final entry = sources.removeLast();
    done.add(entry);
    for (final behind in entry._behind.reversed) {
      if (behind._merged) continue;
      final b = behind.barycenter;
      final e = entry.barycenter;
      if (b == null || e == null || b >= e) _merge(entry, behind);
    }
    for (final next in entry._after) {
      next._behind.add(entry);
      if (--next._before == 0) sources.add(next);
    }
  }
  // Constraints that contradict one another leave entries no order gets
  // to: they keep their place, after the rest.
  if (done.length < entries.length) {
    for (final entry in entries) {
      if (entry._before > 0) done.add(entry);
    }
  }
  return [
    for (final entry in done)
      if (!entry._merged) entry,
  ];
}

/// Puts [source] in front of [target] in one entry, [target].
void _merge(LayeredEntry target, LayeredEntry source) {
  var sum = 0.0;
  var weight = 0.0;
  if (target.weight > 0) {
    sum += target.barycenter! * target.weight;
    weight += target.weight;
  }
  if (source.weight > 0) {
    sum += source.barycenter! * source.weight;
    weight += source.weight;
  }
  target.nodes = [...source.nodes, ...target.nodes];
  if (weight > 0) {
    target
      ..barycenter = sum / weight
      ..weight = weight;
  }
  if (source.index < target.index) target.index = source.index;
  source._merged = true;
}
