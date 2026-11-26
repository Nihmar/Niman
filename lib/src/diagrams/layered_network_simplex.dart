/// Ranking by network simplex (#530): the ranks that make the edges, added
/// up by how much each matters, as short as they can be.
///
/// After Gansner, Koutsofios, North and Vo, "A Technique for Drawing
/// Directed Graphs". A spanning tree of tight edges holds the ranks; each
/// tree edge has a cut value, the weight that runs along it minus the
/// weight that runs against it across the split it makes in the tree. A
/// negative one says the tree is not the shortest: trading that edge for
/// the shortest edge that crosses the split the other way shortens the
/// drawing. When none is negative the ranks are the best there are.
///
/// A cut value is the weight left over by the nodes on one side of the
/// edge, summed in one pass over the tree. The tree is numbered in
/// postorder, so the nodes under an edge are a run of numbers: the
/// `low`..`lim` range of its lower end. That range answers whether a node
/// is under an edge, and the nodes under it are one slice of an array. A
/// trade changes the tree only inside the subtree of the closest common
/// ancestor of the two edges' ends, so only that subtree is numbered and
/// summed again.
library;

import 'dart:typed_data';

import 'package:niman/src/diagrams/layered_feasible_tree.dart';
import 'package:niman/src/diagrams/layered_rank_network.dart';

/// A cut value this close to nothing is nothing: weights are sums of
/// numbers the caller gave, and a sum has its rounding.
const double _epsilon = 1e-9;

/// Gives [network] the ranks of least total weighted edge length, starting
/// from whatever honours every minimum length. The ranks are not moved to
/// start at 0.
///
/// A ranking is feasible after every trade, so if the trades ever failed to
/// end the ranks would still be valid, only not the shortest: it stops after
/// a number of them no real graph needs.
void networkSimplex(RankNetwork network) {
  if (network.nodeCount == 0) return;
  network.rankByLongestPath();
  _Simplex(network, feasibleTree(network)).run();
}

/// The state of one run: the tree and what is known of it.
final class _Simplex {
  new(this._net, this._inTree)
    : _parent = Int32List(_net.nodeCount),
      _parentEdge = Int32List(_net.nodeCount),
      _low = Int32List(_net.nodeCount),
      _lim = Int32List(_net.nodeCount),
      _byLim = Int32List(_net.nodeCount),
      _under = Float64List(_net.nodeCount),
      _cursor = Int32List(_net.nodeCount),
      _stack = Int32List(_net.nodeCount);

  final RankNetwork _net;

  /// Which edges are in the tree.
  final Uint8List _inTree;

  /// The node above each node in the tree, and the edge between them.
  final Int32List _parent;
  final Int32List _parentEdge;

  /// The postorder numbers of the nodes under each node, itself included:
  /// from `_low` up to its own `_lim`.
  final Int32List _low;
  final Int32List _lim;

  /// The node with each postorder number.
  final Int32List _byLim;

  /// The weight left over by the nodes under each node, itself included:
  /// what leaves them for outside minus what arrives from outside.
  final Float64List _under;

  final Int32List _cursor;
  final Int32List _stack;

  void run() {
    _parent[0] = -1;
    _parentEdge[0] = -1;
    _number(0, 0);
    final limit = 100 * (_net.nodeCount + _net.edgeCount) + 1000;
    var scanned = 0;
    for (var trades = 0; trades < limit; trades++) {
      final (child, next) = _leaving(scanned);
      if (child < 0) return;
      scanned = next;
      if (!_trade(child)) return;
    }
  }

  /// The cut value of the tree edge above [node].
  double _cut(int node) {
    final edge = _parentEdge[node];
    return _net.tail[edge] == node ? _under[node] : -_under[node];
  }

  /// The first node from [from], going round, whose edge up has a negative
  /// cut value, and where to look next; -1 if none has.
  (int, int) _leaving(int from) {
    final count = _net.nodeCount;
    var node = from;
    for (var seen = 0; seen < count; seen++) {
      if (_parentEdge[node] >= 0 && _cut(node) < -_epsilon) return (node, node);
      if (++node == count) node = 0;
    }
    return (-1, 0);
  }

  /// Trades the tree edge above [child] for the edge that crosses its split
  /// the other way with the least slack. False if there is none, which a
  /// negative cut value rules out unless the weights are not numbers.
  bool _trade(int child) {
    final net = _net;
    final leaving = _parentEdge[child];
    final low = _low[child];
    final lim = _lim[child];
    // The tree below the edge is the side its lower end is on. If that is
    // its tail, the edge to take in leaves from outside and arrives within.
    final belowIsTail = net.tail[leaving] == child;
    var entering = -1;
    for (var at = low; at <= lim; at++) {
      final node = _byLim[at];
      final from = belowIsTail ? net.outEnd[node] : net.incStart[node];
      final to = belowIsTail ? net.incStart[node + 1] : net.outEnd[node];
      for (var i = from; i < to; i++) {
        final edge = net.incEdges[i];
        final other = belowIsTail ? net.tail[edge] : net.head[edge];
        final position = _lim[other];
        if (position >= low && position <= lim) continue;
        if (entering < 0 || net.slack(edge) < net.slack(entering)) {
          entering = edge;
        }
      }
    }
    if (entering < 0) return false;
    final slack = net.slack(entering);
    if (slack != 0) {
      // Everything below moves so the edge taken in has no slack: down if
      // the edge to leave was above its tail, up if above its head.
      final by = belowIsTail ? -slack : slack;
      for (var at = low; at <= lim; at++) {
        net.rank[_byLim[at]] += by;
      }
    }
    var ancestor = net.tail[entering];
    final far = _lim[net.head[entering]];
    while (!(_low[ancestor] <= far && far <= _lim[ancestor])) {
      ancestor = _parent[ancestor];
    }
    _inTree[leaving] = 0;
    _inTree[entering] = 1;
    _number(ancestor, _low[ancestor]);
    return true;
  }

  /// Numbers the subtree under [root] in postorder from [first], setting
  /// each node's parent, range and left-over weight.
  void _number(int root, int first) {
    final net = _net;
    var next = first;
    var depth = 0;
    _stack[0] = root;
    _low[root] = next;
    _under[root] = net.surplus[root];
    _cursor[root] = net.incStart[root];
    while (depth >= 0) {
      final node = _stack[depth];
      var descended = false;
      final end = net.incStart[node + 1];
      var i = _cursor[node];
      while (i < end) {
        final edge = net.incEdges[i++];
        if (_inTree[edge] == 0 || edge == _parentEdge[node]) continue;
        final child = net.tail[edge] == node ? net.head[edge] : net.tail[edge];
        _parent[child] = node;
        _parentEdge[child] = edge;
        _low[child] = next;
        _under[child] = net.surplus[child];
        _cursor[child] = net.incStart[child];
        _stack[++depth] = child;
        descended = true;
        break;
      }
      _cursor[node] = i;
      if (descended) continue;
      _lim[node] = next;
      _byLim[next++] = node;
      depth--;
      if (depth >= 0) _under[_stack[depth]] += _under[node];
    }
  }
}
