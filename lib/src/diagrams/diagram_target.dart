/// The primitives one drawing uses (#530).
///
/// The renderer walks a layout once and calls these; a Flutter canvas
/// implements them with a `Canvas`, an export with an SVG string.
/// Every shape is reduced to polygons, curves, lines and text, so the two
/// implementations stay small and cannot drift.
library;

import 'package:flutter/painting.dart';

/// A surface the shared diagram renderer draws onto.
abstract interface class DiagramTarget {
  /// Fills and/or strokes a closed [points] polygon.
  void polygon(
    List<Offset> points, {
    Color? fill,
    Color? stroke,
    double strokeWidth = 1,
  });

  /// Draws a cubic Bézier from [from] to [to].
  void cubic(
    Offset from,
    Offset control1,
    Offset control2,
    Offset to, {
    required Color color,
    double strokeWidth = 1,
    bool dashed = false,
  });

  /// Draws a straight line, optionally dashed.
  void line(
    Offset from,
    Offset to, {
    required Color color,
    double strokeWidth = 1,
    bool dashed = false,
  });

  /// Draws [lines] left-aligned or centred inside [box].
  void text(
    List<String> lines,
    Rect box, {
    required Color color,
    required double fontSize,
    bool alignLeft = false,
    FontWeight weight = FontWeight.normal,
  });
}
