/// A laid-out diagram of one of the kinds the engine draws (#530).
///
/// Each kind lays out to geometry of its own: a graph of boxes (a
/// flowchart, a mind map, a class, state or ER diagram), a sequence, a
/// pie, a Gantt chart, a timeline, a user journey, a git graph, a kanban
/// board, a quadrant chart, an xy chart, a Sankey diagram, a block
/// diagram, a packet diagram, a radar chart. The painter and
/// the SVG export dispatch on this one type, so the engine grows a kind at
/// a time and no call site learns about each.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/block_layout.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/gantt_geometry.dart';
import 'package:niman/src/diagrams/git_graph_geometry.dart';
import 'package:niman/src/diagrams/journey_geometry.dart';
import 'package:niman/src/diagrams/kanban_layout.dart';
import 'package:niman/src/diagrams/packet_layout.dart';
import 'package:niman/src/diagrams/pie_geometry.dart';
import 'package:niman/src/diagrams/quadrant_layout.dart';
import 'package:niman/src/diagrams/radar_layout.dart';
import 'package:niman/src/diagrams/sankey_layout.dart';
import 'package:niman/src/diagrams/sequence_geometry.dart';
import 'package:niman/src/diagrams/timeline_geometry.dart';
import 'package:niman/src/diagrams/xy_chart_layout.dart';

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

/// A timeline.
final class TimelineDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed timeline.
  final TimelineLayout layout;

  @override
  Size get size => layout.size;
}

/// A user journey.
final class JourneyDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed journey.
  final JourneyLayout layout;

  @override
  Size get size => layout.size;
}

/// A git graph.
final class GitGraphDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed graph.
  final GitGraphLayout layout;

  @override
  Size get size => layout.size;
}

/// A block diagram.
final class BlockDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed diagram.
  final BlockLayout layout;

  @override
  Size get size => layout.size;
}

/// A packet diagram.
final class PacketDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed diagram.
  final PacketLayout layout;

  @override
  Size get size => layout.size;
}

/// A radar chart.
final class RadarDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed chart.
  final RadarLayout layout;

  @override
  Size get size => layout.size;
}

/// A kanban board.
final class KanbanDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed board.
  final KanbanLayout layout;

  @override
  Size get size => layout.size;
}

/// A quadrant chart.
final class QuadrantDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed chart.
  final QuadrantLayout layout;

  @override
  Size get size => layout.size;
}

/// An xy chart.
final class XyChartDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed chart.
  final XyLayout layout;

  @override
  Size get size => layout.size;
}

/// A Sankey diagram.
final class SankeyDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed diagram.
  final SankeyLayout layout;

  @override
  Size get size => layout.size;
}
