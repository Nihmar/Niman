// Laying a flowchart out (#530): ranks, directions and bounds.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_parser.dart';
import 'package:niman/src/diagrams/flowchart_layout.dart';

DiagramLayout _layout(String source) =>
    layoutFlowchart(parseFlowchart(source), const DiagramStyle());

int _rank(DiagramLayout layout, String id) {
  final target = layout.nodeOf(id)!.rect.center.dy;
  var rank = 0;
  for (final node in layout.nodes) {
    if (node.rect.center.dy < target) rank++;
  }
  return rank;
}

void main() {
  test('every node gets a box and the drawing has a size', () {
    final layout = _layout(
      'flowchart TD\n'
      'A[Start] --> B{Is it?}\n'
      'B -->|Yes| C[OK]\n'
      'B -->|No| D[Stop]',
    );
    expect(layout.nodes, hasLength(4));
    expect(layout.edges, hasLength(3));
    expect(layout.size.width, greaterThan(0));
    expect(layout.size.height, greaterThan(0));
    for (final node in layout.nodes) {
      expect(node.rect.width, greaterThan(0));
      expect(node.rect.height, greaterThan(0));
      expect(node.rect.left, greaterThanOrEqualTo(0));
      expect(node.rect.top, greaterThanOrEqualTo(0));
      expect(node.rect.right, lessThanOrEqualTo(layout.size.width + 0.01));
      expect(node.rect.bottom, lessThanOrEqualTo(layout.size.height + 0.01));
    }
  });

  test('a top-down chart ranks each edge below the one before it', () {
    final layout = _layout('flowchart TD\nA --> B --> C --> D');
    expect(_rank(layout, 'A'), 0);
    expect(_rank(layout, 'B'), 1);
    expect(_rank(layout, 'C'), 2);
    expect(_rank(layout, 'D'), 3);
  });

  test('left-right swaps the axes', () {
    final down = _layout('flowchart TD\nA[Start] --> B --> C');
    final across = _layout('flowchart LR\nA[Start] --> B --> C');
    expect(across.size.width, greaterThan(down.size.width));
    expect(across.size.height, lessThan(down.size.height));
  });

  test('edge endpoints stay inside the drawing', () {
    final layout = _layout('flowchart TD\nA --> B\nB --> C\nA --> C');
    for (final edge in layout.edges) {
      for (final point in [
        edge.start,
        edge.end,
        edge.control1,
        edge.control2,
      ]) {
        expect(point.dx, greaterThanOrEqualTo(-0.01));
        expect(point.dy, greaterThanOrEqualTo(-0.01));
        expect(point.dx, lessThanOrEqualTo(layout.size.width + 0.01));
        expect(point.dy, lessThanOrEqualTo(layout.size.height + 0.01));
      }
    }
  });

  test('a subgraph is boxed round its nodes', () {
    final layout = _layout(
      'flowchart TD\nsubgraph one [Group]\nA --> B\nend\nC --> A',
    );
    expect(layout.subgraphs, hasLength(1));
    final box = layout.subgraphs.first.rect;
    final a = layout.nodeOf('A')!.rect;
    final b = layout.nodeOf('B')!.rect;
    expect(box.contains(a.topLeft), isTrue);
    expect(box.contains(b.bottomRight), isTrue);
  });

  test('a self loop and a cycle both lay out', () {
    final layout = _layout('flowchart TD\nA --> A\nB --> C\nC --> B');
    expect(layout.nodes, hasLength(3));
    expect(layout.size.width, greaterThan(0));
  });

  test('a lone node is still a drawing', () {
    final layout = _layout('flowchart TD\nOnly[Alone]');
    expect(layout.nodes, hasLength(1));
    expect(layout.size.width, greaterThan(0));
  });

  test('an empty chart is empty, not a crash', () {
    final layout = layoutFlowchart(
      const Flowchart(
        direction: FlowDirection.topDown,
        nodes: [],
        edges: [],
        subgraphs: [],
      ),
      const DiagramStyle(),
    );
    expect(layout.size, Size.zero);
  });

  test('a node keeps its proportions in every direction', () {
    for (final direction in ['TD', 'BT', 'LR', 'RL']) {
      final layout = _layout(
        'flowchart $direction\nA[A very long label here] -->|a long label| B',
      );
      final node = layout.nodeOf('A')!.rect;
      expect(node.width, greaterThan(node.height), reason: direction);
      final label = layout.edges.single.labelBox!;
      expect(label.width, greaterThan(label.height), reason: direction);
    }
  });

  test('a subgraph title sits at the top of its box in every direction', () {
    for (final direction in ['TD', 'BT', 'LR', 'RL']) {
      final layout = _layout(
        'flowchart $direction\nsubgraph S [A group title]\nA --> B\nend',
      );
      final box = layout.subgraphs.single;
      expect(box.titleRect.width, greaterThan(box.titleRect.height));
      expect(box.titleRect.top - box.rect.top, lessThan(10), reason: direction);
      for (final node in layout.nodes) {
        expect(
          node.rect.top,
          greaterThan(box.titleRect.bottom),
          reason: '$direction: the title is not over a node',
        );
      }
    }
  });
}
