/// The outline of each Mermaid node shape as a point list (#530).
///
/// Every shape is a polygon (a circle is a fine one), so the two drawings
/// only need one fill-and-stroke primitive. Quadratic-looking shapes sample
/// their curves here, deterministically.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// Builds the outline points of a node shape.
abstract final class DiagramShapes {
  /// The points of [shape] fitted to [rect], sampled for a [radius] corner.
  static List<Offset> polygonFor(
    FlowNodeShape shape,
    Rect rect, {
    double radius = 6,
  }) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    switch (shape) {
      case FlowNodeShape.rect:
      case FlowNodeShape.subroutine:
        return [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft];
      case FlowNodeShape.round:
        return _roundRect(rect, radius);
      case FlowNodeShape.stadium:
        return _stadium(rect);
      case FlowNodeShape.circle:
        return _ellipse(cx, cy, rect.width / 2, rect.height / 2, 32);
      case FlowNodeShape.diamond:
        return [
          Offset(cx, rect.top),
          Offset(rect.right, cy),
          Offset(cx, rect.bottom),
          Offset(rect.left, cy),
        ];
      case FlowNodeShape.hexagon:
        final inset = math.min(rect.width * 0.2, rect.height * 0.5);
        return [
          Offset(rect.left, cy),
          Offset(rect.left + inset, rect.top),
          Offset(rect.right - inset, rect.top),
          Offset(rect.right, cy),
          Offset(rect.right - inset, rect.bottom),
          Offset(rect.left + inset, rect.bottom),
        ];
      case FlowNodeShape.parallelogram:
        final skew = math.min(rect.width * 0.25, rect.height * 0.6);
        return [
          Offset(rect.left + skew, rect.top),
          Offset(rect.right, rect.top),
          Offset(rect.right - skew, rect.bottom),
          Offset(rect.left, rect.bottom),
        ];
      case FlowNodeShape.parallelogramAlt:
        final skew = math.min(rect.width * 0.25, rect.height * 0.6);
        return [
          Offset(rect.left, rect.top),
          Offset(rect.right - skew, rect.top),
          Offset(rect.right, rect.bottom),
          Offset(rect.left + skew, rect.bottom),
        ];
      case FlowNodeShape.trapezoid:
        final skew = math.min(rect.width * 0.2, rect.height * 0.6);
        return [
          Offset(rect.left + skew, rect.top),
          Offset(rect.right - skew, rect.top),
          Offset(rect.right, rect.bottom),
          Offset(rect.left, rect.bottom),
        ];
      case FlowNodeShape.trapezoidAlt:
        final skew = math.min(rect.width * 0.2, rect.height * 0.6);
        return [
          Offset(rect.left, rect.top),
          Offset(rect.right, rect.top),
          Offset(rect.right - skew, rect.bottom),
          Offset(rect.left + skew, rect.bottom),
        ];
      case FlowNodeShape.asymmetric:
        final bite = math.min(rect.width * 0.2, rect.height * 0.5);
        return [
          Offset(rect.left, cy),
          Offset(rect.left + bite, rect.top),
          Offset(rect.right, rect.top),
          Offset(rect.right, rect.bottom),
          Offset(rect.left + bite, rect.bottom),
        ];
      case FlowNodeShape.database:
        return _cylinder(rect);
    }
  }

  /// The two shape-specific bars of a subroutine, from its box.
  static List<(Offset, Offset)> subroutineBars(Rect rect) {
    const inset = 6.0;
    return [
      (
        Offset(rect.left + inset, rect.top),
        Offset(rect.left + inset, rect.bottom),
      ),
      (
        Offset(rect.right - inset, rect.top),
        Offset(rect.right - inset, rect.bottom),
      ),
    ];
  }

  static List<Offset> _roundRect(Rect rect, double radius) {
    final r = math.min(radius, math.min(rect.width, rect.height) / 2);
    if (r <= 0) {
      return [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft];
    }
    return [
      ..._arc(rect.left + r, rect.top + r, r, r, math.pi, math.pi / 2),
      ..._arc(rect.right - r, rect.top + r, r, r, -math.pi / 2, math.pi / 2),
      ..._arc(rect.right - r, rect.bottom - r, r, r, 0, math.pi / 2),
      ..._arc(rect.left + r, rect.bottom - r, r, r, math.pi / 2, math.pi / 2),
    ];
  }

  static List<Offset> _stadium(Rect rect) {
    final r = rect.height / 2;
    return [
      Offset(rect.left + r, rect.top),
      Offset(rect.right - r, rect.top),
      ..._arc(rect.right - r, rect.center.dy, r, r, -math.pi / 2, math.pi),
      Offset(rect.left + r, rect.bottom),
      ..._arc(rect.left + r, rect.center.dy, r, r, math.pi / 2, math.pi),
    ];
  }

  static List<Offset> _cylinder(Rect rect) {
    final rx = rect.width / 2;
    final ry = math.min(rect.height * 0.16, 12).toDouble();
    return [
      Offset(rect.left, rect.top + ry),
      ..._arc(rect.center.dx, rect.top + ry, rx, ry, math.pi, math.pi),
      Offset(rect.right, rect.bottom - ry),
      ..._arc(rect.center.dx, rect.bottom - ry, rx, ry, 0, math.pi),
    ];
  }

  static List<Offset> _ellipse(
    double cx,
    double cy,
    double rx,
    double ry,
    int steps,
  ) {
    final points = <Offset>[];
    for (var i = 0; i < steps; i++) {
      final angle = 2 * math.pi * i / steps;
      points.add(Offset(cx + rx * math.cos(angle), cy + ry * math.sin(angle)));
    }
    return points;
  }

  static List<Offset> _arc(
    double cx,
    double cy,
    double rx,
    double ry,
    double start,
    double sweep,
  ) {
    const steps = 8;
    final points = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final angle = start + sweep * i / steps;
      points.add(Offset(cx + rx * math.cos(angle), cy + ry * math.sin(angle)));
    }
    return points;
  }
}
