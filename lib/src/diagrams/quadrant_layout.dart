/// Laying a quadrant chart out (#530): a square plot of four quadrants,
/// its axes' ends written along it, its points and their names.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/quadrant_model.dart';

const double _margin = 12;

/// The plot's side.
const double _side = 360;

/// A point's radius when it asks for none.
const double quadrantPointRadius = 5;

/// One point placed: its dot and its name under it.
typedef QuadrantDot = ({
  Offset centre,
  double radius,
  Rect labelBox,
  String label,
});

/// A quadrant chart with every part placed.
typedef QuadrantLayout = ({
  Size size,
  Rect plot,
  List<({Rect rect, Rect? nameBox, String? name})> quadrants,
  List<QuadrantDot> dots,
  List<({Rect box, String text})> axisLabels,
  Rect? titleBox,
  String? title,
});

/// Lays [chart] out with [style].
QuadrantLayout layoutQuadrant(QuadrantChart chart, DiagramStyle style) {
  final fontSize = style.fontSize;
  final line = fontSize * style.lineHeight;
  double width(String? text) =>
      text == null ? 0 : DiagramMetrics.textWidth(text, fontSize);

  final title = chart.title;
  final titleSize = fontSize * 1.2;
  final titleHeight = title == null ? 0.0 : titleSize * style.lineHeight + 12;
  // The y axis's ends are written left of the plot, across.
  final left = _margin + math.max(width(chart.yLow), width(chart.yHigh)) + 8;
  final top = _margin + titleHeight;
  final plot = Rect.fromLTWH(left, top, _side, _side);
  const half = _side / 2;

  // Mermaid's quadrants: 1 top right, 2 top left, 3 bottom left, 4 bottom
  // right; a name sits at the top of its quadrant.
  final corners = [
    Rect.fromLTWH(plot.left + half, plot.top, half, half),
    Rect.fromLTWH(plot.left, plot.top, half, half),
    Rect.fromLTWH(plot.left, plot.top + half, half, half),
    Rect.fromLTWH(plot.left + half, plot.top + half, half, half),
  ];
  final quadrants = [
    for (var q = 0; q < 4; q++)
      (
        rect: corners[q],
        name: chart.quadrants[q],
        nameBox: chart.quadrants[q] == null
            ? null
            : Rect.fromLTWH(
                corners[q].left + 8,
                corners[q].top + 8,
                half - 16,
                line,
              ),
      ),
  ];

  final dots = <QuadrantDot>[];
  for (final point in chart.points) {
    final centre = Offset(
      plot.left + point.x * _side,
      plot.bottom - point.y * _side,
    );
    final radius = point.radius ?? quadrantPointRadius;
    final labelWidth = width(point.label);
    // Under the dot, kept inside the plot.
    final labelLeft = math.max(
      plot.left + 2,
      math.min(centre.dx - labelWidth / 2, plot.right - labelWidth - 2),
    );
    final below = centre.dy + radius + 2;
    final labelTop = below + line > plot.bottom
        ? centre.dy - radius - 2 - line
        : below;
    dots.add((
      centre: centre,
      radius: radius,
      label: point.label,
      labelBox: Rect.fromLTWH(labelLeft, labelTop, labelWidth, line),
    ));
  }

  final axisLabels = <({Rect box, String text})>[
    if (chart.xLow != null)
      (
        box: Rect.fromLTWH(plot.left, plot.bottom + 6, width(chart.xLow), line),
        text: chart.xLow!,
      ),
    if (chart.xHigh != null)
      (
        box: Rect.fromLTWH(
          plot.right - width(chart.xHigh),
          plot.bottom + 6,
          width(chart.xHigh),
          line,
        ),
        text: chart.xHigh!,
      ),
    if (chart.yLow != null)
      (
        box: Rect.fromLTWH(
          left - 8 - width(chart.yLow),
          plot.bottom - line,
          width(chart.yLow),
          line,
        ),
        text: chart.yLow!,
      ),
    if (chart.yHigh != null)
      (
        box: Rect.fromLTWH(
          left - 8 - width(chart.yHigh),
          plot.top,
          width(chart.yHigh),
          line,
        ),
        text: chart.yHigh!,
      ),
  ];

  var drawing = plot.right + _margin;
  Rect? titleBox;
  if (title != null) {
    final titleWidth = DiagramMetrics.textWidth(title, titleSize);
    drawing = math.max(drawing, titleWidth + 2 * _margin);
    titleBox = Rect.fromCenter(
      center: Offset(drawing / 2, _margin + (titleHeight - 12) / 2),
      width: titleWidth,
      height: titleHeight - 12,
    );
  }
  final xLabels = chart.xLow != null || chart.xHigh != null;
  return (
    size: Size(drawing, plot.bottom + (xLabels ? line + 6 : 0) + _margin),
    plot: plot,
    quadrants: quadrants,
    dots: dots,
    axisLabels: axisLabels,
    titleBox: titleBox,
    title: title,
  );
}
