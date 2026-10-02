/// A laid-out diagram of one of the kinds the engine draws (#530).
///
/// A graph of boxes (a flowchart, a mind map, a class, state or ER
/// diagram), a sequence, a pie and a Gantt chart lay out to different
/// geometry; the painter and the SVG export dispatch
/// on this one type, so the engine grows a kind at a time and no call site
/// learns about each.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/gantt_geometry.dart';
import 'package:niman/src/diagrams/pie_geometry.dart';
import 'package:niman/src/diagrams/sequence_geometry.dart';

/// A laid-out diagram.
sealed class DiagramDrawing {
  /// Const for subclasses.
  const new();

  /// The drawing's size.
  Size get size;
}

/// A flowchart or a mind map.
final class FlowDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed chart.
  final DiagramLayout layout;

  @override
  Size get size => layout.size;
}

/// A sequence diagram.
final class SequenceDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed sequence.
  final SequenceLayout layout;

  @override
  Size get size => layout.size;
}

/// A pie chart.
final class PieDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed pie.
  final PieLayout layout;

  @override
  Size get size => layout.size;
}

/// A Gantt chart.
final class GanttDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed chart.
  final GanttLayout layout;

  @override
  Size get size => layout.size;
}
