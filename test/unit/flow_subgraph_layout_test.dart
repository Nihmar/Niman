// Subgraphs laid out on the compound layered layout (#530): boxes that stack
// by the edges between them, never meet, and hold what they hold; labels
// that sit on their edges; an edge that names a subgraph ending on its
// outline.
//
// The two fixtures are charts from real notes. For the pipeline one, the
// reference render (mermaid.live) puts the subgraphs one under another —
// the console S6 on top, then S1, S3, S4 and S5 down the page — where the
// old layout put them all in one row. The tests read geometry, never pixels.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flowchart_layout.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/state_parser.dart';
import 'package:path/path.dart' as p;

const DiagramStyle _style = DiagramStyle();

Flowchart _parse(String source) =>
    (parseMermaid(source) as MermaidFlowchart).chart;

DiagramLayout _layout(String source) => layoutFlowchart(_parse(source), _style);

Flowchart _fixture(String name) => _parse(
  File(p.join('test', 'fixtures', 'mermaid', name)).readAsStringSync(),
);

Map<String, Rect> _boxes(DiagramLayout layout) => {
  for (final sub in layout.subgraphs) sub.subgraph.id: sub.rect,
};

/// The ids of the nodes each subgraph holds, those of the subgraphs written
/// inside it included.
Map<String, Set<String>> _held(Flowchart chart) {
  final held = <String, Set<String>>{};
  // The chart lists a subgraph after those inside it.
  for (final sub in chart.subgraphs) {
    final own = (held[sub.id] ??= {})..addAll(sub.nodeIds);
    final parent = sub.parent;
    if (parent != null) (held[parent] ??= {}).addAll(own);
  }
  return held;
}

bool _nested(Flowchart chart, String inner, String outer) {
  final parents = {for (final sub in chart.subgraphs) sub.id: sub.parent};
  for (String? at = inner; at != null; at = parents[at]) {
    if (at == outer) return true;
  }
  return false;
}

/// How far [point] is from the curve of [edge], sampled finely.
double _distance(LaidOutEdge edge, Offset point) {
  final pieces = (edge.path.length - 1) ~/ 3;
  final steps = pieces * 40;
  var best = double.infinity;
  var last = edge.at(0);
  for (var i = 1; i <= steps; i++) {
    final next = edge.at(i / steps);
    best = math.min(best, _toSegment(point, last, next));
    last = next;
  }
  return best;
}

double _toSegment(Offset point, Offset a, Offset b) {
  final ab = b - a;
  final length = ab.distanceSquared;
  final t = length == 0
      ? 0.0
      : (((point - a).dx * ab.dx + (point - a).dy * ab.dy) / length).clamp(
          0.0,
          1.0,
        );
  return (point - (a + ab * t)).distance;
}

void _holdsTogether(Flowchart chart, DiagramLayout layout) {
  final boxes = _boxes(layout);
  expect(boxes.keys, containsAll([for (final sub in chart.subgraphs) sub.id]));
  // No two boxes meet unless one is inside the other.
  final ids = boxes.keys.toList();
  for (var i = 0; i < ids.length; i++) {
    for (var j = i + 1; j < ids.length; j++) {
      if (_nested(chart, ids[i], ids[j]) || _nested(chart, ids[j], ids[i])) {
        continue;
      }
      expect(
        boxes[ids[i]]!.overlaps(boxes[ids[j]]!),
        isFalse,
        reason: '${ids[i]} and ${ids[j]}',
      );
    }
  }
  // Every node is inside every box that holds it.
  final held = _held(chart);
  for (final MapEntry(key: id, value: nodes) in held.entries) {
    for (final node in nodes) {
      final rect = layout.nodeOf(node)!.rect;
      expect(
        boxes[id]!.inflate(0.01).contains(rect.topLeft) &&
            boxes[id]!.inflate(0.01).contains(rect.bottomRight),
        isTrue,
        reason: '$node in $id',
      );
    }
  }
  // Every label sits on its edge.
  for (final edge in layout.edges) {
    final box = edge.labelBox;
    if (box == null) continue;
    expect(
      _distance(edge, box.center),
      lessThan(1.5),
      reason: '${edge.edge.from} -> ${edge.edge.to}: ${edge.label}',
    );
  }
}

