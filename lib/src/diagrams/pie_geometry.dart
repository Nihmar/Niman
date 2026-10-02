/// Where a pie chart's parts sit once laid out (#530).
///
/// Geometry only, in logical pixels: the canvas and the SVG both draw from
/// it, so neither keeps a measurement of its own.
library;

import 'package:flutter/painting.dart';

/// A pie chart with every part placed.
final class PieLayout {
  /// Creates a layout.
  const new({
    required this.size,
    required this.center,
    required this.radius,
    required this.slices,
    required this.legend,
    this.title,
    this.titleBox,
  });

  /// The drawing's size.
  final Size size;

  /// The pie's centre.
  final Offset center;

  /// The pie's radius.
  final double radius;

  /// The slices, clockwise from twelve o'clock.
  final List<LaidOutSlice> slices;

  /// The legend's rows, top to bottom.
  final List<LaidOutLegendRow> legend;

  /// The title, or null.
  final String? title;

  /// Where the title sits, or null.
  final Rect? titleBox;
}

/// One slice of the pie.
final class LaidOutSlice {
  /// Creates a placed slice.
  const new({
    required this.outline,
    required this.colour,
    this.percent,
    this.percentAt,
  });

  /// Its outline: the centre and the points of its arc.
  final List<Offset> outline;

  /// Its slot in the palette's series.
  final int colour;

  /// Its share, written on it ("42%"), or null where it has no room.
  final String? percent;

  /// Where the share is written, or null.
  final Offset? percentAt;
}

/// One row of the legend: a swatch of a slice's colour and its text.
final class LaidOutLegendRow {
  /// Creates a placed row.
  const new({
    required this.swatch,
    required this.textBox,
    required this.text,
    required this.colour,
  });

  /// The square in the slice's colour.
  final Rect swatch;

  /// Where the text sits.
  final Rect textBox;

  /// The slice's label, and its value with `showData`.
  final String text;

  /// The slice's slot in the palette's series.
  final int colour;
}
