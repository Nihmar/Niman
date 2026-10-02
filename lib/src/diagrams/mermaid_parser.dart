/// The entry point of the diagram engine (#530): a Mermaid source in, a
/// parsed diagram out, or a [MermaidParseException] naming the line.
///
/// One function dispatches on the diagram's first word, so adding a kind
/// (mind map, sequence, pie) is a case here and a parser beside it, not a
/// change to every call site.
library;

import 'package:niman/src/diagrams/class_parser.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_parser.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';
import 'package:niman/src/diagrams/mindmap_parser.dart';
import 'package:niman/src/diagrams/pie_model.dart';
import 'package:niman/src/diagrams/pie_parser.dart';
import 'package:niman/src/diagrams/sequence_model.dart';
import 'package:niman/src/diagrams/sequence_parser.dart';
import 'package:niman/src/diagrams/state_parser.dart';

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

/// A `pie` chart.
final class MermaidPie extends MermaidDiagram {
  /// Wraps a parsed [pie].
  const new(this.pie);

  /// The parsed pie chart.
  final PieChart pie;
}

/// A `sequenceDiagram`.
final class MermaidSequence extends MermaidDiagram {
  /// Wraps a parsed [sequence].
  const new(this.sequence);

  /// The parsed sequence.
  final SequenceDiagram sequence;
}

/// The Mermaid diagram kinds this engine does not draw yet. A first word
/// among these is refused by name; anything else is handed to the flowchart
/// parser, which reports its own header error.
const Set<String> _otherDiagramTypes = {
  'erdiagram',
  'journey',
  'gantt',
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
  if (first == 'mindmap') return MermaidFlowchart(parseMindmap(source));
  if (first == 'sequencediagram') return MermaidSequence(parseSequence(source));
  if (first == 'pie') return MermaidPie(parsePie(source));
  if (first == 'classdiagram' || first == 'classdiagram-v2') {
    return MermaidFlowchart(parseClassDiagram(source));
  }
  if (first == 'statediagram' || first == 'statediagram-v2') {
    return MermaidFlowchart(parseStateDiagram(source));
  }
  if (first == 'flowchart' ||
      first == 'graph' ||
      !_otherDiagramTypes.contains(first)) {
    return MermaidFlowchart(parseFlowchart(source));
  }
  throw MermaidParseException(1, 'unsupported diagram type "$first"');
}

/// The first word of the diagram's header — past a front matter, comments
/// and directives — or the empty string.
String _firstWord(String source) {
  final lines = source.split('\n');
  final header = mermaidBodyStart(lines);
  if (header >= lines.length) return '';
  final match = RegExp('^[A-Za-z_][A-Za-z0-9_-]*')
      .firstMatch(lines[header].trim());
  return match?.group(0) ?? '';
}
