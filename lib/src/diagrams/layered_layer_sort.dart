/// Sorting one rank of a compound layered graph (#530).
///
/// After dagre's `sortSubgraph`, `barycenter` and `sort`. A rank is a tree:
/// nodes, and clusters holding nodes and clusters. Each level is sorted by
/// the mean position of its entries' neighbours in the rank next to it, the
/// barycentre, and a cluster is an entry of its parent's level whose
/// barycentre is the mean of its members'. A cluster's content goes between
/// its left and right border nodes, so it stays one run however its members
/// move.
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_cluster.dart';
import 'package:niman/src/diagrams/layered_conflicts.dart';
import 'package:niman/src/diagrams/layered_constraints.dart';
import 'package:niman/src/diagrams/layered_layers.dart';
import 'package:niman/src/diagrams/layered_segments.dart';

/// A rank, or a cluster's part of one, sorted.
final class LayeredSorted {
  /// Creates the result of a sort.
  new(this.nodes, this.barycenter, this.weight, {this.tied = false});

  /// The nodes, in their new order.
  final List<int> nodes;

  /// The mean position of their neighbours, or null if none has any.
  final double? barycenter;

  /// How much the barycentre counts for.
  final double weight;

  /// Whether two entries had the same barycentre and the bias settled which
  /// went first.
  final bool tied;
}

/// Sorts ranks against their neighbour in one direction.
final class LayerSorter {
  /// Creates a sorter over [_layers], whose clusters are [_clusters], using
  /// and keeping each node's place in [_order].
  new(this._layers, this._segments, this._clusters, this._order);

  final LayeredLayers _layers;
  final LayeredSegments _segments;
  final List<LayeredCluster> _clusters;
  final Int32List _order;

  /// Whether ties go to the entry that was later, not the one that was
  /// earlier.
  bool biasRight = true;

  /// Whether the rank before is the fixed one, so a node's neighbours are
  /// the segments up, or the rank after, so they are those down.
  bool down = true;

  /// The cluster order the ranks sorted so far decided.
  LayeredConstraints constraints = LayeredConstraints();

  /// Sorts [rank] against the one next to it, in the direction set.
  LayeredSorted sort(int rank) => _sortLevel(-1, rank);

  /// Records the order of the clusters in [nodes], a rank in order, as
  /// constraints for the ranks still to sort: each cluster, and each
  /// cluster it is inside, stays after the cluster that came before it
  /// among its siblings.
  void record(List<int> nodes) {
    final base = _layers.nodeCount;
    final previous = <int, int>{};
    for (final node in nodes) {
      var child = _layers.nodeParent[node];
      while (child >= 0) {
        final parent = _layers.clusterParent[child];
        final before = previous[parent];
        previous[parent] = child;
        if (before != null && before != child) {
          constraints.add(base + before, base + child);
          break;
        }
        child = parent;
      }
    }
  }

  /// Sorts the entries of one level: the top of the rank if [cluster] is -1,
  /// else the cluster's part of it.
  LayeredSorted _sortLevel(int cluster, int rank) {
    final base = _layers.nodeCount;
    final box = cluster < 0 ? null : _clusters[cluster];
    final at = box == null ? 0 : rank - box.minRank;
    final holder = box == null
        ? _layers.top[rank]
        : _layers.inside[cluster][at];
    final left = box?.borderLeft[at].index ?? -1;
    final right = box?.borderRight[at].index ?? -1;
    final entries = <LayeredEntry>[];
    for (final vertex in holder) {
      if (vertex == left || vertex == right) continue;
      if (vertex < base) {
        entries.add(_nodeEntry(vertex, entries.length));
      } else {
        final inner = _sortLevel(vertex - base, rank);
        entries.add(
          LayeredEntry(
            vertex,
            entries.length,
            inner.nodes,
            barycenter: inner.barycenter,
            weight: inner.weight,
          ),
        );
      }
    }
    final sorted = _place(resolveConflicts(entries, constraints, base));
    return box == null ? sorted : _bracket(sorted, left, right);
  }

