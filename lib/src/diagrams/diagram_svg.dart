/// Diagrams as SVG for an exported page (#530).
///
/// The export's half of the one drawing: it parses the fence's source and
/// walks the same layout the screen paints, through the SVG target. A
/// source that does not parse comes back null, for the caller to keep as a
/// code block.
library;

import 'package:niman/src/diagrams/diagram_drawing.dart';
import 'package:niman/src/diagrams/diagram_renderer.dart';
import 'package:niman/src/diagrams/diagram_result.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/gantt_renderer.dart';
import 'package:niman/src/diagrams/pie_renderer.dart';
import 'package:niman/src/diagrams/sequence_renderer.dart';
import 'package:niman/src/diagrams/svg_target.dart';
import 'package:niman/src/diagrams/timeline_renderer.dart';

/// [source] as a standalone `<svg>` document, or null when it does not
/// parse.
String? diagramSvg(String source, DiagramStyle style) =>
    switch (resolveDiagram(source, style)) {
      DiagramReady(:final drawing) => drawingSvg(drawing, style),
      DiagramFailed() => null,
    };

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
  }
  return target.finish();
}
