/// Putting each stand-in of a long edge in a cluster (#530).
///
/// After dagre's `parentDummyChains`. An edge between two nodes of one
/// cluster has to stay inside it, or the ordering would put an outsider's
/// stand-in among the members' and the cluster's box would be drawn round
/// it. An edge that leaves a cluster leaves it at the cluster's last rank,
/// and one that enters a cluster enters it at its first. So the stand-ins
/// go up the clusters of the edge's start to the lowest cluster that holds
/// both ends, and down the clusters of its end, each in the one whose ranks
/// it is in.
library;

import 'package:niman/src/diagrams/layered_cluster.dart';
import 'package:niman/src/diagrams/layered_edge.dart';
import 'package:niman/src/diagrams/layered_graph.dart';

/// Sets the cluster of every stand-in on a chain of [graph]'s edges.
void parentDummyChains(LayeredGraph graph) {
  for (final edge in graph.edges) {
    if (edge.chain.isEmpty) continue;
    final (path, common) = _path(edge);
    var at = 0;
    var ascending = true;
    for (final stand in edge.chain) {
      if (ascending) {
        // Out of a cluster once the rank is past its last.
        while (at < common && path[at]!.maxRank < stand.rank) {
          at++;
        }
        if (at == common) ascending = false;
      }
      if (!ascending) {
        // Into the next cluster once the rank reaches its first.
        while (at < path.length - 1 && path[at + 1]!.minRank <= stand.rank) {
          at++;
        }
      }
      stand.parent = path[at];
    }
  }
}

/// The clusters from [edge]'s start up to the one that holds both ends and
/// down again to its end, and where the meeting point is in the list: the
/// lowest cluster that holds both, or null, in the list as well, when they
/// meet at the top level.
(List<LayeredCluster?>, int) _path(LayeredEdge edge) {
  final up = <LayeredCluster?>[];
  final down = <LayeredCluster?>[];
  var a = edge.from.parent;
  var b = edge.to.parent;
  while (a != b) {
    if (a != null && (b == null || a.depth >= b.depth)) {
      up.add(a);
      a = a.parent;
    } else {
      down.add(b);
      b = b!.parent;
    }
  }
  return ([...up, a, ...down.reversed], up.length);
}
