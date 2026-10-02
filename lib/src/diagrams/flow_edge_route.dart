/// The curve an edge is drawn along between two placed nodes, and the box
/// its label sits in (#530), in canonical space.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// The curve's straight run before it reaches a node, as a share of the gap.
const double _curveBend = 0.45;

/// How far a cycle's way back bulges past the nodes it goes round.
const double _backBulge = 36;

/// The curve joining two placed nodes; [across] when the chart is drawn
/// left to right or right to left, and its label box is laid on its side.
LaidOutEdge routeFlowEdge(
  FlowEdge edge,
  Map<String, Rect> rects,
  DiagramStyle style, {
  required bool across,
}) {
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
  } else if (to.center.dy > from.center.dy) {
    start = Offset(from.center.dx, from.bottom);
    end = Offset(to.center.dx, to.top);
    final bend = (end.dy - start.dy) * _curveBend;
    control1 = Offset(start.dx, start.dy + bend);
    control2 = Offset(end.dx, end.dy - bend);
  } else {
    // Upwards is a cycle's way back (the ranking sets those edges aside,
    // so every other edge runs down): straight up it would cross the very
    // edges it closes, and every node between. It leaves and comes back
    // by the right sides and bulges past the nodes of the ranks it spans,
    // its own two included.
    var reach = math.max(from.right, to.right);
    for (final rect in rects.values) {
      final centre = rect.center.dy;
      if (centre >= to.center.dy - 1 && centre <= from.center.dy + 1) {
        reach = math.max(reach, rect.right);
      }
    }
    final bulge = reach + _backBulge;
    start = Offset(from.right, from.center.dy);
    end = Offset(to.right, to.center.dy);
    control1 = Offset(bulge, start.dy);
    control2 = Offset(bulge, end.dy);
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
    // Laid out across, the box is turned with the drawing: its canonical
    // sides are the text's the other way round.
    labelBox = Rect.fromCenter(
      center: mid,
      width: across ? size.height : size.width,
      height: across ? size.width : size.height,
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
    startLabelBox: _endBox(edge.startLabel, start, control1, style, across),
    endLabelBox: _endBox(edge.endLabel, end, control2, style, across),
  );
}

/// Where [text] sits beside the end of an edge at [at], the curve leaving
/// towards [towards]: a little along the edge and off to its side, clear
/// of the line and of the cap.
Rect? _endBox(
  String? text,
  Offset at,
  Offset towards,
  DiagramStyle style,
  bool across,
) {
  if (text == null || text.isEmpty) return null;
  final width = DiagramMetrics.textWidth(text, style.fontSize);
  final height = style.fontSize * style.lineHeight;
  var along = towards - at;
  final length = along.distance;
  along = length == 0 ? const Offset(0, 1) : along / length;
  final aside = Offset(-along.dy, along.dx);
  final reach = across ? height : width;
  final centre = at + along * (height + 4) + aside * (reach / 2 + 6);
  return Rect.fromCenter(
    center: centre,
    width: across ? height : width,
    height: across ? width : height,
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
