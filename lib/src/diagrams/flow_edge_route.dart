/// The curve an edge is drawn along between two placed nodes, and the box
/// its label sits in (#530), in canonical space.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_edge_curve.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/layered_edge.dart';

/// How far from an edge's end the text there begins, along the edge.
const double endTextGap = 4;

/// What an edge ends on: the rectangle of a node, or of a subgraph's box.
typedef FlowEnd = ({Rect rect, bool box});

/// The curve joining two placed ends, and where its texts go; [across] when
/// the chart is drawn left to right or right to left, and its label box is
/// laid on its side.
///
/// [routed] is the layout's route for the edge: the points it runs through,
/// a stand-in on each rank it passes and one for its label. A downward edge
/// leaves its tail's bottom at [startX] and reaches its head's top at
/// [endX]; the layout spreads the edges sharing a side along it, and
/// without them the middles are used. An edge the layout turned back to
/// break a cycle leaves the top and reaches the bottom. An end on a
/// subgraph's box is anchored on its outline already. With no stand-ins it
/// is one cubic; with some it is a smooth curve through them.
///
/// An edge with no route — a self loop, a tie between a note and its node —
/// or one the layout could not rank is drawn beside its ends: a loop on the
/// right of the node, a flat edge from side to side.
LaidOutEdge routeFlowEdge(
  FlowEdge edge,
  FlowEnd? from,
  FlowEnd? to,
  LayeredEdge? routed,
  DiagramStyle style, {
  required bool across,
  double? startX,
  double? endX,
}) {
  if (from == null || to == null) {
    return LaidOutEdge(
      edge: edge,
      start: Offset.zero,
      control1: Offset.zero,
      control2: Offset.zero,
      end: Offset.zero,
    );
  }
  final List<Offset> path;
  Offset? labelAt;
  if (edge.from == edge.to) {
    path = _loop(from.rect);
  } else if (routed != null && routed.points.length >= 2) {
    path = _ranked(routed, from, to, startX, endX);
    final centre = routed.labelCenter;
    if (centre != null) labelAt = Offset(centre.x, centre.y);
  } else if (routed?.flow == LayeredEdgeFlow.free) {
    path = _free(from, to);
  } else if ((to.rect.center.dy - from.rect.center.dy).abs() < 1) {
    path = _flat(from.rect, to.rect);
  } else {
    final down = to.rect.center.dy > from.rect.center.dy;
    path = flowCubic(
      Offset(startX ?? from.rect.center.dx, _side(from.rect, bottom: down)),
      Offset(endX ?? to.rect.center.dx, _side(to.rect, bottom: !down)),
    );
  }

  final label = edge.label == null || edge.label!.isEmpty ? null : edge.label;
  Rect? labelBox;
  if (label != null) {
    final size = Size(
      DiagramMetrics.textWidth(label, style.fontSize) +
          style.edgeLabelPadding.horizontal,
      style.fontSize * style.lineHeight + style.edgeLabelPadding.vertical,
    );
    final drawn = LaidOutEdge.along(edge: edge, path: path);
    // The label sits where its stand-in is, on the line the curve makes
    // of its points, or halfway along an edge that has none. Laid out
    // across, the box is turned with the drawing: its canonical sides are
    // the text's the other way round.
    labelBox = Rect.fromCenter(
      center: labelAt == null
          ? drawn.at(0.5)
          : flowNearestOnPath(path, labelAt),
      width: across ? size.height : size.width,
      height: across ? size.width : size.height,
    );
  }
  return LaidOutEdge.along(
    edge: edge,
    path: path,
    label: label,
    labelBox: labelBox,
    startLabelBox: _endBox(edge.startLabel, path.first, path[1], style, across),
    endLabelBox: _endBox(
      edge.endLabel,
      path.last,
      path[path.length - 2],
      style,
      across,
    ),
  );
}

/// A self loop: out of the right of the node and back into it.
List<Offset> _loop(Rect node) {
  final dy = node.height * 0.22;
  return [
    Offset(node.right, node.center.dy - dy),
    Offset(node.right + 40, node.center.dy - 34),
    Offset(node.right + 40, node.center.dy + 34),
    Offset(node.right, node.center.dy + dy),
  ];
}

/// Two ends in one rank: from the side of one to the side of the other.
List<Offset> _flat(Rect from, Rect to) {
  final right = to.center.dx >= from.center.dx;
  return flowFlatCubic(
    Offset(right ? from.right : from.left, from.center.dy),
    Offset(right ? to.left : to.right, to.center.dy),
  );
}

/// An edge between a subgraph's box and what it holds, which no rank can
/// honour: a plain curve between the box's outline and the node, at the
/// node's middle. Out of a box it leaves the bottom and reaches the node's
/// bottom; into one it leaves the node's top and reaches the box's top.
List<Offset> _free(FlowEnd from, FlowEnd to) {
  // The end that is inside the other: the smaller.
  final inner =
      from.rect.width * from.rect.height <= to.rect.width * to.rect.height
      ? from.rect
      : to.rect;
  final x = inner.center.dx;
  final leavingBox = from.box;
  final start = Offset(
    x,
    leavingBox ? from.rect.bottom : _side(from.rect, bottom: false),
  );
  final end = Offset(
    x,
    to.box ? to.rect.top : _side(to.rect, bottom: leavingBox),
  );
  return flowCubic(start, end);
}

/// The route's points with the ends put on the nodes' sides.
List<Offset> _ranked(
  LayeredEdge routed,
  FlowEnd from,
  FlowEnd to,
  double? startX,
  double? endX,
) {
  final points = [for (final p in routed.points) Offset(p.x, p.y)];
  final down = !routed.reversed;
  final start = from.box
      ? points.first
      : Offset(startX ?? from.rect.center.dx, _side(from.rect, bottom: down));
  final end = to.box
      ? points.last
      : Offset(endX ?? to.rect.center.dx, _side(to.rect, bottom: !down));
  if (points.length == 2) return flowCubic(start, end);
  return flowBasisPath([start, ...points.sublist(1, points.length - 1), end]);
}

double _side(Rect rect, {required bool bottom}) =>
    bottom ? rect.bottom : rect.top;

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
