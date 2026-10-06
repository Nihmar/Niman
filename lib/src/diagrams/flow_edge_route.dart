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

/// How many steps along a curve are checked for the nodes it goes round.
const int _samples = 24;

/// How far a cycle's way back bulges past the nodes it goes round.
const double _backBulge = 36;

/// The curve joining two placed nodes; [across] when the chart is drawn
/// left to right or right to left, and its label box is laid on its side.
///
/// A downward edge leaves its node's bottom at [startX] and reaches the
/// other's top at [endX]: the layout spreads the edges sharing a side
/// along it. Without them it uses the middles.
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
  double? startX,
  double? endX,
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
    start = Offset(startX ?? from.center.dx, from.bottom);
    end = Offset(endX ?? to.center.dx, to.top);
    final bend = (end.dy - start.dy) * _curveBend;
    final aside = _aside(start, end, bend, passing);
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

/// The x both control points of a downward edge from [start] to [end],
/// bending [bend] down from one and up to the other, take to go round the
/// nodes of the ranks it passes; null when none is in its way. An edge
/// past a rank otherwise ran straight through the node between its ends.
///
/// It goes round on the nearer side, and far enough that the curve is
/// clear of every node in its way all down that node's height — not only
/// at its middle, where it bulges most: a curve checked there alone still
/// cut the corner of a node lower down.
double? _aside(Offset start, Offset end, double bend, Iterable<Rect> rects) {
  final between = [
    for (final rect in rects)
      if (rect.top > start.dy && rect.bottom < end.dy) rect,
  ];
  final blocking = [
    for (final rect in between)
      if (_across(start, end, rect)) rect,
  ];
  if (blocking.isEmpty) return null;
  // Going round the nodes in the way can lead into others of their ranks:
  // those join the ones to go round, until the curve meets none.
  for (var round = 0; round <= between.length; round++) {
    final control = _control(start, end, bend, blocking);
    final hit = between.where(
      (rect) =>
          !blocking.contains(rect) && _meets(start, end, bend, control, rect),
    );
    if (hit.isEmpty) return control;
    blocking.addAll(hit);
  }
  return _control(start, end, bend, blocking);
}

/// The control x that takes the curve round [blocking] on its nearer side.
double _control(Offset start, Offset end, double bend, List<Rect> blocking) {
  var left = double.infinity;
  var right = double.negativeInfinity;
  for (final rect in blocking) {
    left = math.min(left, rect.left);
    right = math.max(right, rect.right);
  }
  final middle = (start.dx + end.dx) / 2;
  final goRight = right - middle <= middle - left;
  final goal = goRight ? right + _clearance : left - _clearance;
  // x(t) = u³·start + t³·end + (3u²t + 3ut²)·cx: for every t whose point
  // is level with a node in the way, cx puts x(t) past the goal.
  double? control;
  for (var i = 1; i < _samples; i++) {
    final t = i / _samples;
    final u = 1 - t;
    final y = _y(start, end, bend, t);
    final level = blocking.any(
      (rect) => y >= rect.top - _clearance && y <= rect.bottom + _clearance,
    );
    if (!level) continue;
    final fixed = u * u * u * start.dx + t * t * t * end.dx;
    final needed = (goal - fixed) / (3 * u * u * t + 3 * u * t * t);
    control = control == null
        ? needed
        : (goRight ? math.max(control, needed) : math.min(control, needed));
  }
  return control ?? (goal - middle / 4) * 4 / 3;
}

/// Whether the curve with both control points at [control] meets [rect].
bool _meets(Offset start, Offset end, double bend, double control, Rect rect) {
  for (var i = 1; i < _samples; i++) {
    final t = i / _samples;
    final u = 1 - t;
    final x =
        u * u * u * start.dx +
        (3 * u * u * t + 3 * u * t * t) * control +
        t * t * t * end.dx;
    if (rect
        .inflate(_clearance / 2)
        .contains(Offset(x, _y(start, end, bend, t)))) {
      return true;
    }
  }
  return false;
}

/// The curve's y at [t]: its control points [bend] below its start and
/// above its end.
double _y(Offset start, Offset end, double bend, double t) {
  final u = 1 - t;
  return u * u * u * start.dy +
      3 * u * u * t * (start.dy + bend) +
      3 * u * t * t * (end.dy - bend) +
      t * t * t * end.dy;
}

/// Whether the straight line from [start] to [end] passes [rect], level
/// with its middle.
bool _across(Offset start, Offset end, Rect rect) {
  final t = (rect.center.dy - start.dy) / (end.dy - start.dy);
  final x = start.dx + (end.dx - start.dx) * t;
  return x >= rect.left - _clearance && x <= rect.right + _clearance;
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
