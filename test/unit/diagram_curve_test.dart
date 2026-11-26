// An edge drawn as a chain of cubic Béziers (#530): one stroke on either
// target, so a dashed pattern runs on across the joins, and a point along it
// that reads the whole chain.
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/canvas_target.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/flow_edge_curve.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/svg_target.dart';

const FlowEdge _edge = FlowEdge(from: 'a', to: 'b');

const List<Offset> _chain = [
  Offset.zero,
  Offset(0, 10),
  Offset(10, 20),
  Offset(10, 30),
  Offset(10, 40),
  Offset(20, 50),
  Offset(20, 60),
];

void main() {
  test('the svg target writes one path with a cubic for each piece', () {
    final target = SvgDiagramTarget(width: 40, height: 80)
      ..curve(_chain, color: const Color(0xFF000000), dashed: true);
    final svg = target.finish();
    expect('<path'.allMatches(svg).length, 1);
    expect(' C '.allMatches(svg).length, 2);
    expect(svg, contains('M 0 0 C 0 10 10 20 10 30 C 10 40 20 50 20 60'));
    expect(svg, contains('stroke-dasharray'));
  });

  test('the canvas target draws a chain as one path', () {
    final recorder = ui.PictureRecorder();
    CanvasDiagramTarget(ui.Canvas(recorder))
        .curve(_chain, color: const Color(0xFF000000), dashed: true);
    final picture = recorder.endRecording();
    expect(picture.approximateBytesUsed, greaterThan(0));
    picture.dispose();
  });

  test('a one-cubic edge keeps its ends and its control points', () {
    final edge = LaidOutEdge(
      edge: _edge,
      start: Offset.zero,
      control1: const Offset(0, 10),
      control2: const Offset(10, 20),
      end: const Offset(10, 30),
    );
    expect(edge.path.length, 4);
    expect(edge.start, Offset.zero);
    expect(edge.control1, const Offset(0, 10));
    expect(edge.control2, const Offset(10, 20));
    expect(edge.end, const Offset(10, 30));
  });

  test('a chain starts and ends where it says and passes its joins', () {
    final edge = LaidOutEdge.along(edge: _edge, path: _chain);
    expect(edge.start, Offset.zero);
    expect(edge.end, const Offset(20, 60));
    expect(edge.control1, const Offset(0, 10));
    expect(edge.control2, const Offset(20, 50));
    expect(edge.at(0), Offset.zero);
    expect(edge.at(0.5), const Offset(10, 30));
    expect(edge.at(1), const Offset(20, 60));
    // Halfway along the second piece, by the cubic's own formula.
    expect(edge.at(0.75).dx, closeTo(15, 1e-9));
    expect(edge.at(0.75).dy, closeTo(45, 1e-9));
  });

  test('the basis curve starts and ends on its points, with straight ends', () {
    const points = [
      Offset.zero,
      Offset(0, 50),
      Offset(40, 100),
      Offset(40, 150),
    ];
    final path = flowBasisPath(points);
    expect((path.length - 1) % 3, 0);
    expect(path.first, points.first);
    expect(path.last, points.last);
    // The first piece runs towards the second point, the last comes from the
    // one before the end: where a cap points.
    expect(path[1].dx, 0);
    expect(path[1].dy, greaterThan(0));
    final last = path.last - path[path.length - 2];
    final before = points.last - points[points.length - 2];
    expect(last.dx * before.dy - last.dy * before.dx, closeTo(0, 1e-9));
    expect(last.dx * before.dx + last.dy * before.dy, greaterThan(0));
  });

  test('the basis curve through points in a line is that line', () {
    final path = flowBasisPath(const [
      Offset(10, 0),
      Offset(10, 40),
      Offset(10, 90),
      Offset(10, 130),
    ]);
    for (final point in path) {
      expect(point.dx, 10);
    }
    for (var i = 1; i < path.length; i++) {
      expect(path[i].dy, greaterThanOrEqualTo(path[i - 1].dy));
    }
  });
}
