/// The quadrant-chart model (#530): two axes, four quadrants and the points
/// placed on them.
///
/// Like the other models it carries no geometry; the layout places it and
/// the two drawings (canvas and SVG) share it.
library;

/// One point: its name and where it sits, both coordinates from 0 to 1.
final class QuadrantPoint {
  /// Creates a point.
  const new({
    required this.label,
    required this.x,
    required this.y,
    this.radius,
  });

  /// Its name.
  final String label;

  /// Where it sits across, from 0 (left) to 1 (right).
  final double x;

  /// Where it sits up, from 0 (bottom) to 1 (top).
  final double y;

  /// The radius its `radius:` asks for, or null for the default.
  final double? radius;
}

/// A parsed quadrant chart.
final class QuadrantChart {
  /// Creates a quadrant chart.
  const new({
    required this.quadrants,
    required this.points,
    this.title,
    this.xLow,
    this.xHigh,
    this.yLow,
    this.yHigh,
  });

  /// The quadrants' names, Mermaid's way round: top right, top left,
  /// bottom left, bottom right; null where none is written.
  final List<String?> quadrants;

  /// The points.
  final List<QuadrantPoint> points;

  /// The title, or null.
  final String? title;

  /// What the left end of the x axis means, or null.
  final String? xLow;

  /// What its right end means, or null.
  final String? xHigh;

  /// What the bottom of the y axis means, or null.
  final String? yLow;

  /// What its top means, or null.
  final String? yHigh;
}
