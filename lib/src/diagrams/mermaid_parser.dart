/// The entry point of the diagram engine (#530): a Mermaid source in, a
/// parsed diagram out, or a [MermaidParseException] naming the line.
///
/// One function dispatches on the diagram's first word, so adding a kind
/// (mind map, sequence, pie) is a case here and a parser beside it, not a
/// change to every call site.
library;

import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_parser.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';

/// A parsed Mermaid diagram.
sealed class MermaidDiagram {
  /// Const for subclasses.
  const new();
}

/// A `flowchart` (or `graph`) diagram.
final class MermaidFlowchart extends MermaidDiagram {
  /// Wraps a parsed [chart].
  const new(this.chart);

  /// The parsed flowchart.
  final Flowchart chart;
}

/// The Mermaid diagram kinds this engine does not draw yet. A first word
/// among these is refused by name; anything else is handed to the flowchart
/// parser, which reports its own header error.
const Set<String> _otherDiagramTypes = {
  'sequencediagram',
  'classdiagram',
  'statediagram',
  'statediagram-v2',
  'erdiagram',
  'journey',
  'gantt',
  'pie',
  'mindmap',
  'timeline',
  'gitgraph',
  'quadrantchart',
  'requirementdiagram',
  'c4context',
  'sankey-beta',
  'xychart-beta',
  'block-beta',
  'packet-beta',
  'architecture-beta',
  'kanban',
  'radar-beta',
  'treemap-beta',
};

/// Parses [source] (the fence's content, header included).
///
/// Throws a [MermaidParseException] when the source does not parse.
MermaidDiagram parseMermaid(String source) {
  final first = _firstWord(source).toLowerCase();
  if (first == 'flowchart' ||
      first == 'graph' ||
      !_otherDiagramTypes.contains(first)) {
    return MermaidFlowchart(parseFlowchart(source));
  }
  throw MermaidParseException(1, 'unsupported diagram type "$first"');
}

/// The first word of the first non-empty line, or the empty string.
String _firstWord(String source) {
  for (final line in source.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final match = RegExp('^[A-Za-z_][A-Za-z0-9_-]*').firstMatch(trimmed);
    return match?.group(0) ?? '';
  }
  return '';
}
