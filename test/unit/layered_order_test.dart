// The second stage of the compound layered layout (#530): stand-ins for long
// edges, the sides of the clusters, and the order within each rank.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/layered_cluster.dart';
import 'package:niman/src/diagrams/layered_cross_count.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_layers.dart';
import 'package:niman/src/diagrams/layered_layout.dart';
import 'package:niman/src/diagrams/layered_node.dart';
import 'package:niman/src/diagrams/layered_normalize.dart';
import 'package:niman/src/diagrams/layered_segments.dart';

/// The nodes of each rank, left to right.
List<List<LayeredNode>> _ranks(LayeredGraph graph) {
  var last = 0;
  for (final node in graph.nodes) {
    last = math.max(last, node.rank);
  }
  final ranks = [for (var r = 0; r <= last; r++) <LayeredNode>[]];
  for (final node in graph.nodes) {
    ranks[node.rank].add(node);
  }
  for (final rank in ranks) {
    rank.sort((a, b) => a.order - b.order);
  }
  return ranks;
}

/// Whether [node] is [cluster] or inside it, at any depth.
bool _inside(LayeredNode node, LayeredCluster cluster) =>
    node.parent != null && node.parent!.isWithin(cluster);

/// Every rank is numbered from 0 without a gap, every cluster is one run
/// between its sides in each rank it spans, and sibling clusters keep their
/// sides from one rank to the next.
void _expectOrderHolds(LayeredGraph graph) {
  final ranks = _ranks(graph);
  for (final rank in ranks) {
    for (var i = 0; i < rank.length; i++) {
      expect(rank[i].order, i, reason: 'rank of ${rank[i]}');
    }
  }
  for (final cluster in graph.clusters) {
    for (var r = cluster.minRank; r <= cluster.maxRank; r++) {
      final nodes = ranks[r];
      final left = cluster.borderLeft[r - cluster.minRank];
      final right = cluster.borderRight[r - cluster.minRank];
      expect(left.rank, r);
      expect(left.parent, cluster);
      expect(right.parent, cluster);
      final first = nodes.indexOf(left);
      final last = nodes.indexOf(right);
      expect(first, lessThan(last), reason: '${cluster.id} in rank $r');
      for (var i = 0; i < nodes.length; i++) {
        expect(
          _inside(nodes[i], cluster),
          i >= first && i <= last,
          reason: '${nodes[i]} against ${cluster.id} in rank $r',
        );
      }
    }
  }
  for (final a in graph.clusters) {
    for (final b in graph.clusters) {
      if (a.index >= b.index || a.parent != b.parent) continue;
      int? side;
      for (
        var r = math.max(a.minRank, b.minRank);
        r <= math.min(a.maxRank, b.maxRank);
        r++
      ) {
        final left =
            a.borderLeft[r - a.minRank].order <
            b.borderLeft[r - b.minRank].order;
        final now = left ? 1 : -1;
        side ??= now;
        expect(now, side, reason: '${a.id} and ${b.id} swap in rank $r');
      }
    }
  }
  for (final cluster in graph.clusters) {
    for (final node in graph.nodes) {
      if (node.parent == null) continue;
      final parent = node.parent!;
      expect(
        node.rank,
        inInclusiveRange(parent.minRank, parent.maxRank),
        reason: '$node in ${parent.id}',
      );
    }
    expect(
      cluster.borderLeft,
      hasLength(cluster.maxRank - cluster.minRank + 1),
    );
  }
}

/// The weighted crossings of the order the nodes of [graph] have.
double _crossings(LayeredGraph graph) {
  final order = Int32List(graph.nodes.length);
  for (final node in graph.nodes) {
    order[node.index] = node.order;
  }
  return countCrossings(
    LayeredLayers.of(graph),
    LayeredSegments.of(graph),
    order,
  );
}

