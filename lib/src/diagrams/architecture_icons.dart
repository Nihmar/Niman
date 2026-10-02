/// The icons of an architecture diagram (#530), drawn from lines and
/// outlines so the canvas and the SVG draw them alike: Mermaid's own five
/// — `cloud`, `database`, `disk`, `internet`, `server` — and, for any
/// other name (an iconify pack's, which a note cannot fetch), a plain box.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// An icon's strokes: closed outlines, open lines, and filled dots.
typedef ArchIcon = ({
  List<List<Offset>> outlines,
  List<(Offset, Offset)> lines,
  List<Rect> dots,
});

/// The icon [name] draws inside [box].
ArchIcon archIcon(String name, Rect box) {
  final r = box.deflate(box.width * 0.2);
  switch (name.toLowerCase()) {
    case 'database':
      return (
        outlines: [DiagramShapes.polygonFor(FlowNodeShape.database, r)],
        lines: const [],
        dots: const [],
      );
    case 'disk':
      return (
        outlines: [
          _circle(r.center, r.width / 2),
          _circle(r.center, r.width / 8),
        ],
        lines: const [],
        dots: const [],
      );
    case 'server':
      final h = r.height / 3;
      return (
        outlines: [
          for (var i = 0; i < 3; i++)
            DiagramShapes.polygonFor(
              FlowNodeShape.round,
              Rect.fromLTWH(r.left, r.top + i * h, r.width, h).deflate(1),
              radius: 2,
            ),
        ],
        lines: const [],
        dots: [
          for (var i = 0; i < 3; i++)
            Rect.fromCircle(
              center: Offset(r.right - h / 2, r.top + (i + 0.5) * h),
              radius: 1.6,
            ),
        ],
      );
    case 'internet':
      final c = r.center;
      final radius = r.width / 2;
      return (
        outlines: [_circle(c, radius), _ellipse(c, radius * 0.45, radius)],
        lines: [
          (c.translate(-radius, 0), c.translate(radius, 0)),
          for (final dy in [-0.55, 0.55])
            (
              c.translate(-radius * 0.83, radius * dy),
              c.translate(radius * 0.83, radius * dy),
            ),
        ],
        dots: const [],
      );
    case 'cloud':
      return (outlines: [_cloud(r)], lines: const [], dots: const []);
    default:
      final inner = r.deflate(r.width * 0.08);
      return (
        outlines: [
          DiagramShapes.polygonFor(FlowNodeShape.round, inner, radius: 3),
        ],
        lines: [
          (
            Offset(inner.left, inner.top + inner.height * 0.3),
            Offset(inner.right, inner.top + inner.height * 0.3),
          ),
        ],
        dots: const [],
      );
  }
}

List<Offset> _circle(Offset centre, double radius) =>
    _ellipse(centre, radius, radius);

List<Offset> _ellipse(Offset centre, double rx, double ry) =>
    DiagramShapes.polygonFor(
      FlowNodeShape.circle,
      Rect.fromCenter(center: centre, width: 2 * rx, height: 2 * ry),
    );

/// A cloud: three bumps over a flat base, as one outline.
List<Offset> _cloud(Rect r) {
  // Three circles in the box's own units, and the base they sit on.
  final circles = [
    (Offset(r.left + r.width * 0.24, r.top + r.height * 0.62), r.width * 0.22),
    (Offset(r.left + r.width * 0.52, r.top + r.height * 0.45), r.width * 0.3),
    (Offset(r.left + r.width * 0.78, r.top + r.height * 0.64), r.width * 0.2),
  ];
  final base = r.top + r.height * 0.84;
  const samples = 48;
  final left = circles.first.$1.dx - circles.first.$2;
  final right = circles.last.$1.dx + circles.last.$2;
  // The top: at each x, the highest circle over it, but never under the
  // base; the bottom: the base.
  final top = <Offset>[
    for (var i = 0; i <= samples; i++)
      () {
        final x = left + (right - left) * i / samples;
        var y = base;
        for (final (c, radius) in circles) {
          final d = x - c.dx;
          if (d.abs() <= radius) {
            y = math.min(y, c.dy - math.sqrt(radius * radius - d * d));
          }
        }
        return Offset(x, y);
      }(),
  ];
  return [...top, Offset(right, base), Offset(left, base)];
}
