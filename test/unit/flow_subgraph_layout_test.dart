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