void main() {
  group('normalising', () {
    test('a long edge becomes a chain, one stand-in per rank between', () {
      final graph = LayeredGraph();
      ['a', 'b', 'c', 'd'].forEach(graph.addNode);
      graph
        ..addEdge('a', 'b')
        ..addEdge('b', 'c')
        ..addEdge('c', 'd');
      final long = graph.addEdge('a', 'd');
      layOutLayered(graph);
      expect(long.chain.map((n) => n.rank), [1, 2]);
      expect(
        long.chain.map((n) => n.kind),
        everyElement(LayeredNodeKind.dummy),
      );
      expect(long.chain.map((n) => n.chainIndex), [0, 1]);
      expect(long.chain.every((n) => n.edge == long), isTrue);
      expect(long.chain.every((n) => n.width == 0 && n.height == 0), isTrue);
      expect(graph.edges[0].chain, isEmpty);
      expect(long.labelNode, isNull);
    });

    test('a label gets a rank of its own, halfway', () {
      final graph = LayeredGraph()
        ..addNode('a')
        ..addNode('b');
      final edge = graph.addEdge('a', 'b', labelWidth: 30, labelHeight: 12);
      layOutLayered(graph);
      expect(graph.rankSpacing, 2);
      expect(edge.to.rank - edge.from.rank, 2);
      expect(edge.chain, hasLength(1));
      final label = edge.labelNode!;
      expect(label.kind, LayeredNodeKind.edgeLabel);
      expect((label.width, label.height), (30, 12));
      expect(label.rank, edge.labelRank);
      expect(label.rank, 1);
    });

    test('the label stand-in is at the middle of a long labelled edge', () {
      final graph = LayeredGraph();
      ['a', 'b', 'c', 'd'].forEach(graph.addNode);
      graph
        ..addEdge('a', 'b')
        ..addEdge('b', 'c')
        ..addEdge('c', 'd');
      final long = graph.addEdge('a', 'd', labelWidth: 20, labelHeight: 10);
      layOutLayered(graph);
      // Every edge is twice as long, so a to d is six ranks.
      expect(long.to.rank - long.from.rank, 6);
      expect(long.chain, hasLength(5));
      expect(long.labelRank, 3);
      expect(long.labelNode, long.chain[2]);
      expect(
        long.chain.where((n) => n.kind == LayeredNodeKind.edgeLabel),
        hasLength(1),
      );
    });

    test('a labelled edge with minlen 0 still has a rank for its label', () {
      final graph = LayeredGraph()
        ..addNode('a')
        ..addNode('b')
        ..addEdge('a', 'b', minlen: 0, labelWidth: 5, labelHeight: 5);
      layOutLayered(graph);
      final edge = graph.edges.single;
      expect(edge.to.rank - edge.from.rank, greaterThanOrEqualTo(2));
      expect(edge.chain, isNotEmpty);
    });

    test('a labelled edge that spans one rank is refused', () {
      final graph = LayeredGraph()
        ..addNode('a')
        ..addNode('b')
        ..addEdge('a', 'b', labelWidth: 5, labelHeight: 5);
      graph.nodes[0].rank = 0;
      graph.nodes[1].rank = 1;
      expect(() => normalizeEdges(graph), throwsStateError);
    });

    test('a reversed edge is cut in the direction it was ranked', () {
      final graph = LayeredGraph();
      ['a', 'b', 'c'].forEach(graph.addNode);
      graph
        ..addEdge('a', 'b')
        ..addEdge('b', 'c');
      final back = graph.addEdge('c', 'a');
      layOutLayered(graph);
      expect(back.reversed, isTrue);
      expect(back.from.id, 'a');
      expect(back.chain.map((n) => n.rank), [1]);
    });

    test('an edge inside a cluster keeps its stand-ins inside it', () {
      final graph = LayeredGraph()..addCluster('S');
      for (final id in ['a', 'b', 'c', 'd']) {
        graph.addNode(id, parent: 'S');
      }
      graph
        ..addEdge('a', 'b')
        ..addEdge('b', 'c')
        ..addEdge('c', 'd');
      final long = graph.addEdge('a', 'd');
      layOutLayered(graph);
      expect(long.chain, hasLength(2));
      expect(long.chain.map((n) => n.parent?.id), ['S', 'S']);
    });

    test("an edge leaving a cluster leaves it at the cluster's last rank", () {
      final graph = LayeredGraph()..addCluster('A');
      for (final id in ['a1', 'a2']) {
        graph.addNode(id, parent: 'A');
      }
      ['x1', 'x2', 'x3', 'x'].forEach(graph.addNode);
      graph
        ..addEdge('a1', 'a2')
        ..addEdge('a2', 'x1')
        ..addEdge('x1', 'x2')
        ..addEdge('x2', 'x3')
        ..addEdge('x3', 'x');
      final out = graph.addEdge('a1', 'x');
      layOutLayered(graph);
      final a = graph.cluster('A')!;
      expect(out.chain.length, greaterThan(2));
      for (final stand in out.chain) {
        expect(
          stand.parent,
          stand.rank <= a.maxRank ? a : isNull,
          reason: 'at rank ${stand.rank}, A ends at ${a.maxRank}',
        );
      }
      expect(out.chain.any((n) => n.parent == a), isTrue);
      expect(out.chain.any((n) => n.parent == null), isTrue);
    });

    test('an edge from one cluster to another goes down and up the tree', () {
      final graph = LayeredGraph()
        ..addCluster('A')
        ..addCluster('B')
        ..addNode('a1', parent: 'A')
        ..addNode('a2', parent: 'A')
        ..addNode('b1', parent: 'B')
        ..addNode('b2', parent: 'B')
        ..addNode('m1')
        ..addNode('m2')
        ..addEdge('a1', 'a2')
        ..addEdge('b1', 'b2')
        ..addEdge('a2', 'm1')
        ..addEdge('m1', 'm2')
        ..addEdge('m2', 'b1');
      final across = graph.addEdge('a1', 'b2');
      layOutLayered(graph);
      final a = graph.cluster('A')!;
      final b = graph.cluster('B')!;
      expect(across.chain, isNotEmpty);
      for (final stand in across.chain) {
        final expected = stand.rank <= a.maxRank
            ? a
            : stand.rank >= b.minRank
            ? b
            : null;
        expect(stand.parent, expected, reason: 'rank ${stand.rank}');
      }
    });

    test("a cluster-ended edge ends on the cluster's border", () {
      final graph = LayeredGraph()
        ..addCluster('S')
        ..addNode('in', parent: 'S')
        ..addNode('x')
        ..addNode('y')
        ..addEdge('x', 'y')
        ..addEdge('y', 'S')
        ..addEdge('x', 'S');
      layOutLayered(graph);
      final s = graph.cluster('S')!;
      final direct = graph.edges.last;
      expect(direct.to, s.borderTop);
      for (final stand in direct.chain) {
        expect(stand.parent, isNull);
      }
      _expectOrderHolds(graph);
    });
  });

  group('ordering', () {
    test('barycentre sweeps cut the crossing the walk down left', () {
      final graph = LayeredGraph();
      ['a', 'b', 'x', 'y', 'z'].forEach(graph.addNode);
      graph
        ..addEdge('a', 'x')
        ..addEdge('a', 'z')
        ..addEdge('b', 'x')
        ..addEdge('b', 'y');
      layOutLayered(graph);
      expect(_crossings(graph), 0);
      _expectOrderHolds(graph);
    });

    test('a K2,2 keeps its one crossing and nothing more', () {
      final graph = LayeredGraph();
      ['a', 'b', 'x', 'y'].forEach(graph.addNode);
      graph
        ..addEdge('a', 'x')
        ..addEdge('a', 'y')
        ..addEdge('b', 'x')
        ..addEdge('b', 'y');
      layOutLayered(graph);
      expect(_crossings(graph), 1);
    });

    test('a chain and a cycle have no crossings, one node a rank or two', () {
      final chain = LayeredGraph();
      for (var i = 0; i < 20; i++) {
        chain.addNode('n$i');
      }
      for (var i = 1; i < 20; i++) {
        chain.addEdge('n${i - 1}', 'n$i');
      }
      layOutLayered(chain);
      expect(_ranks(chain).every((r) => r.length == 1), isTrue);
      final cycle = LayeredGraph();
      for (var i = 0; i < 20; i++) {
        cycle.addNode('n$i');
      }
      for (var i = 1; i < 20; i++) {
        cycle.addEdge('n${i - 1}', 'n$i');
      }
      cycle.addEdge('n19', 'n0');
      layOutLayered(cycle);
      expect(_crossings(cycle), 0);
      expect(_ranks(cycle).every((r) => r.length <= 2), isTrue);
    });

    test('a cluster is one run between its sides, in every rank', () {
      final graph = LayeredGraph()
        ..addCluster('S')
        ..addCluster('T', parent: 'S');
      for (final id in ['a', 'b', 'c']) {
        graph.addNode(id, parent: 'S');
      }
      for (final id in ['t1', 't2']) {
        graph.addNode(id, parent: 'T');
      }
      ['x', 'y', 'z'].forEach(graph.addNode);
      graph
        ..addEdge('x', 'a')
        ..addEdge('x', 'y')
        ..addEdge('a', 'b')
        ..addEdge('a', 't1')
        ..addEdge('t1', 't2')
        ..addEdge('y', 'b')
        ..addEdge('b', 'c')
        ..addEdge('t2', 'c')
        ..addEdge('y', 'z')
        ..addEdge('z', 'c');
      layOutLayered(graph);
      _expectOrderHolds(graph);
    });

    test('sibling clusters do not swap sides between ranks', () {
      // Heavy edges across pull each cluster, rank by rank, towards the
      // other's side: sorted alone, rank 1 would put B left of A.
      final graph = LayeredGraph()
        ..addCluster('A')
        ..addCluster('B');
      for (var i = 0; i < 4; i++) {
        graph
          ..addNode('a$i', parent: 'A')
          ..addNode('b$i', parent: 'B');
      }
      graph.addNode('top');
      for (var i = 1; i < 4; i++) {
        graph
          ..addEdge('a${i - 1}', 'a$i')
          ..addEdge('b${i - 1}', 'b$i');
      }
      graph
        ..addEdge('top', 'a0')
        ..addEdge('top', 'b0')
        ..addEdge('b0', 'a1', weight: 40)
        ..addEdge('a0', 'b1', weight: 40)
        ..addEdge('b1', 'a2', weight: 40)
        ..addEdge('a1', 'b2', weight: 40)
        ..addEdge('b2', 'a3', weight: 40)
        ..addEdge('a2', 'b3', weight: 40);
      layOutLayered(graph);
      _expectOrderHolds(graph);
    });

    test('the same graph twice has the same order', () {
      List<int> run() {
        final graph = LayeredGraph()
          ..addCluster('S')
          ..addNode('a', parent: 'S')
          ..addNode('b', parent: 'S')
          ..addNode('c')
          ..addNode('d')
          ..addEdge('a', 'b')
          ..addEdge('b', 'c', labelWidth: 4, labelHeight: 4)
          ..addEdge('c', 'a')
          ..addEdge('a', 'd')
          ..addEdge('d', 'c');
        layOutLayered(graph);
        return [for (final n in graph.nodes) n.rank * 1000 + n.order];
      }

      expect(run(), run());
    });
  });

  group('crossing count', () {
    test('matches counting every pair of segments', () {
      final random = math.Random(11);
      for (var round = 0; round < 80; round++) {
        final graph = LayeredGraph();
        final north = 1 + random.nextInt(6);
        final south = 1 + random.nextInt(6);
        for (var i = 0; i < north; i++) {
          graph.addNode('n$i');
        }
        for (var i = 0; i < south; i++) {
          graph.addNode('s$i');
        }
        for (var i = 0; i < north; i++) {
          graph.nodes[i].rank = 0;
        }
        for (var i = 0; i < south; i++) {
          graph.nodes[north + i].rank = 1;
        }
        for (var i = random.nextInt(12); i > 0; i--) {
          graph.addEdge(
            'n${random.nextInt(north)}',
            's${random.nextInt(south)}',
            weight: 1.0 + random.nextInt(3),
          );
        }
        normalizeEdges(graph);
        final order = Int32List(north + south);
        final upper = [for (var i = 0; i < north; i++) i]..shuffle(random);
        final lower = [for (var i = 0; i < south; i++) i]..shuffle(random);
        for (var i = 0; i < north; i++) {
          order[i] = upper[i];
        }
        for (var i = 0; i < south; i++) {
          order[north + i] = lower[i];
        }
        var expected = 0.0;
        for (final a in graph.edges) {
          for (final b in graph.edges) {
            final left = order[a.from.index] - order[b.from.index];
            final right = order[a.to.index] - order[b.to.index];
            if (left < 0 && right > 0) expected += a.weight * b.weight;
          }
        }
        expect(
          countCrossings(
            LayeredLayers.of(graph),
            LayeredSegments.of(graph),
            order,
          ),
          expected,
          reason: 'round $round',
        );
      }
    });
  });

  group('properties', () {
    test('random clustered graphs keep their clusters whole', () {
      final random = math.Random(21);
      for (var round = 0; round < 300; round++) {
        final graph = LayeredGraph();
        final clusters = random.nextInt(5);
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
            parent: clusters == 0 || random.nextInt(3) == 0
                ? null
                : 'c${random.nextInt(clusters)}',
          );
        }
        String end() => clusters > 0 && random.nextInt(9) == 0
            ? 'c${random.nextInt(clusters)}'
            : 'n${random.nextInt(count)}';
        for (var i = random.nextInt(2 * count + 2); i > 0; i--) {
          final label = random.nextInt(5) == 0;
          graph.addEdge(
            end(),
            end(),
            minlen: random.nextInt(3),
            weight: 1.0 + random.nextInt(3),
            labelWidth: label ? 10 : 0,
            labelHeight: label ? 6 : 0,
          );
        }
        layOutLayered(graph);
        _expectOrderHolds(graph);
        for (final edge in graph.edges) {
          if (!edge.ranked) continue;
          expect(
            edge.chain.length,
            math.max(0, edge.to.rank - edge.from.rank - 1),
          );
          for (var i = 0; i < edge.chain.length; i++) {
            expect(edge.chain[i].rank, edge.from.rank + 1 + i);
          }
          if (edge.hasLabel) {
            expect(edge.labelNode, isNotNull);
            expect(
              edge.labelNode!.rank,
              inExclusiveRange(edge.from.rank, edge.to.rank),
            );
          }
        }
      }
    });
  });
}
