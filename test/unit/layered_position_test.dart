// The last stage of the compound layered layout (#530): where the nodes are,
// the clusters' boxes, the edges' points. Canonical space: ranks run down,
// the order runs right.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/layered_box.dart';
import 'package:niman/src/diagrams/layered_cluster.dart';
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_layout.dart';
import 'package:niman/src/diagrams/layered_node.dart';
import 'package:niman/src/diagrams/layered_options.dart';

const double _eps = 1e-6;

/// Whether [node] is [cluster] or inside it, at any depth.
bool _inside(LayeredNode node, LayeredCluster cluster) =>
    node.parent != null && node.parent!.isWithin(cluster);

/// The real nodes of [graph].
Iterable<LayeredNode> _boxes(LayeredGraph graph) =>
    graph.nodes.where((n) => n.kind == LayeredNodeKind.real);

/// A graph of boxes 40 by 20 named [ids], joined by the edges `a>b`.
LayeredGraph _graph(List<String> ids, List<String> edges) {
  final graph = LayeredGraph();
  for (final id in ids) {
    graph.addNode(id, width: 40, height: 20);
  }
  for (final edge in edges) {
    final [from, to] = edge.split('>');
    graph.addEdge(from, to);
  }
  return graph;
}

/// No two boxes of a rank overlap, and each has the node gap to the next.
void _expectBoxesApart(LayeredGraph graph, LayeredOptions options) {
  final boxes = _boxes(graph).toList();
  for (final a in boxes) {
    for (final b in boxes) {
      if (a.index >= b.index || a.rank != b.rank) continue;
      final apart = (a.x - b.x).abs() - (a.width + b.width) / 2;
      expect(
        apart,
        greaterThanOrEqualTo(options.nodeGap - _eps),
        reason: '${a.id} and ${b.id} in rank ${a.rank}',
      );
    }
  }
}

/// Every box is inside the box of every cluster it is in, by its pads.
void _expectInsideClusters(LayeredGraph graph) {
  for (final node in _boxes(graph)) {
    for (var outer = node.parent; outer != null; outer = outer.parent) {
      final c = outer;
      final box = c.box;
      String reason(String side) => '${node.id} against $side of ${c.id}';
      expect(
        node.x - node.width / 2,
        greaterThanOrEqualTo(box.left + c.padLeft - _eps),
        reason: reason('the left'),
      );
      expect(
        node.x + node.width / 2,
        lessThanOrEqualTo(box.right - c.padRight + _eps),
        reason: reason('the right'),
      );
      expect(
        node.y - node.height / 2,
        greaterThanOrEqualTo(box.top + c.padTop - _eps),
        reason: reason('the top'),
      );
      expect(
        node.y + node.height / 2,
        lessThanOrEqualTo(box.bottom - c.padBottom + _eps),
        reason: reason('the bottom'),
      );
    }
  }
}

bool _intersect(LayeredBox a, LayeredBox b) =>
    a.left < b.right - _eps &&
    b.left < a.right - _eps &&
    a.top < b.bottom - _eps &&
    b.top < a.bottom - _eps;

/// Clusters do not intersect unless one is inside the other, and a cluster
/// is inside its parent by the parent's pads; clusters side by side in a rank
/// are a node gap apart there.
void _expectClustersApart(LayeredGraph graph, LayeredOptions options) {
  for (final a in graph.clusters) {
    final parent = a.parent;
    if (parent != null) {
      expect(
        a.box.left,
        greaterThanOrEqualTo(parent.box.left + parent.padLeft - _eps),
      );
      expect(
        a.box.right,
        lessThanOrEqualTo(parent.box.right - parent.padRight + _eps),
      );
      expect(
        a.box.top,
        greaterThanOrEqualTo(parent.box.top + parent.padTop - _eps),
      );
      expect(
        a.box.bottom,
        lessThanOrEqualTo(parent.box.bottom - parent.padBottom + _eps),
      );
    }
    for (final b in graph.clusters) {
      if (a.index >= b.index) continue;
      if (a.isWithin(b) || b.isWithin(a)) continue;
      expect(_intersect(a.box, b.box), isFalse, reason: '${a.id} and ${b.id}');
      if (a.parent != b.parent) continue;
      for (
        var r = math.max(a.minRank, b.minRank);
        r <= math.min(a.maxRank, b.maxRank);
        r++
      ) {
        final left = a.borderLeft[r - a.minRank];
        final other = b.borderLeft[r - b.minRank];
        final (first, second) = left.x < other.x ? (a, b) : (b, a);
        final gap =
            second.borderLeft[r - second.minRank].x -
            first.borderRight[r - first.minRank].x;
        expect(
          gap,
          greaterThanOrEqualTo(options.nodeGap - _eps),
          reason: '${a.id} and ${b.id} in rank $r',
        );
      }
    }
  }
}

