// The first stage of the compound layered layout (#530): acyclic, nesting
// graph, network simplex. Ranks are asserted, not pixels.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/layered_edge.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_rank.dart';

/// A graph of the nodes [ids], with an edge for each `from>to` of [edges].
LayeredGraph _graph(List<String> ids, List<String> edges) {
  final graph = LayeredGraph();
  ids.forEach(graph.addNode);
  for (final edge in edges) {
    final [from, to] = edge.split('>');
    graph.addEdge(from, to);
  }
  return graph;
}

/// The rank of the node [id].
int _rank(LayeredGraph graph, String id) => graph.node(id)!.rank;

/// The ranks of [ids], in order.
List<int> _ranks(LayeredGraph graph, List<String> ids) => [
  for (final id in ids) _rank(graph, id),
];

/// The total of weight times length over the edges that were ranked.
double _length(LayeredGraph graph) {
  var total = 0.0;
  for (final edge in graph.edges) {
    if (edge.ranked) total += edge.weight * (edge.to.rank - edge.from.rank);
  }
  return total;
}

/// The same total with every node as high as its edges allow.
double _longestPathLength(LayeredGraph graph) {
  final rank = <int, int>{};
  int at(int node) => rank.putIfAbsent(node, () {
    var best = 0;
    for (final edge in graph.edges) {
      if (edge.ranked && edge.to.index == node) {
        best = math.max(best, at(edge.from.index) + edge.minlen);
      }
    }
    return best;
  });
  var total = 0.0;
  for (final edge in graph.edges) {
    if (!edge.ranked) continue;
    final length = at(edge.to.index) - at(edge.from.index);
    total += edge.weight * length;
  }
  return total;
}

/// The least total of weight times length over every ranking in 0..[top]
/// that honours the minimum lengths, by trying them all.
double _optimum(LayeredGraph graph, int top) {
  final count = graph.nodes.length;
  final edges = [
    for (final edge in graph.edges)
      if (edge.ranked) edge,
  ];
  final rank = List.filled(count, 0);
  var best = double.infinity;
  void place(int node) {
    if (node == count) {
      var total = 0.0;
      for (final edge in edges) {
        final length = rank[edge.to.index] - rank[edge.from.index];
        if (length < edge.minlen) return;
        total += edge.weight * length;
      }
      best = math.min(best, total);
      return;
    }
    for (var r = 0; r <= top; r++) {
      rank[node] = r;
      place(node + 1);
    }
  }

  place(0);
  return best;
}

/// Every edge the ranking honoured is at least its `minlen` long.
void _expectEdgesHold(LayeredGraph graph) {
  for (final edge in graph.edges) {
    if (!edge.ranked) continue;
    expect(
      edge.to.rank - edge.from.rank,
      greaterThanOrEqualTo(edge.minlen),
      reason: '${edge.fromId} > ${edge.toId}',
    );
  }
}

/// Every member of every cluster is inside its box, and every cluster
/// inside the box of the one it is in, strictly.
void _expectClustersHold(LayeredGraph graph) {
  for (final cluster in graph.clusters) {
    expect(cluster.minRank, lessThan(cluster.maxRank), reason: cluster.id);
    for (final node in cluster.nodes) {
      expect(node.rank, greaterThan(cluster.minRank), reason: node.id);
      expect(node.rank, lessThan(cluster.maxRank), reason: node.id);
    }
    for (final inner in cluster.clusters) {
      expect(inner.minRank, greaterThan(cluster.minRank), reason: inner.id);
      expect(inner.maxRank, lessThan(cluster.maxRank), reason: inner.id);
    }
  }
}

