/// Where a Gantt chart's parts sit once laid out (#530).
///
/// Geometry only, in logical pixels: the canvas and the SVG both draw from
/// it, so neither keeps a measurement of its own.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/gantt_model.dart';

/// A Gantt chart with every part placed.
final class GanttLayout {
  /// Creates a layout.
  const new({
    required this.size,
    required this.plot,
    required this.bands,
    required this.bars,
    required this.ticks,
    this.title,
    this.titleBox,
  });

  /// The drawing's size.
  final Size size;

  /// The area the bars are drawn in: time across, rows down.
  final Rect plot;

  /// The sections' bands, top to bottom.
  final List<LaidOutBand> bands;

  /// The tasks' bars, in order.
  final List<LaidOutBar> bars;

  /// The axis's ticks, left to right.
  final List<LaidOutTick> ticks;

  /// The title, or null.
  final String? title;

  /// Where the title sits, or null.
  final Rect? titleBox;
}

/// One section's band across the chart, and its name beside it.
final class LaidOutBand {
  /// Creates a placed band.
  const new({
    required this.rect,
    required this.name,
    required this.nameBox,
    required this.shaded,
  });

  /// The band, the name column included.
  final Rect rect;

  /// The section's name.
  final String name;

  /// Where the name sits.
  final Rect nameBox;

  /// Whether the band is shaded: every other one is.
  final bool shaded;
}

/// One task's bar — or a milestone's diamond — and its label.
final class LaidOutBar {
  /// Creates a placed bar.
  const new({required this.task, required this.rect, required this.labelBox});

  /// The model.
  final GanttTask task;

  /// The bar; a milestone's diamond fits it.
  final Rect rect;

  /// Where the label sits: on the bar when it fits, beside it when not.
  final Rect labelBox;

  /// Whether the label sits on the bar.
  bool get labelInside => rect.contains(labelBox.center) && !task.milestone;
}

/// One tick of the time axis.
final class LaidOutTick {
  /// Creates a placed tick.
  const new({required this.x, required this.label, required this.labelBox});

  /// Where it falls across the plot.
  final double x;

  /// The date it marks, as the axis writes it.
  final String label;

  /// Where the date is written, under the axis.
  final Rect labelBox;
}
