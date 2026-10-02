/// Diagrams as SVG for an exported page (#530).
///
/// The export's half of the one drawing: it parses the fence's source and
/// walks the same layout the screen paints, through the SVG target. A
/// source that does not parse comes back null, for the caller to keep as a
/// code block.
library;

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/diagrams/architecture_renderer.dart';
import 'package:niman/src/diagrams/block_renderer.dart';
import 'package:niman/src/diagrams/diagram_drawing.dart';
import 'package:niman/src/diagrams/diagram_renderer.dart';
import 'package:niman/src/diagrams/diagram_result.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/gantt_renderer.dart';
import 'package:niman/src/diagrams/git_graph_renderer.dart';
import 'package:niman/src/diagrams/journey_renderer.dart';
import 'package:niman/src/diagrams/kanban_renderer.dart';
import 'package:niman/src/diagrams/packet_renderer.dart';
import 'package:niman/src/diagrams/pie_renderer.dart';
import 'package:niman/src/diagrams/quadrant_renderer.dart';
import 'package:niman/src/diagrams/radar_renderer.dart';
import 'package:niman/src/diagrams/sankey_renderer.dart';
import 'package:niman/src/diagrams/sequence_renderer.dart';
import 'package:niman/src/diagrams/svg_target.dart';
import 'package:niman/src/diagrams/timeline_renderer.dart';
import 'package:niman/src/diagrams/treemap_renderer.dart';
import 'package:niman/src/diagrams/xy_chart_renderer.dart';

/// [source] as a standalone `<svg>` document, or null when it does not
/// parse — or when writing it throws, a fault of the engine's that keeps
/// the fence as code rather than failing the whole export
/// ([guardDiagram] is the same for the layout).
String? diagramSvg(String source, DiagramStyle style) {
  final result = resolveDiagram(source, style);
  if (result is! DiagramReady) return null;
  try {
    return drawingSvg(result.drawing, style);
  } on Object catch (error, stack) {
    const AppLogger(name: 'diagrams').error('SVG not written: $error\n$stack');
    return null;
  }
}

/// A laid-out [drawing] as a standalone `<svg>` document.
String drawingSvg(DiagramDrawing drawing, DiagramStyle style) {
  final target = SvgDiagramTarget(
    width: drawing.size.width,
    height: drawing.size.height,
    fontFamily: style.fontFamily,
  );
  switch (drawing) {
    case FlowDrawing(:final layout):
      DiagramRenderer(layout: layout, style: style).paint(target);
    case SequenceDrawing(:final layout):
      SequenceRenderer(layout: layout, style: style).paint(target);
    case PieDrawing(:final layout):
      PieRenderer(layout: layout, style: style).paint(target);
    case GanttDrawing(:final layout):
      GanttRenderer(layout: layout, style: style).paint(target);
    case TimelineDrawing(:final layout):
      TimelineRenderer(layout: layout, style: style).paint(target);
    case JourneyDrawing(:final layout):
      JourneyRenderer(layout: layout, style: style).paint(target);
    case GitGraphDrawing(:final layout):
      GitGraphRenderer(layout: layout, style: style).paint(target);
    case BlockDrawing(:final layout):
      BlockRenderer(layout: layout, style: style).paint(target);
    case PacketDrawing(:final layout):
      PacketRenderer(layout: layout, style: style).paint(target);
    case RadarDrawing(:final layout):
      RadarRenderer(layout: layout, style: style).paint(target);
    case TreemapDrawing(:final layout):
      TreemapRenderer(layout: layout, style: style).paint(target);
    case ArchitectureDrawing(:final layout):
      ArchitectureRenderer(layout: layout, style: style).paint(target);
    case KanbanDrawing(:final layout):
      KanbanRenderer(layout: layout, style: style).paint(target);
    case QuadrantDrawing(:final layout):
      QuadrantRenderer(layout: layout, style: style).paint(target);
    case XyChartDrawing(:final layout):
      XyChartRenderer(layout: layout, style: style).paint(target);
    case SankeyDrawing(:final layout):
      SankeyRenderer(layout: layout, style: style).paint(target);
  }
  return target.finish();
}
