/// The graph the compound layered layout works on (#530): nodes with a
/// size, clusters that group them, and edges between them.
///
/// It knows nothing of flowcharts, so the stages of the layout — ranking,
/// ordering, placing — share it and a sequence or a state chart could draw
/// with it later. Everything keeps the order it was added in, so a layout
/// is the same every time it is run.
library;

import 'dart:collection';

import 'package:niman/src/diagrams/layered_cluster.dart';
import 'package:niman/src/diagrams/layered_edge.dart';
import 'package:niman/src/diagrams/layered_node.dart';

/// A mutable compound graph.
final class LayeredGraph {
  /// Creates an empty graph.
  new() {
    nodes = UnmodifiableListView(_nodes);
    clusters = UnmodifiableListView(_clusters);
    edges = UnmodifiableListView(_edges);
  }

  final List<LayeredNode> _nodes = [];
  final List<LayeredCluster> _clusters = [];
  final List<LayeredEdge> _edges = [];
  final Map<String, LayeredNode> _nodeById = {};
  final Map<String, LayeredCluster> _clusterById = {};
  var _auxiliary = 0;

  // Edges in and out of each node, indexed by node; null while a change
  // has left them out of date, and rebuilt by the next query.
  List<List<LayeredEdge>>? _out;
  List<List<LayeredEdge>>? _in;

  /// Every node, the layout's own included, in the order they were added.
  late final List<LayeredNode> nodes;

  /// Every cluster, in the order they were added.
  late final List<LayeredCluster> clusters;

  /// Every edge, the layout's own included, in the order they were added.
  late final List<LayeredEdge> edges;

  /// The nodes outside every cluster, in the order they were added.
  final List<LayeredNode> topNodes = [];

  /// The clusters outside every other, in the order they were added.
  final List<LayeredCluster> topClusters = [];

  /// How many ranks apart the caller's own edges are drawn: 2 once there is
  /// room for a label on every rank between two nodes, else 1. Set by the
  /// ranking.
  int rankSpacing = 1;

  /// The node named [id], or null.
  LayeredNode? node(String id) => _nodeById[id];

  /// The cluster named [id], or null.
  LayeredCluster? cluster(String id) => _clusterById[id];

  /// Adds the box [id] of the given size, inside the cluster [parent] if
  /// one is named. Throws if [id] is taken or [parent] does not exist.
  LayeredNode addNode(
    String id, {
    double width = 0,
    double height = 0,
    String? parent,
  }) {
    final cluster = _parentOf(parent);
    final node = _create(
      id,
      width: width,
      height: height,
      kind: LayeredNodeKind.real,
      parent: cluster,
    );
    (cluster?.nodes ?? topNodes).add(node);
    return node;
  }

  /// Adds the cluster [id], inside the cluster [parent] if one is named.
  /// Its two border nodes are made with it. The pads are the room between
  /// its box and what is in it on each side. Throws if [id] is taken or
  /// [parent] does not exist.
  LayeredCluster addCluster(
    String id, {
    String? parent,
    double padTop = 0,
    double padBottom = 0,
    double padLeft = 0,
    double padRight = 0,
  }) {
    _checkFree(id);
    final outer = _parentOf(parent);
    final cluster = LayeredCluster(
      id: id,
      index: _clusters.length,
      depth: outer == null ? 0 : outer.depth + 1,
      parent: outer,
      padTop: padTop,
      padBottom: padBottom,
      padLeft: padLeft,
      padRight: padRight,
    );
    _clusters.add(cluster);
    _clusterById[id] = cluster;
    (outer?.clusters ?? topClusters).add(cluster);
    cluster.borderTop = addAuxiliary(
      LayeredNodeKind.border,
      parent: cluster,
      side: LayeredBorder.top,
      name: 'top',
    );
    cluster.borderBottom = addAuxiliary(
      LayeredNodeKind.border,
      parent: cluster,
      side: LayeredBorder.bottom,
      name: 'bottom',
    );
    return cluster;
  }

  /// Adds a node of the layout's own, under a name no caller's id can be.
  /// [name] only makes it easier to read in a dump.
  LayeredNode addAuxiliary(
    LayeredNodeKind kind, {
    double width = 0,
    double height = 0,
    LayeredCluster? parent,
    LayeredBorder? side,
    String name = '',
  }) {
    final id = '\u0000${kind.name}${_auxiliary++}$name';
    return _create(
      id,
      width: width,
      height: height,
      kind: kind,
      parent: parent,
      side: side,
    );
  }