/// A box or a stand-in is not inside the box of a cluster it is not in.
void _expectOutsideOthers(LayeredGraph graph) {
  for (final node in graph.nodes) {
    if (node.kind != LayeredNodeKind.real &&
        node.kind != LayeredNodeKind.dummy &&
        node.kind != LayeredNodeKind.edgeLabel) {
      continue;
    }
    for (final cluster in graph.clusters) {
      if (_inside(node, cluster)) continue;
      final box = cluster.box;
      final strictlyIn =
          node.x > box.left + _eps &&
          node.x < box.right - _eps &&
          node.y > box.top + _eps &&
          node.y < box.bottom - _eps;
      expect(strictlyIn, isFalse, reason: '$node in ${cluster.id}');
    }
  }
}

/// The edge points run the way the caller drew the edge.
void _expectPointsRun(LayeredGraph graph) {
  for (final edge in graph.edges) {
    final span = edge.to.rank - edge.from.rank;
    if (!edge.ranked || span < 1) {
      expect(edge.points, isEmpty, reason: edge.toString());
      continue;
    }
    expect(edge.points, hasLength(span + 1));
    for (var i = 1; i < edge.points.length; i++) {
      if (edge.reversed) {
        expect(edge.points[i].y, lessThan(edge.points[i - 1].y));
      } else {
        expect(edge.points[i].y, greaterThan(edge.points[i - 1].y));
      }
    }
  }
}

