/// What parsing and laying a diagram out produced (#530): a drawing, or the
/// error to fall back to source with.
library;

import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flowchart_layout.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';

/// The outcome for one diagram source at one style.
sealed class DiagramResult {
  /// Const for subclasses.
  const new();
}

/// The diagram parsed and was laid out.
final class DiagramReady extends DiagramResult {
  /// Wraps a laid-out [layout].
  const new(this.layout);

  /// The drawing to paint.
  final DiagramLayout layout;
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
    final diagram = parseMermaid(source);
    return switch (diagram) {
      MermaidFlowchart(:final chart) => DiagramReady(
        layoutFlowchart(chart, style),
      ),
    };
  } on MermaidParseException catch (error) {
    return DiagramFailed(error);
  }
}
