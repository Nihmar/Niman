/// How big a flowchart node is drawn (#530): its text plus padding, widened
/// for its shape — and a class box's compartments, which the renderer draws
/// from the same numbers.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// The size of [node]'s box, its label already broken into [lines].
Size flowNodeSize(FlowNode node, List<String> lines, DiagramStyle style) {
  switch (node.shape) {
    case FlowNodeShape.start:
      return const Size.square(18);
    case FlowNodeShape.end:
      return const Size.square(22);
    case FlowNodeShape.bar:
      // Across the flow: the layout keeps it on this side.
      return const Size(72, 8);
    case FlowNodeShape.classBox:
      return _classBox(node, style);
    case _:
      break;
  }
  // A card is as big as all its lines, its outline's room added as for
  // any label.
  final shown = node.sections.isNotEmpty ? node.stackedLines : lines;
  var text = 0.0;
  for (final line in shown) {
    text = math.max(text, DiagramMetrics.textWidth(line, style.fontSize));
  }
  var width = text + style.nodePadding.horizontal;
  var height =
      shown.length * style.fontSize * style.lineHeight +
      style.nodePadding.vertical;
  switch (node.shape) {
    case FlowNodeShape.circle:
      final diameter = math.max(width, height) * 1.3;
      width = diameter;
      height = diameter;
    case FlowNodeShape.diamond:
      // A choice, written with no text, is a small diamond.
      if (text == 0) return const Size.square(28);
      width *= 1.7;
      height *= 1.9;
    case FlowNodeShape.hexagon:
      width *= 1.35;
    case FlowNodeShape.stadium:
      width += height * 0.4;
    case FlowNodeShape.subroutine:
      width += 12;
    case FlowNodeShape.database:
      height += 10;
    case _:
      break;
  }
  return Size(math.max(width, 34), math.max(height, 28));
}

/// The heights of a class box's compartments, top to bottom: its name,
/// then each list of members — an empty one a thin band, as UML draws it.
List<double> classSectionHeights(FlowNode node, DiagramStyle style) {
  final line = style.fontSize * style.lineHeight;
  final pad = style.nodePadding.vertical / 2;
  final heights = <double>[];
  for (var i = 0; i < node.sections.length; i++) {
    final lines = node.sections[i].length;
    heights.add(lines == 0 ? pad : lines * line + (i == 0 ? 2 * pad : pad));
  }
  return heights;
}

Size _classBox(FlowNode node, DiagramStyle style) {
  var widest = 0.0;
  for (final section in node.sections) {
    for (final line in section) {
      widest = math.max(widest, DiagramMetrics.textWidth(line, style.fontSize));
    }
  }
  final height = classSectionHeights(
    node,
    style,
  ).fold<double>(0, (sum, h) => sum + h);
  return Size(
    math.max(widest + style.nodePadding.horizontal, 80),
    math.max(height, 28),
  );
}
