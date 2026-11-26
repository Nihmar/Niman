/// The nesting graph (#530): what lets a ranking that knows only nodes and
/// edges keep a cluster in one compact band of ranks.
///
/// After Sander's "Layout of compound directed graphs", as dagre does it.
/// Every cluster has a top and a bottom node; each member is tied below the
/// top and above the bottom by an edge much heavier than any the caller
/// drew, so the ranking pulls the two borders tight round the members. A
/// root above everything ties the pieces together, so the graph is one
/// connected whole whatever the caller drew.
///
/// The rank of a border must never meet the rank of a node, or a cluster's
/// frame would share a row with a box. So the caller's edges are
/// stretched: every minimum length is multiplied by a factor that leaves
/// `nodeRankFactor` − 1 ranks between two rows of nodes for the borders of
/// the clusters in between, one per level of nesting.
library;

import 'package:niman/src/diagrams/layered_cluster.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_node.dart';

/// A nesting graph added to a [LayeredGraph], for the time of a ranking.
final class LayeredNesting {
  new _(
    this._graph,
    this._nodeCount,
    this._edgeCount,
    this.root,
    this.nodeRankFactor,
  );

  /// Adds the root, the nesting edges, and each cluster's ties to its
  /// members to [graph], which must have no ring in its ranked edges.
  factory add(LayeredGraph graph) {
    final nodeCount = graph.nodes.length;
    final edgeCount = graph.edges.length;
    final height = _height(graph);
    final nodeSep = 2 * height + 1;
    final nesting = LayeredNesting._(
      graph,
      nodeCount,
      edgeCount,
      graph.addAuxiliary(LayeredNodeKind.nestingRoot, name: 'root'),
      nodeSep,
    );
    // Heavy enough that no way of shortening the caller's edges is worth
    // stretching a cluster: more than all of them together.
    var weight = 1.0;
    for (final edge in graph.edges) {
      if (edge.ranked) weight += edge.weight;
    }
    for (final node in graph.topNodes) {
      graph.connect(
        nesting.root,
        node,
        minlen: nodeSep,
        weight: 0,
        nesting: true,
      );
    }
    for (final cluster in graph.topClusters) {
      nesting._tie(cluster, height, weight);
      graph.connect(
        nesting.root,
        cluster.borderTop,
        minlen: height + 1,
        weight: 0,
        nesting: true,
      );
    }
    return nesting;
  }

  final LayeredGraph _graph;
  final int _nodeCount;
  final int _edgeCount;

  /// The node above everything while ranking; [cleanup] takes it away.
  final LayeredNode root;

  /// What the caller's minimum lengths are multiplied by, and the gap
  /// between two rows of nodes: 1 with no cluster, 3 with one level, 5 with
  /// two.
  final int nodeRankFactor;

  /// Takes the root and every edge the nesting added out of the graph. The
  /// clusters' border nodes stay: they hold the rank of the box's top and
  /// bottom.
  void cleanup() {
    _graph.truncate(nodeCount: _nodeCount, edgeCount: _edgeCount);
  }

  /// Ties [cluster]'s members between its borders, and its sub-clusters'
  /// the same way, down.
  void _tie(LayeredCluster cluster, int height, double weight) {
    final graph = _graph;
    // How far the cluster's rows sit from its border: a node leaves room
    // for the borders of the levels still to come below it.
    final reach = height - cluster.depth;
    void join(LayeredNode top, LayeredNode bottom, int minlen, double w) {
      graph
        ..connect(
          cluster.borderTop,
          top,
          minlen: minlen,
          weight: w,
          nesting: true,
        )
        ..connect(
          bottom,
          cluster.borderBottom,
          minlen: minlen,
          weight: w,
          nesting: true,
        );
    }

    for (final node in cluster.nodes) {
      join(node, node, reach, 2 * weight);
    }
    for (final inner in cluster.clusters) {
      _tie(inner, height, weight);
      join(inner.borderTop, inner.borderBottom, 1, weight);
    }
    if (cluster.isEmpty) {
      // Standing in for a node: the room one would take.
      graph.connect(
        cluster.borderTop,
        cluster.borderBottom,
        minlen: 2 * reach,
        weight: 2 * weight,
        nesting: true,
      );
    }
  }

  /// The depth of the deepest node, less one: how many levels of borders can
  /// stand between two rows of nodes. A cluster counts for the node it could
  /// hold, so an empty one has room for its own box.
  static int _height(LayeredGraph graph) {
    var deepest = 1;
    for (final cluster in graph.clusters) {
      if (cluster.depth + 2 > deepest) deepest = cluster.depth + 2;
    }
    return deepest - 1;
  }
}