  /// Adds an edge from [from] to [to], each the id of a node or of a
  /// cluster. An edge to a cluster arrives at its top, one from a cluster
  /// leaves from its bottom. [source] is the caller's index for it, and
  /// [tailRoom] and [headRoom] the room it needs along itself next to each end.
  ///
  /// Throws if an end does not exist, or [minlen] or [weight] is negative.
  LayeredEdge addEdge(
    String from,
    String to, {
    int minlen = 1,
    double weight = 1,
    double labelWidth = 0,
    double labelHeight = 0,
    double tailRoom = 0,
    double headRoom = 0,
    int source = -1,
  }) {
    if (minlen < 0) throw ArgumentError.value(minlen, 'minlen');
    if (!(weight >= 0)) throw ArgumentError.value(weight, 'weight');
    final edge = LayeredEdge(
      index: _edges.length,
      fromId: from,
      toId: to,
      from: _end(from, leaving: true),
      to: _end(to, leaving: false),
      minlen: minlen,
      weight: weight,
      labelWidth: labelWidth,
      labelHeight: labelHeight,
      tailRoom: tailRoom,
      headRoom: headRoom,
      source: source,
      clusterEnd:
          _clusterById.containsKey(from) || _clusterById.containsKey(to),
    );
    _register(edge);
    return edge;
  }

  /// Adds an edge of the layout's own between two nodes of the graph.
  LayeredEdge connect(
    LayeredNode from,
    LayeredNode to, {
    required int minlen,
    required double weight,
    bool nesting = false,
  }) {
    final edge = LayeredEdge(
      index: _edges.length,
      fromId: from.id,
      toId: to.id,
      from: from,
      to: to,
      minlen: minlen,
      weight: weight,
      nesting: nesting,
    );
    _register(edge);
    return edge;
  }

  /// The edges that leave [node], in the order they were added. A view the
  /// next change to the graph's edges leaves out of date.
  List<LayeredEdge> outEdges(LayeredNode node) {
    _ensureAdjacency();
    return _out![node.index];
  }

  /// The edges that arrive at [node], in the order they were added. A view
  /// the next change to the graph's edges leaves out of date.
  List<LayeredEdge> inEdges(LayeredNode node) {
    _ensureAdjacency();
    return _in![node.index];
  }

  /// Turns [edge] against the caller's direction, or back again: an edge
  /// to a cluster then leaves from the cluster's bottom, and one from a
  /// cluster arrives at its top. Its flow follows.
  void reverse(LayeredEdge edge) {
    final turned = !edge.reversed;
    edge
      ..flow = turned ? LayeredEdgeFlow.reversed : LayeredEdgeFlow.forward
      ..from = _end(turned ? edge.toId : edge.fromId, leaving: true)
      ..to = _end(turned ? edge.fromId : edge.toId, leaving: false);
    _out = null;
    _in = null;
  }

  /// Drops every node after the first [nodeCount] and every edge after the
  /// first [edgeCount]: what a stage added, once it is done with it. They
  /// must be the last ones, and nothing that stays may refer to them.
  void truncate({required int nodeCount, required int edgeCount}) {
    for (var i = _nodes.length - 1; i >= nodeCount; i--) {
      _nodeById.remove(_nodes[i].id);
    }
    _nodes.length = nodeCount;
    _edges.length = edgeCount;
    _out = null;
    _in = null;
  }

  LayeredCluster? _parentOf(String? id) {
    if (id == null) return null;
    final cluster = _clusterById[id];
    if (cluster == null) throw ArgumentError.value(id, 'parent', 'no cluster');
    return cluster;
  }

  void _checkFree(String id) {
    if (_nodeById.containsKey(id) || _clusterById.containsKey(id)) {
      throw ArgumentError.value(id, 'id', 'already in the graph');
    }
  }

  LayeredNode _create(
    String id, {
    required double width,
    required double height,
    required LayeredNodeKind kind,
    required LayeredCluster? parent,
    LayeredBorder? side,
  }) {
    _checkFree(id);
    final node = LayeredNode(
      id: id,
      index: _nodes.length,
      width: width,
      height: height,
      kind: kind,
      parent: parent,
      side: side,
    );
    _nodes.add(node);
    _nodeById[id] = node;
    _out?.add([]);
    _in?.add([]);
    return node;
  }

  LayeredNode _end(String id, {required bool leaving}) {
    final node = _nodeById[id];
    if (node != null) return node;
    final cluster = _clusterById[id];
    if (cluster == null) throw ArgumentError.value(id, 'edge end', 'unknown');
    return leaving ? cluster.borderBottom : cluster.borderTop;
  }

  void _register(LayeredEdge edge) {
    if (edge.from == edge.to) edge.flow = LayeredEdgeFlow.loop;
    _edges.add(edge);
    _out?[edge.from.index].add(edge);
    _in?[edge.to.index].add(edge);
  }

  void _ensureAdjacency() {
    if (_out != null) return;
    final out = [for (var i = 0; i < _nodes.length; i++) <LayeredEdge>[]];
    final inn = [for (var i = 0; i < _nodes.length; i++) <LayeredEdge>[]];
    for (final edge in _edges) {
      out[edge.from.index].add(edge);
      inn[edge.to.index].add(edge);
    }
    _out = out;
    _in = inn;
  }
}
