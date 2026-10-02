/// The radar chart model (#530): its axes round a centre and the curves
/// that give each axis a value.
///
/// Like the other models it carries no geometry; the layout places it and
/// the two drawings (canvas and SVG) share it.
library;

/// The rings a radar chart's scale is drawn with.
enum RadarGraticule {
  /// Circles round the centre, Mermaid's default.
  circle,

  /// Polygons through the axes.
  polygon,
}

/// One axis: its id, the name curves give values by, and its label.
final class RadarAxis {
  /// Creates an axis.
  const new({required this.id, required this.label});

  /// Its id.
  final String id;

  /// What is written at its end.
  final String label;
}

/// One curve: its label and a value for each axis, in the axes' order.
final class RadarCurve {
  /// Creates a curve.
  const new({required this.label, required this.values});

  /// Its name in the legend.
  final String label;

  /// Its values, one an axis.
  final List<double> values;
}

/// A parsed radar chart.
final class RadarChart {
  /// Creates a radar chart.
  const new({
    required this.axes,
    required this.curves,
    required this.min,
    required this.max,
    this.ticks = 5,
    this.graticule = RadarGraticule.circle,
    this.showLegend = true,
    this.title,
  });

  /// The axes, clockwise from the top.
  final List<RadarAxis> axes;

  /// The curves, in the order they were written.
  final List<RadarCurve> curves;

  /// The value at the centre.
  final double min;

  /// The value at the outer ring.
  final double max;

  /// How many rings the scale is drawn with.
  final int ticks;

  /// The rings' shape.
  final RadarGraticule graticule;

  /// Whether the curves are named in a legend.
  final bool showLegend;

  /// The title, if any.
  final String? title;
}
