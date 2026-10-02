/// Where a user journey's parts sit once laid out (#530).
///
/// Geometry only, in logical pixels: the canvas and the SVG both draw from
/// it, so neither keeps a measurement of its own.
library;

import 'package:flutter/painting.dart';

/// A user journey with every part placed.
final class JourneyLayout {
  /// Creates a layout.
  const new({
    required this.size,
    required this.sections,
    required this.tasks,
    required this.legend,
    this.title,
    this.titleBox,
  });

  /// The drawing's size.
  final Size size;

  /// The named sections' headers, left to right.
  final List<LaidOutJourneySection> sections;

  /// The tasks, their actors' dots and their faces.
  final List<LaidOutJourneyTask> tasks;

  /// The actors' legend, top to bottom.
  final List<LaidOutJourneyActor> legend;

  /// The title, or null.
  final String? title;

  /// Where the title sits, or null.
  final Rect? titleBox;
}

/// One section's header.
final class LaidOutJourneySection {
  /// Creates a placed header.
  const new({required this.rect, required this.lines});

  /// Its box, over its tasks.
  final Rect rect;

  /// Its name, wrapped.
  final List<String> lines;
}

/// One task: its box, the dots of who took part, and the face of how it
/// went.
final class LaidOutJourneyTask {
  /// Creates a placed task.
  const new({
    required this.box,
    required this.textBox,
    required this.lines,
    required this.dots,
    required this.face,
    required this.mood,
  });

  /// Its box.
  final Rect box;

  /// Where its text sits inside the box.
  final Rect textBox;

  /// Its text, wrapped.
  final List<String> lines;

  /// Its actors' dots: where each is, and the actor's place.
  final List<(Offset, int)> dots;

  /// The face, the higher the better it went.
  final Rect face;

  /// The face's mood: 1 a smile, 0 a straight mouth, -1 a frown.
  final int mood;
}

/// One row of the actors' legend.
final class LaidOutJourneyActor {
  /// Creates a placed row.
  const new({required this.dot, required this.textBox, required this.name});

  /// The actor's dot.
  final Offset dot;

  /// Where the name sits.
  final Rect textBox;

  /// The actor's name.
  final String name;
}