void main() {
  group('a straight picture', () {
    test('a chain of equal boxes is one vertical line', () {
      final graph = _graph(['a', 'b', 'c', 'd'], ['a>b', 'b>c', 'c>d']);
      layOutLayered(graph);
      final xs = graph.nodes.map((n) => n.x).toSet();
      expect(xs, hasLength(1));
      final ys = [for (final n in graph.nodes) n.y];
      expect(ys, orderedEquals([...ys]..sort()));
      // 20 high boxes, 50 between.
      expect(graph.node('b')!.y - graph.node('a')!.y, 70);
    });

    test('a node with two equal children sits between them', () {
      final graph = _graph(['a', 'b', 'c'], ['a>b', 'a>c']);
      layOutLayered(graph);
      final a = graph.node('a')!;
      final b = graph.node('b')!;
      final c = graph.node('c')!;
      expect(b.x, lessThan(c.x));
      expect(a.x, closeTo((b.x + c.x) / 2, _eps));
      expect(c.x - b.x, closeTo(40 + 50, _eps));
    });

    test('a long edge runs straight beside the boxes it passes', () {
      final graph = _graph(['a', 'b', 'c', 'd'], ['a>b', 'b>c', 'c>d']);
      final long = graph.addEdge('a', 'd');
      layOutLayered(graph);
      expect(long.points, hasLength(4));
      expect(long.points[1].x, closeTo(long.points[2].x, _eps));
      final b = graph.node('b')!;
      expect(
        (long.points[1].x - b.x).abs(),
        greaterThanOrEqualTo(20 + 20 - _eps),
      );
    });
  });

  group('edges', () {
    test('points run down, and a reversed edge is flipped back', () {
      final graph = _graph(['a', 'b', 'c'], ['a>b', 'b>c', 'c>a']);
      layOutLayered(graph);
      _expectPointsRun(graph);
      final back = graph.edges[2];
      expect(back.reversed, isTrue);
      expect(back.points.first.y, greaterThan(back.points.last.y));
      expect(back.points.first.x, graph.node('c')!.x);
      expect(back.points.last.y, graph.node('a')!.y);
    });

    test('a self loop, a flat edge and a free edge have no points', () {
      final graph = LayeredGraph()
        ..addNode('a', width: 40, height: 20)
        ..addNode('b', width: 40, height: 20)
        ..addCluster('S')
        ..addNode('in', width: 40, height: 20, parent: 'S')
        ..addEdge('a', 'a')
        ..addEdge('a', 'b', minlen: 0)
        ..addEdge('S', 'in');
      layOutLayered(graph);
      for (final edge in graph.edges) {
        expect(edge.points, isEmpty, reason: edge.toString());
      }
    });

    test('a label sits at its rank, between the ends', () {
      final graph = LayeredGraph()
        ..addNode('a', width: 40, height: 20)
        ..addNode('b', width: 40, height: 20);
      final edge = graph.addEdge('a', 'b', labelWidth: 60, labelHeight: 30);
      final bounds = layOutLayered(graph);
      final label = edge.labelNode!;
      expect(edge.labelCenter, (x: label.x, y: label.y));
      expect(label.y, inExclusiveRange(graph.node('a')!.y, graph.node('b')!.y));
      expect(edge.points[1], edge.labelCenter);
      // The label's row is 30 high and the gaps are half of 50 each way.
      expect(
        graph.node('b')!.y - graph.node('a')!.y,
        closeTo(10 + 25 + 30 + 25 + 10, _eps),
      );
      expect(bounds.left, lessThanOrEqualTo(label.x - 30 + _eps));
    });

    test('two opposite edges between neighbours run side by side', () {
      // One edge has the joins of the alignment and the other would be left
      // to the nearest constraint, out at the side of a cluster that a wide
      // box in another rank made broad.
      final graph = LayeredGraph()
        ..addCluster('E', padTop: 20, padBottom: 6, padLeft: 8, padRight: 8)
        ..addNode('c', width: 150, height: 33, parent: 'E')
        ..addNode('a', width: 233, height: 33, parent: 'E')
        ..addNode('b', width: 212, height: 33, parent: 'E')
        ..addEdge('c', 'a')
        ..addEdge('a', 'b');
      final back = graph.addEdge('b', 'a', labelWidth: 100, labelHeight: 20);
      const options = LayeredOptions(rankGap: 60, nodeGap: 40);
      layOutLayered(graph, options);
      final forward = graph.edges[1];
      final label = back.labelNode!;
      final stand = forward.chain.single;
      expect(stand.rank, label.rank);
      expect(
        (stand.x - label.x).abs() - label.width / 2,
        closeTo(options.edgeGap, _eps),
      );
      final box = graph.cluster('E')!.box;
      for (final x in [stand.x, label.x - 50, label.x + 50]) {
        expect(x, inInclusiveRange(box.left + 8, box.right - 8));
      }
    });

    test('an edge without a label has no label centre', () {
      final graph = _graph(['a', 'b'], ['a>b']);
      layOutLayered(graph);
      expect(graph.edges.single.labelCenter, isNull);
    });

    test('the gap between ranks honours the rooms at both ends', () {
      LayeredGraph build({
        double tail = 0,
        double head = 0,
        bool back = false,
      }) {
        final graph = LayeredGraph()
          ..addNode('a', width: 40, height: 20)
          ..addNode('b', width: 40, height: 20)
          ..addEdge(
            back ? 'b' : 'a',
            back ? 'a' : 'b',
            tailRoom: tail,
            headRoom: head,
          );
        // A forward edge the other way, so the first one is the one reversed.
        if (back) graph.addEdge('a', 'b');
        layOutLayered(graph, const LayeredOptions(rankGap: 10));
        return graph;
      }

      double gap(LayeredGraph g) => g.node('b')!.y - 10 - (g.node('a')!.y + 10);
      expect(gap(build()), closeTo(10, _eps));
      expect(gap(build(tail: 30, head: 20)), closeTo(50, _eps));
      // a > b is drawn a above b, so its tail room is above and head below.
      expect(gap(build(tail: 3, head: 4)), closeTo(10, _eps));
      // For the edge b > a, reversed, the head is on the upper end.
      final reversed = build(tail: 30, head: 20, back: true);
      expect(reversed.edges.first.reversed, isTrue);
      expect(gap(reversed), closeTo(50, _eps));
    });
  });

  group('clusters', () {
    test('two clusters joined by an edge: the first is wholly above', () {
      final graph = LayeredGraph()
        ..addCluster('A', padTop: 20, padBottom: 8, padLeft: 8, padRight: 8)
        ..addCluster('B', padTop: 20, padBottom: 8, padLeft: 8, padRight: 8);
      for (final id in ['a1', 'a2']) {
        graph.addNode(id, width: 40, height: 20, parent: 'A');
      }
      for (final id in ['b1', 'b2']) {
        graph.addNode(id, width: 40, height: 20, parent: 'B');
      }
      graph
        ..addEdge('a1', 'a2')
        ..addEdge('b1', 'b2')
        ..addEdge('a2', 'b1');
      layOutLayered(graph);
      final a = graph.cluster('A')!.box;
      final b = graph.cluster('B')!.box;
      expect(a.bottom, lessThan(b.top));
      // The outline is the pad from what the cluster holds: no more.
      final a1 = graph.node('a1')!;
      expect(a1.y - 10 - a.top, closeTo(20, _eps));
      final a2 = graph.node('a2')!;
      expect(a.bottom - (a2.y + 10), closeTo(8, _eps));
      expect(a1.x - 20 - a.left, closeTo(8, _eps));
      _expectClustersApart(graph, const LayeredOptions());
      _expectInsideClusters(graph);
    });

    test("a nested cluster is inside its parent by the parent's pads", () {
      final graph = LayeredGraph()
        ..addCluster(
          'outer',
          padTop: 24,
          padBottom: 6,
          padLeft: 10,
          padRight: 12,
        )
        ..addCluster(
          'inner',
          parent: 'outer',
          padTop: 18,
          padBottom: 5,
          padLeft: 7,
          padRight: 7,
        )
        ..addNode('a', width: 40, height: 20, parent: 'outer')
        ..addNode('b', width: 40, height: 20, parent: 'inner')
        ..addNode('c', width: 40, height: 20, parent: 'outer')
        ..addEdge('a', 'b')
        ..addEdge('b', 'c');
      layOutLayered(graph);
      _expectClustersApart(graph, const LayeredOptions());
      _expectInsideClusters(graph);
      final outer = graph.cluster('outer')!.box;
      final inner = graph.cluster('inner')!.box;
      expect(inner.top - outer.top, greaterThanOrEqualTo(24 - _eps));
      expect(outer.bottom - inner.bottom, greaterThanOrEqualTo(6 - _eps));
    });

    test('an edge to a cluster ends on its outline', () {
      final graph = LayeredGraph()
        ..addCluster('S', padTop: 16, padBottom: 6)
        ..addNode('in', width: 40, height: 20, parent: 'S')
        ..addNode('x', width: 40, height: 20)
        ..addNode('y', width: 40, height: 20)
        ..addEdge('x', 'S')
        ..addEdge('S', 'y');
      layOutLayered(graph);
      final box = graph.cluster('S')!.box;
      final into = graph.edges[0];
      final out = graph.edges[1];
      expect(into.points.last.y, closeTo(box.top, _eps));
      expect(out.points.first.y, closeTo(box.bottom, _eps));
      expect(into.points.first.y, graph.node('x')!.y);
      expect(out.points.last.y, graph.node('y')!.y);
    });

    test('edges that name clusters do not stretch them', () {
      // A graph found by search, in which the edges that end at a cluster's
      // top or bottom dragged those border nodes out towards their far
      // ends and the cluster's side with them: 1223 wide, now 440.
      final random = math.Random(222);
      final graph = LayeredGraph();
      final clusters = 2 + random.nextInt(3);
      for (var c = 0; c < clusters; c++) {
        graph.addCluster(
          'c$c',
          padTop: 10,
          padBottom: 6,
          padLeft: 8,
          padRight: 8,
        );
      }
      final count = 6 + random.nextInt(10);
      for (var i = 0; i < count; i++) {
        graph.addNode(
          'n$i',
          width: 50.0 + random.nextInt(150),
          height: 20,
          parent: random.nextInt(4) == 0
              ? null
              : 'c${random.nextInt(clusters)}',
        );
      }
      String end() => random.nextInt(6) == 0
          ? 'c${random.nextInt(clusters)}'
          : 'n${random.nextInt(count)}';
      for (var i = 0; i < count + 4; i++) {
        graph.addEdge(end(), end());
      }
      layOutLayered(graph);
      for (final cluster in graph.clusters) {
        expect(cluster.box.width, lessThan(600), reason: cluster.id);
      }
      // An end on a cluster is on its outline, inside its pads.
      for (final edge in graph.edges.where((e) => e.clusterEnd)) {
        if (edge.points.isEmpty) continue;
        for (final (id, point) in [
          (edge.fromId, edge.points.first),
          (edge.toId, edge.points.last),
        ]) {
          final cluster = graph.cluster(id);
          if (cluster == null) continue;
          expect(
            point.x,
            inInclusiveRange(cluster.box.left + 8, cluster.box.right - 8),
          );
          expect([
            cluster.box.top,
            cluster.box.bottom,
          ], contains(closeTo(point.y, _eps)));
        }
      }
    });

    test('an edge to a cluster arrives straight where the box allows', () {
      final graph = LayeredGraph()
        ..addCluster('S', padTop: 16, padLeft: 8, padRight: 8)
        ..addNode('a', width: 150, height: 20, parent: 'S')
        ..addNode('x', width: 40, height: 20)
        ..addEdge('x', 'S');
      layOutLayered(graph);
      final end = graph.edges.single.points.last;
      expect(end.x, closeTo(graph.node('x')!.x, _eps));
    });

    test('empty ranks that hold no box add no tall band', () {
      // A long edge down the side of a chain: no rank is empty of boxes, but
      // a cluster's own top and bottom ranks hold only its border nodes.
      final withBorders = LayeredGraph()
        ..addCluster('S', padTop: 10, padBottom: 10)
        ..addNode('a', width: 40, height: 20, parent: 'S')
        ..addNode('b', width: 40, height: 20, parent: 'S')
        ..addEdge('a', 'b');
      layOutLayered(withBorders);
      final box = withBorders.cluster('S')!.box;
      // Pad, box, 50 between, box, pad: nothing from the border ranks.
      expect(box.height, closeTo(10 + 20 + 50 + 20 + 10, _eps));
    });
  });

  group('the whole', () {
    test('the bounds hold every box, cluster and label', () {
      final graph = LayeredGraph()
        ..addCluster('S', padTop: 20, padBottom: 8, padLeft: 8, padRight: 8)
        ..addNode('a', width: 40, height: 20, parent: 'S')
        ..addNode('b', width: 70, height: 20)
        ..addEdge('a', 'b', labelWidth: 200, labelHeight: 14);
      final bounds = layOutLayered(graph);
      for (final node in _boxes(graph)) {
        expect(bounds.left, lessThanOrEqualTo(node.x - node.width / 2 + _eps));
        expect(
          bounds.right,
          greaterThanOrEqualTo(node.x + node.width / 2 - _eps),
        );
        expect(bounds.top, lessThanOrEqualTo(node.y - node.height / 2 + _eps));
        expect(
          bounds.bottom,
          greaterThanOrEqualTo(node.y + node.height / 2 - _eps),
        );
      }
      final box = graph.cluster('S')!.box;
      expect(bounds.top, closeTo(box.top, _eps));
      expect(layOutLayered(LayeredGraph()), LayeredBox.zero);
    });

    test('the same graph twice is placed the same', () {
      List<double> run() {
        final graph = LayeredGraph()
          ..addCluster('S', padTop: 12, padLeft: 6, padRight: 6, padBottom: 6)
          ..addNode('a', width: 30, height: 20, parent: 'S')
          ..addNode('b', width: 50, height: 20, parent: 'S')
          ..addNode('c', width: 40, height: 30)
          ..addNode('d', width: 40, height: 30)
          ..addEdge('a', 'b')
          ..addEdge('b', 'c', labelWidth: 10, labelHeight: 10)
          ..addEdge('c', 'a')
          ..addEdge('a', 'd')
          ..addEdge('d', 'c');
        layOutLayered(graph);
        return [
          for (final n in graph.nodes) ...[n.x, n.y],
        ];
      }

      expect(run(), run());
    });

    test('random clustered graphs keep their boxes apart and inside', () {
      final random = math.Random(31);
      for (var round = 0; round < 300; round++) {
        final graph = LayeredGraph();
        final clusters = random.nextInt(5);
        double pad() => random.nextInt(4) == 0 ? 0 : 4.0 + random.nextInt(12);
        for (var i = 0; i < clusters; i++) {
          graph.addCluster(
            'c$i',
            parent: i > 0 && random.nextBool() ? 'c${random.nextInt(i)}' : null,
            padTop: pad(),
            padBottom: pad(),
            padLeft: pad(),
            padRight: pad(),
          );
        }
        final count = 1 + random.nextInt(14);
        for (var i = 0; i < count; i++) {
          graph.addNode(
            'n$i',
            width: 20.0 + random.nextInt(60),
            height: 10.0 + random.nextInt(30),
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
            labelWidth: label ? 10 + random.nextInt(40).toDouble() : 0,
            labelHeight: label ? 6 + random.nextInt(10).toDouble() : 0,
            tailRoom: random.nextInt(3) == 0 ? 12 : 0,
            headRoom: random.nextInt(3) == 0 ? 9 : 0,
          );
        }
        final options = LayeredOptions(
          rankGap: 20.0 + random.nextInt(40),
          nodeGap: 10.0 + random.nextInt(30),
          edgeGap: 4.0 + random.nextInt(10),
        );
        layOutLayered(graph, options);
        _expectBoxesApart(graph, options);
        _expectInsideClusters(graph);
        _expectClustersApart(graph, options);
        _expectOutsideOthers(graph);
        _expectPointsRun(graph);
      }
    });
  });
}
