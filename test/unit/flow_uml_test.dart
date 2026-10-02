// The graph engine's UML parts (#530), on hand-built charts: a class box
// sized to its compartments, a state's start, end and bar, the text at an
// edge's ends, and every cap drawn on the canvas and in the SVG.
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/canvas_target.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_renderer.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_node_size.dart';
import 'package:niman/src/diagrams/flowchart_layout.dart';
import 'package:niman/src/diagrams/svg_target.dart';

const DiagramStyle _style = DiagramStyle();

const FlowNode _animal = FlowNode(
  id: 'Animal',
  label: 'Animal',
  shape: FlowNodeShape.classBox,
  sections: [
    ['«interface»', 'Animal'],
    ['+String name', '+int age'],
    ['+makeSound() void'],
  ],
);

DiagramLayout _lay(
  List<FlowNode> nodes,
  List<FlowEdge> edges, [
  FlowDirection direction = FlowDirection.topDown,
]) => layoutFlowchart(
  Flowchart(direction: direction, nodes: nodes, edges: edges, subgraphs: []),
  _style,
);

void main() {
  test('a class box holds its widest member and its compartments', () {
    final size = flowNodeSize(_animal, const [], _style);
    final widest = DiagramMetrics.textWidth('+makeSound() void', 14);
    expect(size.width, greaterThanOrEqualTo(widest));
    final heights = classSectionHeights(_animal, _style);
    expect(heights, hasLength(3));
    expect(size.height, closeTo(heights.reduce((a, b) => a + b), 0.01));
    // The name's compartment holds two lines, the methods' one.
    expect(heights[0], greaterThan(heights[2]));
  });

  test('an empty compartment is still a band', () {
    const node = FlowNode(
      id: 'A',
      label: 'A',
      shape: FlowNodeShape.classBox,
      sections: [
        ['A'],
        [],
        [],
      ],
    );
    final heights = classSectionHeights(node, _style);
    expect(heights[1], greaterThan(0));
    expect(heights[1], lessThan(heights[0]));
  });

  test('a bar lies across the flow in every direction', () {
    const nodes = [
      FlowNode(id: 's', label: '', shape: FlowNodeShape.start),
      FlowNode(id: 'f', label: '', shape: FlowNodeShape.bar),
      FlowNode(id: 'e', label: '', shape: FlowNodeShape.end),
    ];
    const edges = [FlowEdge(from: 's', to: 'f'), FlowEdge(from: 'f', to: 'e')];
    final down = _lay(nodes, edges).nodeOf('f')!.rect;
    expect(down.width, greaterThan(down.height));
    final across = _lay(
      nodes,
      edges,
      FlowDirection.leftRight,
    ).nodeOf('f')!.rect;
    expect(across.height, greaterThan(across.width));
    final start = _lay(nodes, edges).nodeOf('s')!.rect;
    expect(start.width, start.height);
  });

  test("an edge's end texts sit by their ends, clear of the nodes", () {
    const nodes = [
      _animal,
      FlowNode(id: 'Leg', label: 'Leg', shape: FlowNodeShape.classBox),
    ];
    const edges = [
      FlowEdge(
        from: 'Animal',
        to: 'Leg',
        start: FlowEdgeEnd.diamond,
        end: FlowEdgeEnd.none,
        startLabel: '1',
        endLabel: '*',
      ),
    ];
    for (final direction in [FlowDirection.topDown, FlowDirection.leftRight]) {
      final layout = _lay(nodes, edges, direction);
      final edge = layout.edges.single;
      final tail = edge.startLabelBox!;
      final head = edge.endLabelBox!;
      expect((tail.center - edge.start).distance, lessThan(40));
      expect((head.center - edge.end).distance, lessThan(40));
      for (final node in layout.nodes) {
        expect(node.rect.overlaps(tail), isFalse, reason: '$direction');
        expect(node.rect.overlaps(head), isFalse, reason: '$direction');
      }
      final bounds = Offset.zero & layout.size;
      expect(bounds.contains(tail.topLeft), isTrue);
      expect(bounds.contains(head.bottomRight), isTrue);
    }
  });

  test('every shape and every cap draws on the canvas and in the SVG', () {
    final nodes = [
      _animal,
      const FlowNode(id: 's', label: '', shape: FlowNodeShape.start),
      const FlowNode(id: 'e', label: '', shape: FlowNodeShape.end),
      const FlowNode(id: 'b', label: '', shape: FlowNodeShape.bar),
      const FlowNode(id: 'n', label: 'a note', shape: FlowNodeShape.note),
    ];
    final edges = [
      for (final end in FlowEdgeEnd.values)
        FlowEdge(from: 's', to: 'Animal', start: end, end: end),
      const FlowEdge(from: 'Animal', to: 'b'),
      const FlowEdge(from: 'b', to: 'e'),
      const FlowEdge(from: 'n', to: 'Animal', end: FlowEdgeEnd.none),
    ];
    final layout = _lay(nodes, edges);
    final recorder = ui.PictureRecorder();
    DiagramRenderer(
      layout: layout,
      style: _style,
    ).paint(CanvasDiagramTarget(ui.Canvas(recorder)));
    recorder.endRecording().dispose();
    final svg = SvgDiagramTarget(
      width: layout.size.width,
      height: layout.size.height,
    );
    DiagramRenderer(layout: layout, style: _style).paint(svg);
    final text = svg.finish();
    expect(text, contains('+makeSound() void'));
    expect(text, contains('«interface»'));
    expect(text, contains('a note'));
  });

  test('a short edge makes room for its label, end texts and caps', () {
    const nodes = [
      FlowNode(id: 'Zoo', label: 'Zoo', shape: FlowNodeShape.classBox),
      FlowNode(id: 'Animal', label: 'Animal', shape: FlowNodeShape.classBox),
    ];
    const edges = [
      FlowEdge(
        from: 'Zoo',
        to: 'Animal',
        label: 'houses',
        start: FlowEdgeEnd.diamond,
        end: FlowEdgeEnd.none,
        startLabel: '1',
        endLabel: 'many',
      ),
    ];
    double gapTo(Rect box, Offset point) {
      final dx = point.dx < box.left
          ? box.left - point.dx
          : (point.dx > box.right ? point.dx - box.right : 0.0);
      final dy = point.dy < box.top
          ? box.top - point.dy
          : (point.dy > box.bottom ? point.dy - box.bottom : 0.0);
      return Offset(dx, dy).distance;
    }

    for (final direction in [FlowDirection.topDown, FlowDirection.leftRight]) {
      final edge = _lay(nodes, edges, direction).edges.single;
      final label = edge.labelBox!;
      // Clear of the diamond at the tail, eighteen long.
      expect(gapTo(label, edge.start), greaterThan(18), reason: '$direction');
      expect(
        label.overlaps(edge.startLabelBox!),
        isFalse,
        reason: '$direction',
      );
      expect(label.overlaps(edge.endLabelBox!), isFalse, reason: '$direction');
    }
  });

  test('a note tied to a node sits beside it, in its rank', () {
    const nodes = [
      FlowNode(id: 'A', label: 'A', shape: FlowNodeShape.round),
      FlowNode(id: 'B', label: 'B', shape: FlowNodeShape.round),
      FlowNode(id: 'C', label: 'C', shape: FlowNodeShape.round),
      FlowNode(id: 'n', label: 'a note', shape: FlowNodeShape.note),
    ];
    const edges = [
      FlowEdge(from: 'A', to: 'B'),
      FlowEdge(from: 'A', to: 'C'),
      FlowEdge(
        from: 'B',
        to: 'n',
        style: FlowEdgeStyle.dotted,
        end: FlowEdgeEnd.none,
      ),
    ];
    final layout = _lay(nodes, edges);
    final b = layout.nodeOf('B')!.rect;
    final note = layout.nodeOf('n')!.rect;
    expect(note.center.dy, closeTo(b.center.dy, 0.01));
    expect(note.left, greaterThan(b.right));
    // Nothing between the note and its node.
    for (final other in layout.nodes) {
      if (other.node.id == 'B' || other.node.id == 'n') continue;
      final r = other.rect;
      final between =
          (r.center.dy - b.center.dy).abs() < 1 &&
          r.left > b.right &&
          r.right < note.left;
      expect(between, isFalse);
    }
  });
}
