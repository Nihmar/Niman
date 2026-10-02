/// What parsing and laying a diagram out produced (#530): a drawing, or the
/// error to fall back to source with.
library;

import 'package:niman/src/diagrams/block_layout.dart';
import 'package:niman/src/diagrams/diagram_drawing.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flowchart_layout.dart';
import 'package:niman/src/diagrams/gantt_layout.dart';
import 'package:niman/src/diagrams/git_graph_layout.dart';
import 'package:niman/src/diagrams/journey_layout.dart';
import 'package:niman/src/diagrams/kanban_layout.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/packet_layout.dart';
import 'package:niman/src/diagrams/pie_layout.dart';
import 'package:niman/src/diagrams/quadrant_layout.dart';
import 'package:niman/src/diagrams/radar_layout.dart';
import 'package:niman/src/diagrams/sankey_layout.dart';
import 'package:niman/src/diagrams/sequence_layout.dart';
import 'package:niman/src/diagrams/timeline_layout.dart';
import 'package:niman/src/diagrams/treemap_layout.dart';
import 'package:niman/src/diagrams/xy_chart_layout.dart';

/// The outcome for one diagram source at one style.
sealed class DiagramResult {
  /// Const for subclasses.
  const new();
}

/// The diagram parsed and was laid out.
final class DiagramReady extends DiagramResult {
  /// Wraps a laid-out [drawing].
  const new(this.drawing);

  /// The drawing to paint.
  final DiagramDrawing drawing;
}

/// The diagram did not parse; the source is shown instead.
final class DiagramFailed extends DiagramResult {
  /// Wraps the [error].
  const new(this.error);

  /// The line and message to report.
  final MermaidParseException error;
}

/// Parses [source] and lays it out at [style], catching a syntax error.
DiagramResult resolveDiagram(String source, DiagramStyle style) {
  try {
    return DiagramReady(switch (parseMermaid(source)) {
      MermaidFlowchart(:final chart) => FlowDrawing(
        layoutFlowchart(chart, style),
      ),
      MermaidSequence(:final sequence) => SequenceDrawing(
        layoutSequence(sequence, style),
      ),
      MermaidPie(:final pie) => PieDrawing(layoutPie(pie, style)),
      MermaidGantt(:final gantt) => GanttDrawing(layoutGantt(gantt, style)),
      MermaidTimeline(:final timeline) => TimelineDrawing(
        layoutTimeline(timeline, style),
      ),
      MermaidJourney(:final journey) => JourneyDrawing(
        layoutJourney(journey, style),
      ),
      MermaidGitGraph(:final graph) => GitGraphDrawing(
        layoutGitGraph(graph, style),
      ),
      MermaidKanban(:final board) => KanbanDrawing(layoutKanban(board, style)),
      MermaidQuadrant(:final chart) => QuadrantDrawing(
        layoutQuadrant(chart, style),
      ),
      MermaidXyChart(:final chart) => XyChartDrawing(
        layoutXyChart(chart, style),
      ),
      MermaidSankey(:final chart) => SankeyDrawing(layoutSankey(chart, style)),
      MermaidBlock(:final diagram) => BlockDrawing(layoutBlock(diagram, style)),
      MermaidPacket(:final chart) => PacketDrawing(layoutPacket(chart, style)),
      MermaidRadar(:final chart) => RadarDrawing(layoutRadar(chart, style)),
      MermaidTreemap(:final chart) => TreemapDrawing(
        layoutTreemap(chart, style),
      ),
    });
  } on MermaidParseException catch (error) {
    return DiagramFailed(error);
  }
}
