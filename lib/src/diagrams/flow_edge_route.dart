/// The curve an edge is drawn along between two placed nodes, and the box
/// its label sits in (#530), in canonical space.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// The curve's straight run before it reaches a node, as a share of the gap.
const double _curveBend = 0.45;

/// The curve joining two placed nodes.
LaidOutEdge routeFlowEdge(
  FlowEdge edge,
  Map<String, Rect> rects,
  DiagramStyle style,
) {
  final from = rects[edge.from];
  final to = rects[edge.to];
  if (from == null || to == null) {
    return LaidOutEdge(
      edge: edge,
      start: Offset.zero,
      control1: Offset.zero,
      control2: Offset.zero,
      end: Offset.zero,
    );
  }
  Offset start;
  Offset control1;
  Offset control2;
  Offset end;

  if (edge.from == edge.to) {
    final dy = from.height * 0.22;
    start = Offset(from.right, from.center.dy - dy);
    end = Offset(from.right, from.center.dy + dy);
    control1 = Offset(from.right + 40, from.center.dy - 34);
    control2 = Offset(from.right + 40, from.center.dy + 34);
  } else if ((to.center.dy - from.center.dy).abs() < 1) {
    final right = to.center.dx >= from.center.dx;
    start = Offset(right ? from.right : from.left, from.center.dy);
    end = Offset(right ? to.left : to.right, to.center.dy);
    final bend = (end.dx - start.dx) * _curveBend;
    control1 = Offset(start.dx + bend, start.dy);
    control2 = Offset(end.dx - bend, end.dy);
  } else {
    final down = to.center.dy > from.center.dy;
    start = Offset(from.center.dx, down ? from.bottom : from.top);
    end = Offset(to.center.dx, down ? to.top : to.bottom);
    final bend = (end.dy - start.dy) * _curveBend;
    control1 = Offset(start.dx, start.dy + bend);
    control2 = Offset(end.dx, end.dy - bend);
  }

  final label = edge.label == null || edge.label!.isEmpty ? null : edge.label;
  Rect? labelBox;
  if (label != null) {
    final size = Size(
      DiagramMetrics.textWidth(label, style.fontSize) +
          style.edgeLabelPadding.horizontal,
      style.fontSize * style.lineHeight + style.edgeLabelPadding.vertical,
    );
    final mid = _cubicMidpoint(start, control1, control2, end);
    labelBox = Rect.fromCenter(
      center: mid,
      width: size.width,
      height: size.height,
    );
  }
  return LaidOutEdge(
    edge: edge,
    start: start,
    control1: control1,
    control2: control2,
    end: end,
    label: label,
    labelBox: labelBox,
  );
}

Offset _cubicMidpoint(Offset p0, Offset c1, Offset c2, Offset p1) {
  const t = 0.5;
  const u = 1 - t;
  final x =
      u * u * u * p0.dx +
      3 * u * u * t * c1.dx +
      3 * u * t * t * c2.dx +
      t * t * t * p1.dx;
  final y =
      u * u * u * p0.dy +
      3 * u * u * t * c1.dy +
      3 * u * t * t * c2.dy +
      t * t * t * p1.dy;
  return Offset(x, y);
}