void main() {
  group('the graph', () {
    test('keeps ids apart and refuses a missing end or parent', () {
      final graph = LayeredGraph()
        ..addNode('a')
        ..addCluster('S');
      expect(() => graph.addNode('a'), throwsArgumentError);
      expect(() => graph.addNode('S'), throwsArgumentError);
      expect(() => graph.addCluster('a'), throwsArgumentError);
      expect(() => graph.addNode('b', parent: 'nope'), throwsArgumentError);
      expect(() => graph.addEdge('a', 'nope'), throwsArgumentError);
      expect(() => graph.addEdge('a', 'S', minlen: -1), throwsArgumentError);
      expect(() => graph.addEdge('a', 'S', weight: -1), throwsArgumentError);
    });

    test('keeps parallel edges and answers in and out without a scan', () {
      final graph = _graph(['a', 'b'], ['a>b', 'a>b', 'b>a']);
      final a = graph.node('a')!;
      final b = graph.node('b')!;
      expect(graph.outEdges(a), hasLength(2));
      expect(graph.inEdges(b), hasLength(2));
      expect(graph.inEdges(a).single.index, 2);
      graph.addEdge('b', 'b');
      expect(graph.outEdges(b), hasLength(2));
      expect(graph.edges.last.flow, LayeredEdgeFlow.loop);
    });

    test('reversing an edge to a cluster leaves from its bottom', () {
      final graph = LayeredGraph()
        ..addNode('a')
        ..addCluster('S');
      final edge = graph.addEdge('a', 'S');
      final s = graph.cluster('S')!;
      expect(edge.to, s.borderTop);
      graph.reverse(edge);
      expect(edge.from, s.borderBottom);
      expect(edge.to, graph.node('a'));
      expect(graph.outEdges(s.borderBottom), [edge]);
      graph.reverse(edge);
      expect(edge.to, s.borderTop);
      expect(edge.flow, LayeredEdgeFlow.forward);
    });
  });

  group('ranking', () {
    test('a chain ranks 0, 1, 2, ...', () {
      final graph = _graph(
        ['a', 'b', 'c', 'd', 'e'],
        ['a>b', 'b>c', 'c>d', 'd>e'],
      );
      rankLayered(graph);
      expect(_ranks(graph, ['a', 'b', 'c', 'd', 'e']), [0, 1, 2, 3, 4]);
    });

    test('an empty graph, and a node alone, rank', () {
      rankLayered(LayeredGraph());
      final graph = _graph(['a'], []);
      rankLayered(graph);
      expect(_rank(graph, 'a'), 0);
    });

    test('a cycle is ranked from the node written first', () {
      final graph = _graph(['a', 'b', 'c'], ['a>b', 'b>c', 'c>a']);
      rankLayered(graph);
      expect(_ranks(graph, ['a', 'b', 'c']), [0, 1, 2]);
      expect(graph.edges[2].reversed, isTrue);
      expect(graph.edges[2].fromId, 'c');
      final later = _graph(['b', 'c', 'a'], ['a>b', 'b>c', 'c>a']);
      rankLayered(later);
      expect(_ranks(later, ['b', 'c', 'a']), [0, 1, 2]);
      expect(later.edges[0].reversed, isTrue);
    });

    test('a self loop takes no part', () {
      final graph = _graph(['a', 'b'], ['a>a', 'a>b', 'b>b']);
      rankLayered(graph);
      expect(_ranks(graph, ['a', 'b']), [0, 1]);
      expect(graph.edges[0].flow, LayeredEdgeFlow.loop);
    });

    test('a source is pulled down next to its target', () {
      final graph = _graph(['a', 'b', 'c', 'x'], ['a>c', 'b>c', 'x>a']);
      rankLayered(graph);
      expect(_ranks(graph, ['x', 'a', 'c']), [0, 1, 2]);
      expect(_rank(graph, 'b'), _rank(graph, 'c') - 1);
    });

    test('network simplex beats longest path', () {
      // f and e are sources of a short branch into the end of a long chain.
      final graph = _graph(
        ['a', 'b', 'c', 'd', 'e', 'f'],
        ['a>b', 'b>c', 'c>d', 'e>d', 'f>e'],
      );
      rankLayered(graph);
      expect(_length(graph), 5);
      expect(_longestPathLength(graph), 6);
      expect(_ranks(graph, ['f', 'e', 'd']), [1, 2, 3]);
    });

    test('network simplex weighs the edges', () {
      final graph = _graph(
        ['a', 'b', 'c', 'd', 'z', 'm'],
        ['a>b', 'b>c', 'c>d', 'd>z', 'a>m'],
      )..addEdge('m', 'z', weight: 3);
      rankLayered(graph);
      expect(_rank(graph, 'm'), 3);
      expect(_length(graph), 10);
    });

    test('minlen is honoured', () {
      final graph = LayeredGraph()
        ..addNode('a')
        ..addNode('b')
        ..addNode('c')
        ..addEdge('a', 'b', minlen: 2)
        ..addEdge('b', 'c', minlen: 0);
      rankLayered(graph);
      expect(_ranks(graph, ['a', 'b', 'c']), [0, 2, 2]);
    });

    test('the same graph twice ranks the same', () {
      LayeredGraph build() {
        final graph = LayeredGraph()
          ..addCluster('S')
          ..addNode('a', parent: 'S')
          ..addNode('b', parent: 'S')
          ..addNode('c')
          ..addEdge('a', 'b')
          ..addEdge('b', 'c')
          ..addEdge('c', 'a');
        return graph;
      }

      List<int> run() {
        final graph = build();
        rankLayered(graph);
        return [for (final node in graph.nodes) node.rank];
      }

      expect(run(), run());
    });

    test('a graph in pieces is one', () {
      final graph = _graph(['a', 'b', 'c', 'd'], ['a>b', 'c>d']);
      rankLayered(graph);
      expect(_ranks(graph, ['a', 'b', 'c', 'd']), [0, 1, 0, 1]);
    });
  });

  group('clusters', () {
    test('two clusters joined by an edge stand one above the other', () {
      final graph = LayeredGraph()
        ..addCluster('A')
        ..addCluster('B')
        ..addNode('a1', parent: 'A')
        ..addNode('a2', parent: 'A')
        ..addNode('b1', parent: 'B')
        ..addNode('b2', parent: 'B')
        ..addEdge('a1', 'a2')
        ..addEdge('b1', 'b2')
        ..addEdge('a2', 'b1');
      rankLayered(graph);
      final a = graph.cluster('A')!;
      final b = graph.cluster('B')!;
      expect(a.maxRank, lessThan(b.minRank));
      expect(a.minRank, 0);
      _expectClustersHold(graph);
      _expectEdgesHold(graph);
    });

    test('clusters with no edge between them are not stacked', () {
      final graph = LayeredGraph()
        ..addCluster('A')
        ..addCluster('B')
        ..addNode('a1', parent: 'A')
        ..addNode('a2', parent: 'A')
        ..addNode('b1', parent: 'B')
        ..addNode('b2', parent: 'B')
        ..addEdge('a1', 'a2')
        ..addEdge('b1', 'b2');
      rankLayered(graph);
      expect(graph.cluster('A')!.minRank, graph.cluster('B')!.minRank);
      expect(graph.cluster('A')!.maxRank, graph.cluster('B')!.maxRank);
    });

    test('a source outside is pulled down to the cluster it feeds', () {
      // The case that put every box of a chart in one row.
      final graph = LayeredGraph()
        ..addCluster('S')
        ..addNode('a', parent: 'S')
        ..addNode('b', parent: 'S')
        ..addNode('c', parent: 'S')
        ..addNode('x')
        ..addNode('y')
        ..addEdge('x', 'y')
        ..addEdge('y', 'a')
        ..addEdge('a', 'b')
        ..addEdge('b', 'c')
        ..addNode('late')
        ..addEdge('late', 'c');
      rankLayered(graph);
      expect(_rank(graph, 'late'), _rank(graph, 'b'));
      _expectClustersHold(graph);
    });

    test('nested clusters are strictly inside their parent', () {
      final graph = LayeredGraph()
        ..addCluster('outer')
        ..addCluster('inner', parent: 'outer')
        ..addCluster('deep', parent: 'inner')
        ..addNode('a', parent: 'outer')
        ..addNode('b', parent: 'inner')
        ..addNode('c', parent: 'deep')
        ..addNode('d')
        ..addEdge('a', 'b')
        ..addEdge('b', 'c')
        ..addEdge('c', 'd');
      rankLayered(graph);
      _expectClustersHold(graph);
      _expectEdgesHold(graph);
      expect(_rank(graph, 'd'), greaterThan(graph.cluster('deep')!.maxRank));
    });

    test('an empty cluster has a box of its own', () {
      final graph = LayeredGraph()
        ..addCluster('empty')
        ..addNode('a')
        ..addEdge('a', 'empty');
      rankLayered(graph);
      final empty = graph.cluster('empty')!;
      expect(empty.minRank, greaterThan(_rank(graph, 'a')));
      expect(empty.maxRank, greaterThan(empty.minRank));
    });

    test('an edge to a cluster puts the whole cluster below its source', () {
      final graph = LayeredGraph()
        ..addCluster('S')
        ..addNode('in1', parent: 'S')
        ..addNode('in2', parent: 'S')
        ..addNode('x')
        ..addEdge('in1', 'in2')
        ..addEdge('x', 'S');
      rankLayered(graph);
      final s = graph.cluster('S')!;
      expect(_rank(graph, 'x'), lessThan(s.minRank));
      expect(graph.edges.last.to, s.borderTop);
      _expectClustersHold(graph);
    });

    test('an edge from a cluster puts the whole cluster above its target', () {
      final graph = LayeredGraph()
        ..addCluster('S')
        ..addNode('in1', parent: 'S')
        ..addNode('in2', parent: 'S')
        ..addNode('y')
        ..addEdge('in1', 'in2')
        ..addEdge('S', 'y');
      rankLayered(graph);
      final s = graph.cluster('S')!;
      expect(s.maxRank, lessThan(_rank(graph, 'y')));
      _expectClustersHold(graph);
    });

    test('an edge between a cluster and a node inside it is set aside', () {
      final graph = LayeredGraph()
        ..addCluster('S')
        ..addCluster('T', parent: 'S')
        ..addNode('a', parent: 'S')
        ..addNode('b', parent: 'T')
        ..addEdge('a', 'S')
        ..addEdge('S', 'b')
        ..addEdge('S', 'T')
        ..addEdge('S', 'S');
      rankLayered(graph);
      for (final edge in graph.edges) {
        expect(edge.flow, LayeredEdgeFlow.free, reason: edge.toString());
      }
      _expectClustersHold(graph);
    });

    test('a ring through a cluster is opened at the edge that names it', () {
      // b is in S, b > a, and a > S: a ring through S's top.
      final graph = LayeredGraph()
        ..addCluster('S')
        ..addNode('b', parent: 'S')
        ..addNode('a')
        ..addEdge('b', 'a')
        ..addEdge('a', 'S');
      rankLayered(graph);
      expect(graph.edges[1].clusterEnd, isTrue);
      expect(graph.edges[1].reversed, isTrue);
      _expectClustersHold(graph);
      _expectEdgesHold(graph);
    });

    test('rings that cannot be opened by turning are set aside', () {
      final graph = LayeredGraph()
        ..addCluster('S')
        ..addCluster('T')
        ..addNode('a', parent: 'S')
        ..addNode('b', parent: 'T')
        ..addEdge('S', 'T')
        ..addEdge('T', 'S')
        ..addEdge('a', 'b')
        ..addEdge('b', 'a');
      rankLayered(graph);
      _expectClustersHold(graph);
      _expectEdgesHold(graph);
    });
  });

  group('properties', () {
    test('a small graph gets a best ranking: brute force agrees', () {
      final random = math.Random(1);
      for (var round = 0; round < 120; round++) {
        final count = 2 + random.nextInt(4);
        final graph = LayeredGraph();
        for (var i = 0; i < count; i++) {
          graph.addNode('n$i');
        }
        for (var i = random.nextInt(count + 3); i > 0; i--) {
          graph.addEdge(
            'n${random.nextInt(count)}',
            'n${random.nextInt(count)}',
            minlen: random.nextInt(3),
            weight: 1.0 + random.nextInt(3),
          );
        }
        rankLayered(graph);
        _expectEdgesHold(graph);
        expect(
          _length(graph),
          _optimum(graph, 2 * count),
          reason: 'round $round',
        );
      }
    });

    test('a random graph is never longer than longest path', () {
      final random = math.Random(2);
      for (var round = 0; round < 150; round++) {
        final count = 2 + random.nextInt(30);
        final graph = LayeredGraph();
        for (var i = 0; i < count; i++) {
          graph.addNode('n$i');
        }
        for (var i = random.nextInt(2 * count); i > 0; i--) {
          graph.addEdge(
            'n${random.nextInt(count)}',
            'n${random.nextInt(count)}',
            minlen: random.nextInt(3),
            weight: 1.0 + random.nextInt(4),
          );
        }
        rankLayered(graph);
        _expectEdgesHold(graph);
        expect(
          _length(graph),
          lessThanOrEqualTo(_longestPathLength(graph)),
          reason: 'round $round',
        );
        expect(graph.nodes.map((n) => n.rank).reduce(math.min), 0);
      }
    });

    test('random cluster trees keep their members inside', () {
      final random = math.Random(3);
      for (var round = 0; round < 300; round++) {
        final graph = LayeredGraph();
        final clusters = 1 + random.nextInt(5);
        for (var i = 0; i < clusters; i++) {
          graph.addCluster(
            'c$i',
            parent: i > 0 && random.nextBool() ? 'c${random.nextInt(i)}' : null,
          );
        }
        final count = 1 + random.nextInt(14);
        for (var i = 0; i < count; i++) {
          graph.addNode(
            'n$i',
            parent: random.nextInt(4) == 0
                ? null
                : 'c${random.nextInt(clusters)}',
          );
        }
        String end() => random.nextInt(8) == 0
            ? 'c${random.nextInt(clusters)}'
            : 'n${random.nextInt(count)}';
        for (var i = random.nextInt(2 * count + 2); i > 0; i--) {
          graph.addEdge(
            end(),
            end(),
            minlen: random.nextInt(3),
            weight: 1.0 + random.nextInt(3),
          );
        }
        rankLayered(graph);
        _expectEdgesHold(graph);
        _expectClustersHold(graph);
        // The nesting graph is gone again.
        expect(graph.nodes.any((n) => n.kind.name == 'nestingRoot'), isFalse);
        expect(graph.edges.any((e) => e.nesting), isFalse);
      }
    });
  });
}
