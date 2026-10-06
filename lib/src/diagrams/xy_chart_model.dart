/// The xy-chart model (#530): categories along one axis, values along the
/// other, and the bars and lines that plot them.
///
/// Like the other models it carries no geometry; the layout places it and
/// the two drawings (canvas and SVG) share it.
library;

/// How a series is drawn.
enum XySeriesKind {
  /// `bar`: a bar a category.
  bar,

  /// `line`: a point a category, joined.
  line,
}

/// One series: a value a category.
final class XySeries {
  /// Creates a series.
  const new({required this.kind, required this.values, this.name});

  /// How it is drawn.
  final XySeriesKind kind;

  /// Its values, one a category.
  final List<double> values;

  /// Its name, for the legend, or null.
  final String? name;
}

/// A parsed xy chart.
final class XyChart {
  /// Creates an xy chart.
  const new({
    required this.categories,
    required this.series,
    this.horizontal = false,
    this.title,
    this.xTitle,
    this.yTitle,
    this.yRange,
  });

  /// The categories, in order.
  final List<String> categories;

  /// The series, in the order they were written.
  final List<XySeries> series;

  /// Whether the categories run down and the values across.
  final bool horizontal;

  /// The title, or null.
  final String? title;

  /// The category axis's title, or null.
  final String? xTitle;

  /// The value axis's title, or null.
  final String? yTitle;

  /// The value axis's range as written, or null to fit the values.
  final (double, double)? yRange;
}
