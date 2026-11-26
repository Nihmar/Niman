/// How far apart two neighbours in a rank are (#530).
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_node.dart';
import 'package:niman/src/diagrams/layered_options.dart';

/// The least distance between the centres of two nodes, one right after the
/// other in a rank.
///
/// It is their half widths and a gap. The gap is a cluster's pad where one
/// of them is the cluster's left or right side and the other is inside it;
/// otherwise half the node gap for each of them that is a box or a side of
/// a cluster not holding the other — so two boxes, two clusters' outlines,
/// and a side and a box outside it are a node gap apart — and half the edge
/// gap, which is smaller, for each that is the stand-in of an edge. A
/// stand-in between two boxes does not bring them closer than the node gap.
final class LayeredSeparation {
  /// Reads the sizes and the places in the cluster tree of [graph]'s nodes.
  new(LayeredGraph graph, this._options)
    : _width = Float64List(graph.nodes.length),
      _kind = Uint8List(graph.nodes.length),
      _parent = Int32List(graph.nodes.length),
      _clusterParent = Int32List(graph.clusters.length),
      _padLeft = Float64List(graph.clusters.length),
      _padRight = Float64List(graph.clusters.length) {
    for (final node in graph.nodes) {
      final i = node.index;
      _width[i] = node.width;
      _parent[i] = node.parent?.index ?? -1;
      _kind[i] = switch (node.kind) {
        LayeredNodeKind.real => _box,
        LayeredNodeKind.border when node.side == LayeredBorder.left => _left,
        LayeredNodeKind.border when node.side == LayeredBorder.right => _right,
        _ => _thin,
      };
    }
    for (final cluster in graph.clusters) {
      _clusterParent[cluster.index] = cluster.parent?.index ?? -1;
      _padLeft[cluster.index] = cluster.padLeft;
      _padRight[cluster.index] = cluster.padRight;
    }
  }

  static const int _box = 0;
  static const int _left = 1;
  static const int _right = 2;
  static const int _thin = 3;

  final LayeredOptions _options;
  final Float64List _width;
  final Uint8List _kind;
  final Int32List _parent;
  final Int32List _clusterParent;
  final Float64List _padLeft;
  final Float64List _padRight;

  /// The least distance from the centre of [left] to that of [right], the
  /// node to its right, by index.
  double between(int left, int right) {
    var gap = 0.0;
    var padded = false;
    if (_kind[left] == _left && _isInside(right, _parent[left])) {
      gap += _padLeft[_parent[left]];
      padded = true;
    }
    if (_kind[right] == _right && _isInside(left, _parent[right])) {
      gap += _padRight[_parent[right]];
      padded = true;
    }
    if (!padded) {
      gap =
          (_kind[left] == _thin ? _options.edgeGap : _options.nodeGap) / 2 +
          (_kind[right] == _thin ? _options.edgeGap : _options.nodeGap) / 2;
    }
    return _width[left] / 2 + gap + _width[right] / 2;
  }

  /// Whether [node] is in [cluster], or in one inside it, at any depth.
  bool _isInside(int node, int cluster) {
    for (var at = _parent[node]; at >= 0; at = _clusterParent[at]) {
      if (at == cluster) return true;
    }
    return false;
  }
}
