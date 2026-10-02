// Laying a flowchart out (#530): ranks, directions and bounds.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/er_parser.dart';
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

  test('a subgraph inside another is boxed inside it, title and all', () {
    final layout = _layout(
      'flowchart TD\nsubgraph outer [Outer]\nsubgraph inner [Inner]\n'
      'A-->B\nend\nend',
    );
    final outer = layout.subgraphs.firstWhere((s) => s.title == 'Outer');
    final inner = layout.subgraphs.firstWhere((s) => s.title == 'Inner');
    expect(layout.subgraphs.first, outer, reason: 'painted first, under');
    expect(outer.rect.top, lessThan(inner.rect.top));
    expect(outer.titleRect.bottom, lessThanOrEqualTo(inner.rect.top));
    expect(outer.rect.left, lessThan(inner.rect.left));
    expect(outer.rect.right, greaterThan(inner.rect.right));
    expect(outer.rect.bottom, greaterThan(inner.rect.bottom));
  });

  test('a cycle is ranked from the node written first', () {
    final layout = _layout('flowchart TD\nA-->B\nB-->C\nC-->A');
    expect(_rank(layout, 'A'), 0);
    expect(_rank(layout, 'B'), 1);
    expect(_rank(layout, 'C'), 2);
  });

  test("a cycle's way back goes round the nodes, not through them", () {
    for (final direction in ['TD', 'LR']) {
      final layout = _layout(
        'flowchart $direction\nA[First step] --> B[Second]\nB --> C\nC --> A',
      );
      final back = layout.edges.last;
      expect(back.edge.from, 'C');
      double across(Offset p) => direction == 'TD' ? p.dx : p.dy;
      final reach = layout.nodes
          .map((n) => direction == 'TD' ? n.rect.right : n.rect.bottom)
          .reduce((a, b) => a > b ? a : b);
      // Both control points lie beyond every node it passes.
      expect(across(back.control1), greaterThan(reach), reason: direction);
      expect(across(back.control2), greaterThan(reach), reason: direction);
      for (final node in layout.nodes) {
        expect(
          node.rect.contains(back.labelBox?.center ?? Offset.infinite),
          isFalse,
        );
      }
    }
  });

  test("a cycle's way back passes beside its own ranks' other nodes", () {
    // L, D and C share a rank, D between the other two: with no side of D
    // free, its way back to A leaves by its right side, past C.
    final layout = _layout(
      'flowchart TD\nA --> L\nA --> D\nA --> C[A wide node here]\nD --> A',
    );
    final back = layout.edges.last;
    expect(back.edge.from, 'D');
    final from = layout.nodeOf('D')!.rect;
    final wide = layout.nodeOf('C')!.rect;
    expect(layout.nodeOf('L')!.rect.right, lessThan(from.left));
    expect(wide.left, greaterThan(from.right));
    expect(back.control1.dx, greaterThan(wide.right));
  });

  test('an edge past a rank goes round the nodes in its way', () {
    for (final direction in ['TD', 'LR']) {
      final layout = _layout(
        'flowchart $direction\nA[Animal] --> B[Duck]\nB --> C[Fish]\nA --> C',
      );
      final long = layout.edges.last;
      final between = layout.nodeOf('B')!.rect;
      for (var i = 1; i < 20; i++) {
        final t = i / 20;
        final u = 1 - t;
        final point =
            long.start * (u * u * u) +
            long.control1 * (3 * u * u * t) +
            long.control2 * (3 * u * t * t) +
            long.end * (t * t * t);
        expect(between.contains(point), isFalse, reason: '$direction t=$t');
      }
    }
  });

  test("an edge's label into a subgraph keeps off its title", () {
    for (final direction in ['TD', 'LR']) {
      final layout = _layout(
        'flowchart $direction\nA -->|a label here| B\n'
        'subgraph S [The group title]\nB --> C\nend',
      );
      final label = layout.edges.first.labelBox!;
      final title = layout.subgraphs.single.titleRect;
      expect(label.overlaps(title), isFalse, reason: direction);
    }
  });

  test('a bent edge stays clear of a node all down its height', () {
    final layout = _layout(
      'flowchart TD\nC[CUSTOMER] --> O[An ORDER with a long, long label]\n'
      'C --> D[DELIVERY-ADDRESS]\nP[PRODUCT] --> L[LINE-ITEM]\nO --> L',
    );
    final long = layout.edges.firstWhere((e) => e.edge.from == 'P');
    for (final id in ['O', 'D']) {
      final rect = layout.nodeOf(id)!.rect;
      for (var i = 1; i < 100; i++) {
        final t = i / 100;
        final u = 1 - t;
        final point =
            long.start * (u * u * u) +
            long.control1 * (3 * u * u * t) +
            long.control2 * (3 * u * t * t) +
            long.end * (t * t * t);
        expect(rect.contains(point), isFalse, reason: '$id at t=$t');
      }
    }
  });

  test('a relationship past an entity keeps clear of it', () {
    final layout = layoutFlowchart(
      parseErDiagram(
        'erDiagram\nCUSTOMER ||--o{ ORDER : places\n'
        'ORDER ||--|{ LINE-ITEM : contains\n'
        'CUSTOMER }|..|{ DELIVERY-ADDRESS : uses\n'
        'PRODUCT |o--o{ LINE-ITEM : "appears in"\n'
        'CUSTOMER {\nstring name\nstring custNumber PK\nstring sector\n}\n'
        'ORDER {\nint orderNumber PK\n'
        'string deliveryAddress FK "where it goes"\n}',
      ),
      const DiagramStyle(),
    );
    final long = layout.edges.firstWhere((e) => e.edge.from == 'PRODUCT');
    for (final node in layout.nodes) {
      if (node.node.id == 'PRODUCT' || node.node.id == 'LINE-ITEM') continue;
      for (var i = 1; i < 100; i++) {
        final t = i / 100;
        final u = 1 - t;
        final point =
            long.start * (u * u * u) +
            long.control1 * (3 * u * u * t) +
            long.control2 * (3 * u * t * t) +
            long.end * (t * t * t);
        expect(node.rect.contains(point), isFalse, reason: node.node.id);
      }
      expect(node.rect.overlaps(long.labelBox!), isFalse);
    }
  });

  test('edges leaving or reaching one side spread along it, in order', () {
    final layout = _layout(
      'flowchart TD\nA[A wide source node] --> B\nA --> C\nA --> D\n'
      'B --> E[A wide target node]\nC --> E',
    );
    List<double> startsOf(String id) => [
      for (final e in layout.edges)
        if (e.edge.from == id) e.start.dx,
    ];
    final out = startsOf('A');
    expect(out.toSet(), hasLength(3), reason: 'no two share a point');
    final targets = [
      for (final e in layout.edges)
        if (e.edge.from == 'A') layout.nodeOf(e.edge.to)!.rect.center.dx,
    ];
    // The leftmost target is reached from the leftmost point, and so on.
    for (var i = 0; i < out.length; i++) {
      for (var j = 0; j < out.length; j++) {
        if (targets[i] < targets[j]) expect(out[i], lessThan(out[j]));
      }
    }
    final into = [
      for (final e in layout.edges)
        if (e.edge.to == 'E') e.end.dx,
    ];
    expect(into.toSet(), hasLength(2));
    final source = layout.nodeOf('A')!.rect;
    for (final x in out) {
      expect(x, inInclusiveRange(source.left, source.right));
    }
  });
}