void main() {
  group('the pipeline of subgraphs', () {
    final chart = _fixture('subgraph-pipeline.mmd');
    final layout = layoutFlowchart(chart, _style);
    final box = _boxes(layout);

    test('no boxes meet, each holds its nodes, labels are on their edges', () {
      _holdsTogether(chart, layout);
    });

    test('the console is on top and the others follow, one under another', () {
      for (final id in ['S1', 'S2', 'S3', 'S4', 'S5']) {
        expect(box['S6']!.top, lessThan(box[id]!.top), reason: id);
      }
      expect(box['S1']!.top, lessThan(box['S3']!.top));
      expect(box['S3']!.top, lessThan(box['S4']!.top));
      expect(box['S4']!.top, lessThan(box['S5']!.top));
    });

    test('the legend lays its unconnected nodes out in a column', () {
      // It declares direction LR and nothing joins it to the rest: in an LR
      // layout unconnected nodes share the first rank, which is a column.
      final nodes = [
        for (final id in ['L1', 'L2', 'L3', 'L4']) layout.nodeOf(id)!.rect,
      ];
      for (final rect in nodes) {
        expect(rect.center.dx, moreOrLessEquals(nodes.first.center.dx));
      }
      for (var i = 1; i < nodes.length; i++) {
        expect(nodes[i].top, greaterThanOrEqualTo(nodes[i - 1].bottom));
      }
    });

    test('the subgraphs are not all in the first band', () {
      for (final id in ['S3', 'S4', 'S5']) {
        expect(box[id]!.top, greaterThan(box['S1']!.bottom), reason: id);
      }
    });
  });

  group('the nested services', () {
    final chart = _fixture('nested-services.mmd');
    final layout = layoutFlowchart(chart, _style);

    test('no boxes meet, each holds its nodes, labels are on their edges', () {
      _holdsTogether(chart, layout);
    });

    test(
      'a subgraph is inside the one it is written in, title band and all',
      () {
        final box = _boxes(layout);
        for (final id in ['SYNC', 'ASYNC']) {
          expect(box['CORE']!.contains(box[id]!.topLeft), isTrue, reason: id);
          expect(box['CORE']!.contains(box[id]!.bottomRight), isTrue);
          expect(box[id]!.top, greaterThan(box['CORE']!.top));
        }
      },
    );
  });

  group("a subgraph's own direction", () {
    List<Rect> chain(DiagramLayout layout, List<String> ids) => [
      for (final id in ids) layout.nodeOf(id)!.rect,
    ];

    void sameRow(List<Rect> rects) {
      for (final r in rects) {
        expect(r.center.dy, moreOrLessEquals(rects.first.center.dy));
      }
    }

    void sameColumn(List<Rect> rects) {
      for (final r in rects) {
        expect(r.center.dx, moreOrLessEquals(rects.first.center.dx));
      }
    }

    test('an isolated subgraph in a top-down chart runs left to right', () {
      final layout = _layout(
        'flowchart TB\na --> b --> c\n'
        'subgraph L\ndirection LR\nl1 --> l2 --> l3\nend',
      );
      final l = chain(layout, ['l1', 'l2', 'l3']);
      sameRow(l);
      expect(l[0].right, lessThan(l[1].left));
      expect(l[1].right, lessThan(l[2].left));
      final box = _boxes(layout)['L']!;
      for (final rect in l) {
        expect(box.contains(rect.topLeft), isTrue);
        expect(box.contains(rect.bottomRight), isTrue);
      }
      for (final id in ['a', 'b', 'c']) {
        expect(box.overlaps(layout.nodeOf(id)!.rect), isFalse, reason: id);
      }
      // The chain's edges run between its nodes, and the drawing is whole.
      expect(layout.edges, hasLength(4));
      expect(layout.nodes.map((n) => n.node.id), [
        'a',
        'b',
        'c',
        'l1',
        'l2',
        'l3',
      ]);
      for (final edge in layout.edges.skip(2)) {
        expect(edge.start.dy, moreOrLessEquals(l.first.center.dy));
        expect(edge.end.dy, moreOrLessEquals(l.first.center.dy));
        expect(box.contains(edge.start), isTrue);
        expect(box.contains(edge.end), isTrue);
      }
      expect(layout.size.width, greaterThanOrEqualTo(box.right));
      expect(layout.size.height, greaterThanOrEqualTo(box.bottom));
    });

    test('an edge across its border makes it ignore its direction', () {
      final layout = _layout(
        'flowchart TB\na --> b --> c\n'
        'subgraph L\ndirection LR\nl1 --> l2 --> l3\nend\nl3 --> x',
      );
      final l = chain(layout, ['l1', 'l2', 'l3']);
      sameColumn(l);
      expect(l[0].bottom, lessThan(l[1].top));
      expect(l[1].bottom, lessThan(l[2].top));
    });

    test('so does an edge that names the subgraph', () {
      final layout = _layout(
        'flowchart TB\na --> L\n'
        'subgraph L\ndirection LR\nl1 --> l2\nend',
      );
      sameColumn(chain(layout, ['l1', 'l2']));
    });

    test('an isolated subgraph in a left-right chart runs top down', () {
      final layout = _layout(
        'flowchart LR\na --> b\n'
        'subgraph L\ndirection TB\nl1 --> l2 --> l3\nend',
      );
      final l = chain(layout, ['l1', 'l2', 'l3']);
      sameColumn(l);
      expect(l[0].bottom, lessThan(l[1].top));
      expect(l[1].bottom, lessThan(l[2].top));
      final box = _boxes(layout)['L']!;
      for (final rect in l) {
        expect(box.contains(rect.topLeft), isTrue);
        expect(box.contains(rect.bottomRight), isTrue);
      }
    });

    test('bottom up and right to left keep their order', () {
      for (final (word, check) in [
        ('BT', (List<Rect> r) => r[0].top > r[1].bottom),
        ('RL', (List<Rect> r) => r[0].left > r[1].right),
      ]) {
        final layout = _layout(
          'flowchart TB\na --> b\n'
          'subgraph L\ndirection $word\nl1 --> l2\nend',
        );
        final l = chain(layout, ['l1', 'l2']);
        expect(check(l), isTrue, reason: word);
        if (word == 'BT') sameColumn(l);
        if (word == 'RL') sameRow(l);
      }
    });

    test('an isolated subgraph inside an isolated one has its own', () {
      final layout = _layout(
        'flowchart TB\na --> b\nsubgraph O\ndirection LR\no1 --> o2\n'
        'subgraph I\ndirection TB\ni1 --> i2\nend\nend',
      );
      final o = chain(layout, ['o1', 'o2']);
      sameRow(o);
      expect(o[0].right, lessThan(o[1].left));
      final i = chain(layout, ['i1', 'i2']);
      sameColumn(i);
      expect(i[0].bottom, lessThan(i[1].top));
      final box = _boxes(layout);
      expect(box.keys, containsAll(['O', 'I']));
      for (final rect in [...o, ...i]) {
        expect(box['O']!.contains(rect.topLeft), isTrue);
        expect(box['O']!.contains(rect.bottomRight), isTrue);
      }
      for (final rect in i) {
        expect(box['I']!.contains(rect.topLeft), isTrue);
        expect(box['I']!.contains(rect.bottomRight), isTrue);
      }
      for (final rect in o) {
        expect(box['I']!.overlaps(rect), isFalse);
      }
      // The inner box is painted after the one it is inside.
      final order = [for (final sub in layout.subgraphs) sub.subgraph.id];
      expect(order.indexOf('O'), lessThan(order.indexOf('I')));
    });

    test('a subgraph with the chart direction is laid out with the rest', () {
      final same = _layout(
        'flowchart TB\nsubgraph L\ndirection TB\nl1 --> l2\nend\na --> L2[b]',
      );
      sameColumn(chain(same, ['l1', 'l2']));
    });
  });

  group('small charts', () {
    const two =
        'subgraph A\na1 --> a2\nend\nsubgraph B\nb1 --> b2\nend\na2 --> b1';

    test('two subgraphs joined by an edge stack, top down', () {
      final box = _boxes(_layout('flowchart TB\n$two'));
      expect(box['A']!.bottom, lessThanOrEqualTo(box['B']!.top));
    });

    test('and left to right', () {
      final box = _boxes(_layout('flowchart LR\n$two'));
      expect(box['A']!.right, lessThanOrEqualTo(box['B']!.left));
    });

    test('and bottom up, and right to left', () {
      final up = _boxes(_layout('flowchart BT\n$two'));
      expect(up['B']!.bottom, lessThanOrEqualTo(up['A']!.top));
      final back = _boxes(_layout('flowchart RL\n$two'));
      expect(back['B']!.right, lessThanOrEqualTo(back['A']!.left));
    });

    test('a node between two subgraphs is outside both', () {
      final layout = _layout(
        'flowchart TB\nsubgraph A\na1 --> a2\nend\n'
        'subgraph B\nb1 --> b2\nend\na2 --> m\nm --> b1',
      );
      final box = _boxes(layout);
      final m = layout.nodeOf('m')!.rect;
      expect(box['A']!.overlaps(m), isFalse);
      expect(box['B']!.overlaps(m), isFalse);
      expect(m.top, greaterThanOrEqualTo(box['A']!.bottom));
      expect(m.bottom, lessThanOrEqualTo(box['B']!.top));
    });

    test('the title is at the top of the box in every direction', () {
      for (final direction in ['TB', 'BT', 'LR', 'RL']) {
        final layout = _layout(
          'flowchart $direction\nsubgraph A [Group title]\na1 --> a2\nend',
        );
        final sub = layout.subgraphs.single;
        expect(sub.titleRect.top, moreOrLessEquals(sub.rect.top + 4));
        for (final node in layout.nodes) {
          expect(
            sub.titleRect.overlaps(node.rect),
            isFalse,
            reason: '$direction ${node.node.id}',
          );
        }
      }
    });

    test('a note tied to a node in a subgraph sits beside it, in the box', () {
      final chart = parseStateDiagram(
        'stateDiagram-v2\n  [*] --> Idle\n  Idle --> Saving\n'
        '  state Saving {\n    [*] --> Writing\n    Writing --> Indexing\n  }\n'
        '  note right of Writing : slow\n',
      );
      final layout = layoutFlowchart(chart, _style);
      final writing = layout.nodeOf('Writing')!.rect;
      final note = layout.nodes.firstWhere(
        (n) => n.node.shape == FlowNodeShape.note,
      );
      final saving = _boxes(layout)['Saving']!;
      expect(note.rect.left, greaterThan(writing.right));
      expect(note.rect.center.dy, moreOrLessEquals(writing.center.dy));
      expect(saving.contains(note.rect.topLeft), isTrue);
      expect(saving.contains(note.rect.bottomRight), isTrue);
      expect(saving.contains(writing.topLeft), isTrue);
    });

    test('a node in the row a subgraph opens or closes keeps its gap', () {
      // Two charts a fuzz found: a node outside the subgraph shares the
      // row of its outline, and the gap below that row was dropped as if
      // the subgraph's pad filled it, so the node touched the one under it.
      const first =
          'flowchart TB\nsubgraph S0\nn0["lbl n0"]\nend\n'
          'n1\nn2\nn3\nn4\nn5\nn6\nn7\nn2 --> n5\nS0 --> n5';
      const second =
          'flowchart TB\nsubgraph S0\ndirection LR\nn0\nn1["lbl n1"]\n'
          'n0 --> n1\nend\nsubgraph S1\nn2["lbl n2"]\nend\n'
          'n3\nn4\nn5\nn6\nn3 -->|"t0"| n3\nS0 --> n0\n'
          'n6 -->|"t2"| n1\nn5 --> n0\nS1 -->|"t4"| n6';
      const charts = [first, second];
      for (final source in charts) {
        final nodes = _layout(source).nodes;
        for (var i = 0; i < nodes.length; i++) {
          for (var j = i + 1; j < nodes.length; j++) {
            final a = nodes[i].rect;
            final b = nodes[j].rect;
            final across = a.left < b.right && b.left < a.right;
            if (!across) continue;
            final apart = math.max(b.top - a.bottom, a.top - b.bottom);
            expect(
              apart,
              greaterThan(0),
              reason: '${nodes[i].node.id} and ${nodes[j].node.id}',
            );
          }
        }
      }
    });

    test('an edge naming a subgraph ends on its outline', () {
      for (final direction in ['TB', 'LR']) {
        final layout = _layout(
          'flowchart $direction\nx --> S\nS --> y\n'
          'subgraph S\ns1 --> s2\nend',
        );
        final s = _boxes(layout)['S']!;
        final into = layout.edges.firstWhere((e) => e.edge.to == 'S');
        final out = layout.edges.firstWhere((e) => e.edge.from == 'S');
        if (direction == 'TB') {
          expect(into.end.dy, moreOrLessEquals(s.top), reason: direction);
          expect(out.start.dy, moreOrLessEquals(s.bottom));
        } else {
          expect(into.end.dx, moreOrLessEquals(s.left), reason: direction);
          expect(out.start.dx, moreOrLessEquals(s.right));
        }
        expect(s.inflate(0.01).contains(into.end), isTrue);
        expect(s.inflate(0.01).contains(out.start), isTrue);
      }
    });
  });
}
