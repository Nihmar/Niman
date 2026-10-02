/// The marks an edge ends with (#530): arrowheads, crosses, circles, UML's
/// triangles and diamonds, and the crow's feet of an entity-relationship
/// diagram.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// Draws [end] at [point], the edge arriving from [towards]. A hollow mark
/// is filled with the surface, so the line under it does not show through.
void paintEdgeCap(
  DiagramTarget target,
  Offset point,
  Offset towards,
  FlowEdgeEnd end,
  DiagramPalette palette,
) {
  if (!end.isMarked) return;
  final direction = _unit(point - towards);
  final normal = Offset(-direction.dy, direction.dx);
  switch (end) {
    case FlowEdgeEnd.none:
      return;
    case FlowEdgeEnd.arrow:
      final back = point - direction * 11;
      target.polygon([
        point,
        back + normal * 5,
        back - normal * 5,
      ], fill: palette.edge);
    case FlowEdgeEnd.cross:
      const s = 5.0;
      target
        ..line(
          point - direction * s - normal * s,
          point + direction * s + normal * s,
          color: palette.edge,
          strokeWidth: 2,
        )
        ..line(
          point - direction * s + normal * s,
          point + direction * s - normal * s,
          color: palette.edge,
          strokeWidth: 2,
        );
    case FlowEdgeEnd.circle:
      target.polygon(
        DiagramShapes.polygonFor(
          FlowNodeShape.circle,
          Rect.fromCircle(center: point, radius: 5),
        ),
        fill: palette.edgeLabelBackground,
        stroke: palette.edge,
        strokeWidth: 2,
      );
    case FlowEdgeEnd.triangle:
      final back = point - direction * 14;
      target.polygon(
        [point, back + normal * 8, back - normal * 8],
        fill: palette.edgeLabelBackground,
        stroke: palette.edge,
        strokeWidth: 1.5,
      );
    case FlowEdgeEnd.diamond:
    case FlowEdgeEnd.hollowDiamond:
      final middle = point - direction * 9;
      final filled = end == FlowEdgeEnd.diamond;
      target.polygon(
        [
          point,
          middle + normal * 6,
          point - direction * 18,
          middle - normal * 6,
        ],
        fill: filled ? palette.edge : palette.edgeLabelBackground,
        stroke: palette.edge,
        strokeWidth: 1.5,
      );
    case FlowEdgeEnd.one:
      _bar(target, point, direction, normal, 6, palette);
      _bar(target, point, direction, normal, 11, palette);
    case FlowEdgeEnd.zeroOrOne:
      _bar(target, point, direction, normal, 6, palette);
      _ring(target, point - direction * 15, palette);
    case FlowEdgeEnd.oneOrMore:
      _foot(target, point, direction, normal, palette);
      _bar(target, point, direction, normal, 16, palette);
    case FlowEdgeEnd.zeroOrMore:
      _foot(target, point, direction, normal, palette);
      _ring(target, point - direction * 18, palette);
  }
}

/// A bar across the edge, [back] from its end.
void _bar(
  DiagramTarget target,
  Offset point,
  Offset direction,
  Offset normal,
  double back,
  DiagramPalette palette,
) {
  final at = point - direction * back;
  target.line(
    at + normal * 7,
    at - normal * 7,
    color: palette.edge,
    strokeWidth: 1.5,
  );
}

/// A small ring on the edge at [centre], filled with the surface.
void _ring(DiagramTarget target, Offset centre, DiagramPalette palette) {
  target.polygon(
    DiagramShapes.polygonFor(
      FlowNodeShape.circle,
      Rect.fromCircle(center: centre, radius: 4.5),
    ),
    fill: palette.edgeLabelBackground,
    stroke: palette.edge,
    strokeWidth: 1.5,
  );
}

/// A crow's foot: three toes from a point on the edge to the node.
void _foot(
  DiagramTarget target,
  Offset point,
  Offset direction,
  Offset normal,
  DiagramPalette palette,
) {
  final heel = point - direction * 12;
  for (final toe in [point + normal * 7, point, point - normal * 7]) {
    target.line(heel, toe, color: palette.edge, strokeWidth: 1.5);
  }
}

Offset _unit(Offset vector) {
  final length = math.sqrt(vector.dx * vector.dx + vector.dy * vector.dy);
  if (length == 0) return const Offset(0, 1);
  return Offset(vector.dx / length, vector.dy / length);
}