  LayeredEntry _nodeEntry(int node, int index) {
    final start = down ? _segments.upStart : _segments.downStart;
    final others = down ? _segments.upNodes : _segments.downNodes;
    final weights = down ? _segments.upWeights : _segments.downWeights;
    var sum = 0.0;
    var weight = 0.0;
    for (var i = start[node]; i < start[node + 1]; i++) {
      sum += weights[i] * _order[others[i]];
      weight += weights[i];
    }
    if (weight <= 0) return LayeredEntry(node, index, [node]);
    return LayeredEntry(
      node,
      index,
      [node],
      barycenter: sum / weight,
      weight: weight,
    );
  }

  /// Puts the entries with a barycentre in its order, and the others where
  /// they stood.
  LayeredSorted _place(List<LayeredEntry> entries) {
    final sortable = <LayeredEntry>[];
    final fixed = <LayeredEntry>[];
    for (final entry in entries) {
      (entry.barycenter == null ? fixed : sortable).add(entry);
    }
    sortable.sort((a, b) {
      final byBarycenter = a.barycenter!.compareTo(b.barycenter!);
      if (byBarycenter != 0) return byBarycenter;
      return biasRight ? b.index - a.index : a.index - b.index;
    });
    // Last first, so the next to be placed is the one to pop.
    fixed.sort((a, b) => b.index - a.index);
    final nodes = <int>[];
    var sum = 0.0;
    var weight = 0.0;
    var tied = false;
    var placed = _takeFixed(nodes, fixed, 0);
    for (var i = 0; i < sortable.length; i++) {
      final entry = sortable[i];
      final barycenter = entry.barycenter!;
      if (i > 0 &&
          barycenter != 0 &&
          barycenter == sortable[i - 1].barycenter) {
        tied = true;
      }
      nodes.addAll(entry.nodes);
      placed += entry.nodes.length;
      sum += barycenter * entry.weight;
      weight += entry.weight;
      placed = _takeFixed(nodes, fixed, placed);
    }
    while (fixed.isNotEmpty) {
      nodes.addAll(fixed.removeLast().nodes);
    }
    return LayeredSorted(
      nodes,
      weight > 0 ? sum / weight : null,
      weight,
      tied: tied,
    );
  }

  /// Places the entries that keep their place, once [placed] have gone
  /// before; returns how many have. Those with a barycentre count by node
  /// and these by entry, as in dagre, so the place they keep is the one they
  /// stood in only when nothing before them is a cluster or a merge.
  int _takeFixed(List<int> nodes, List<LayeredEntry> fixed, int placed) {
    var count = placed;
    while (fixed.isNotEmpty && fixed.last.index <= count) {
      nodes.addAll(fixed.removeLast().nodes);
      count++;
    }
    return count;
  }

  /// Puts [left] and [right], a cluster's border nodes, round [sorted], and
  /// counts their neighbours in the fixed rank in its barycentre, so a
  /// cluster is drawn towards where its own sides were in that rank.
  LayeredSorted _bracket(LayeredSorted sorted, int left, int right) {
    final nodes = [left, ...sorted.nodes, right];
    final start = down ? _segments.upStart : _segments.downStart;
    final others = down ? _segments.upNodes : _segments.downNodes;
    if (start[left] == start[left + 1] || start[right] == start[right + 1]) {
      return LayeredSorted(
        nodes,
        sorted.barycenter,
        sorted.weight,
        tied: sorted.tied,
      );
    }
    final sum =
        (sorted.barycenter ?? 0) * sorted.weight +
        _order[others[start[left]]] +
        _order[others[start[right]]];
    final weight = sorted.weight + 2;
    return LayeredSorted(nodes, sum / weight, weight, tied: sorted.tied);
  }
}
