/// Diagrams as SVG for an exported page (#530).
///
/// The export's half of the one drawing: it parses the fence's source and
/// walks the same layout the screen paints, through the SVG target. A
/// source that does not parse comes back null, for the caller to keep as a
/// code block.
library;

import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_renderer.dart';
import 'package:niman/src/diagrams/diagram_result.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/svg_target.dart';

/// [source] as a standalone `<svg>` document, or null when it does not
/// parse.
String? diagramSvg(String source, DiagramStyle style) {
  final result = resolveDiagram(source, style);
  return switch (result) {
    DiagramReady(:final layout) => diagramLayoutSvg(layout, style),
    DiagramFailed() => null,
  };
}

/// A laid-out [layout] as a standalone `<svg>` document.
String diagramLayoutSvg(DiagramLayout layout, DiagramStyle style) {
  final target = SvgDiagramTarget(
    width: layout.size.width,
    height: layout.size.height,
    fontFamily: style.fontFamily,
  );
  DiagramRenderer(layout: layout, style: style).paint(target);
  return target.finish();
}
