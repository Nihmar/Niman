/// Turning a flowchart laid out in canonical space to its direction
/// (#530).
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// Turns canonical geometry into the chart's direction.
final class FlowOrientation {
  /// Turns geometry whose bounds start at (`minX`, `minY`) and are [width]
  /// by [height] in canonical space to [direction].
  new({
    required this.direction,
    required this._minX,
    required this._minY,
    required this.width,
    required this.height,
  });

  /// The direction the chart is drawn in.
  final FlowDirection direction;
  final double _minX;
  final double _minY;

  /// The canonical width: across the ranks.
  final double width;

  /// The canonical height: along the ranks.
  final double height;

  /// The drawing's size once turned.
  Size get size =>
      direction.isVertical ? Size(width, height) : Size(height, width);

  /// [p], turned.
  Offset point(Offset p) {
    final x = p.dx - _minX;
    final y = p.dy - _minY;
    return switch (direction) {
      FlowDirection.topDown => Offset(x, y),
      FlowDirection.bottomUp => Offset(x, height - y),
      FlowDirection.leftRight => Offset(y, x),
      FlowDirection.rightLeft => Offset(height - y, x),
    };
  }

  /// [r], turned.
  Rect rect(Rect r) {
    final a = point(r.topLeft);
    final b = point(r.bottomRight);
    return Rect.fromLTRB(
      math.min(a.dx, b.dx),
      math.min(a.dy, b.dy),
      math.max(a.dx, b.dx),
      math.max(a.dy, b.dy),
    );
  }

  /// [edge], turned.
  LaidOutEdge edge(LaidOutEdge edge) => LaidOutEdge(
    edge: edge.edge,
    start: point(edge.start),
    control1: point(edge.control1),
    control2: point(edge.control2),
    end: point(edge.end),
    label: edge.label,
    labelBox: edge.labelBox == null ? null : rect(edge.labelBox!),
    startLabelBox: edge.startLabelBox == null
        ? null
        : rect(edge.startLabelBox!),
    endLabelBox: edge.endLabelBox == null ? null : rect(edge.endLabelBox!),
  );

  /// [sub], turned: its title is text, kept its size and put at the top
  /// left of the turned box, where the box's title band has come to be.
  LaidOutSubgraph subgraph(LaidOutSubgraph sub) {
    final box = rect(sub.rect);
    return LaidOutSubgraph(
      subgraph: sub.subgraph,
      rect: box,
      titleRect: Rect.fromLTWH(
        box.left + 8,
        box.top + 4,
        sub.titleRect.width,
        sub.titleRect.height,
      ),
      title: sub.title,
    );
  }
}
