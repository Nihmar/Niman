/// Where a timeline's parts sit once laid out (#530).
///
/// Geometry only, in logical pixels: the canvas and the SVG both draw from
/// it, so neither keeps a measurement of its own.
library;

import 'package:flutter/painting.dart';

/// A timeline with every part placed.
final class TimelineLayout {
  /// Creates a layout.
  const new({
    required this.size,
    required this.sections,
    required this.boxes,
    required this.connectors,
    required this.axis,
    this.title,
    this.titleBox,
  });

  /// The drawing's size.
  final Size size;

  /// The named sections' headers, left to right.
  final List<LaidOutTimelineBox> sections;

  /// The periods and their events.
  final List<LaidOutTimelineBox> boxes;

  /// The dashed lines from each period down to its events.
  final List<(Offset, Offset)> connectors;

  /// The time line's two ends: it runs left to right, under the periods.
  final (Offset, Offset) axis;

  /// The title, or null.
  final String? title;

  /// Where the title sits, or null.
  final Rect? titleBox;
}

/// One box of a timeline: a section's header, a period or an event.
final class LaidOutTimelineBox {
  /// Creates a placed box.
  const new({
    required this.rect,
    required this.lines,
    required this.colour,
    this.event = false,
  });

  /// Its box.
  final Rect rect;

  /// Its text, wrapped.
  final List<String> lines;

  /// Its slot in the palette's series, or null for the neutral fill.
  final int? colour;

  /// Whether it is an event, drawn lighter than its period.
  final bool event;
}
