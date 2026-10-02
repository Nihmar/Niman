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

/// How far from an edge's end the text there begins, along the edge.
const double endTextGap = 4;

/// How far an edge keeps from a node it goes round.
const double _clearance = 16;

/// How far a cycle's way back bulges past the nodes it goes round.
const double _backBulge = 36;

/// The curve joining two placed nodes; [across] when the chart is drawn
/// left to right or right to left, and its label box is laid on its side.
///
/// [passing] are the nodes of the ranks the edge passes, which it bends
/// round: the ranks strictly between its ends, or for a cycle's way back
/// the ranks it spans, its own two included. The layout hands only those,
/// so an edge between neighbouring ranks — nearly every one — looks at
/// none.
LaidOutEdge routeFlowEdge(
  FlowEdge edge,
  Map<String, Rect> rects,
  DiagramStyle style, {
  required bool across,
  Iterable<Rect> passing = const [],
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
    final aside = _aside(start, end, passing);
    control1 = Offset(aside ?? start.dx, start.dy + bend);
    control2 = Offset(aside ?? end.dx, end.dy - bend);
  } else {
    // Upwards is a cycle's way back (the ranking sets those edges aside,
    // so every other edge runs down): straight up it would cross the very
    // edges it closes, and every node between. It leaves and comes back
    // by the nodes' sides and bulges past the nodes of the ranks it spans,
    // its own two included — by the right, unless a node stands right
    // beside one of its ends (a note, say) and none on the left.
    bool beside(Rect end, {required bool right}) => passing.any(
      (rect) =>
          (rect.center.dy - end.center.dy).abs() < 1 &&
          (right ? rect.left >= end.right : rect.right <= end.left),
    );
    final blockedRight = beside(from, right: true) || beside(to, right: true);
    final blockedLeft = beside(from, right: false) || beside(to, right: false);
    final right = !blockedRight || blockedLeft;
    var reach = right
        ? math.max(from.right, to.right)
        : math.min(from.left, to.left);
    for (final rect in passing) {
      reach = right ? math.max(reach, rect.right) : math.min(reach, rect.left);
    }
    final bulge = right ? reach + _backBulge : reach - _backBulge;
    start = Offset(right ? from.right : from.left, from.center.dy);
    end = Offset(right ? to.right : to.left, to.center.dy);
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

/// The x both control points of a downward edge from [start] to [end]
/// take to bend it round the nodes of the ranks it passes, or null when
/// none is in its way. An edge past a rank otherwise ran straight through
/// the node between its ends.
///
/// It goes round on the nearer side, its middle — where a cubic whose two
/// control points share an x bulges furthest, three quarters of the way to
/// them — clear of every node in the way.
double? _aside(Offset start, Offset end, Iterable<Rect> rects) {
  var left = double.infinity;
  var right = double.negativeInfinity;
  for (final rect in rects) {
    if (rect.top <= start.dy || rect.bottom >= end.dy) continue;
    final t = (rect.center.dy - start.dy) / (end.dy - start.dy);
    final x = start.dx + (end.dx - start.dx) * t;
    if (x < rect.left - _clearance || x > rect.right + _clearance) continue;
    left = math.min(left, rect.left);
    right = math.max(right, rect.right);
  }
  if (left > right) return null;
  final middle = (start.dx + end.dx) / 2;
  final goal = right - middle <= middle - left
      ? right + _clearance
      : left - _clearance;
  return (goal - middle / 4) * 4 / 3;
}

/// Where [text] sits beside the end of an edge at [at], the curve leaving
/// towards [towards]: from just past the end along the edge, and off to its
/// side clear of the line and of the widest cap. The layout leaves the
/// edge room for it between two ranks.
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
  // Along the edge and across it, in the canonical space this runs in.
  final alongExtent = across ? width : height;
  final asideExtent = across ? height : width;
  final centre =
      at +
      along * (alongExtent / 2 + endTextGap) +
      aside * (asideExtent / 2 + 10);
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
