/// The entry point of the diagram engine (#530): a Mermaid source in, a
/// parsed diagram out, or a [MermaidParseException] naming the line.
///
/// One function dispatches on the diagram's first word, so adding a kind
/// (mind map, sequence, pie) is a case here and a parser beside it, not a
/// change to every call site.
library;

import 'package:niman/src/diagrams/block_model.dart';
import 'package:niman/src/diagrams/block_parser.dart';
import 'package:niman/src/diagrams/class_parser.dart';
import 'package:niman/src/diagrams/er_parser.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_parser.dart';
import 'package:niman/src/diagrams/gantt_model.dart';
import 'package:niman/src/diagrams/gantt_parser.dart';
import 'package:niman/src/diagrams/git_graph_model.dart';
import 'package:niman/src/diagrams/git_graph_parser.dart';
import 'package:niman/src/diagrams/journey_model.dart';
import 'package:niman/src/diagrams/journey_parser.dart';
import 'package:niman/src/diagrams/kanban_model.dart';
import 'package:niman/src/diagrams/kanban_parser.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';
import 'package:niman/src/diagrams/mindmap_parser.dart';
import 'package:niman/src/diagrams/pie_model.dart';
import 'package:niman/src/diagrams/pie_parser.dart';
import 'package:niman/src/diagrams/quadrant_model.dart';
import 'package:niman/src/diagrams/quadrant_parser.dart';
import 'package:niman/src/diagrams/sankey_model.dart';
import 'package:niman/src/diagrams/sankey_parser.dart';
import 'package:niman/src/diagrams/sequence_model.dart';
import 'package:niman/src/diagrams/sequence_parser.dart';
import 'package:niman/src/diagrams/state_parser.dart';
import 'package:niman/src/diagrams/timeline_model.dart';
import 'package:niman/src/diagrams/timeline_parser.dart';
import 'package:niman/src/diagrams/xy_chart_model.dart';
import 'package:niman/src/diagrams/xy_chart_parser.dart';

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

/// A `gantt` chart.
final class MermaidGantt extends MermaidDiagram {
  /// Wraps a parsed [gantt].
  const new(this.gantt);

  /// The parsed Gantt chart.
  final GanttChart gantt;
}

/// A `timeline`.
final class MermaidTimeline extends MermaidDiagram {
  /// Wraps a parsed [timeline].
  const new(this.timeline);

  /// The parsed timeline.
  final TimelineChart timeline;
}

/// A user `journey`.
final class MermaidJourney extends MermaidDiagram {
  /// Wraps a parsed [journey].
  const new(this.journey);

  /// The parsed journey.
  final JourneyChart journey;
}

/// A `gitGraph`.
final class MermaidGitGraph extends MermaidDiagram {
  /// Wraps a parsed [graph].
  const new(this.graph);

  /// The parsed git graph.
  final GitGraph graph;
}

/// A `kanban` board.
final class MermaidKanban extends MermaidDiagram {
  /// Wraps a parsed [board].
  const new(this.board);

  /// The parsed board.
  final KanbanBoard board;
}

/// A `quadrantChart`.
final class MermaidQuadrant extends MermaidDiagram {
  /// Wraps a parsed [chart].
  const new(this.chart);

  /// The parsed quadrant chart.
  final QuadrantChart chart;
}

/// An `xychart-beta`.
final class MermaidXyChart extends MermaidDiagram {
  /// Wraps a parsed [chart].
  const new(this.chart);

  /// The parsed xy chart.
  final XyChart chart;
}

/// A `sankey-beta` diagram.
final class MermaidSankey extends MermaidDiagram {
  /// Wraps a parsed [chart].
  const new(this.chart);

  /// The parsed Sankey diagram.
  final SankeyChart chart;
}

/// A `block-beta` diagram.
final class MermaidBlock extends MermaidDiagram {
  /// Wraps a parsed [diagram].
  const new(this.diagram);

  /// The parsed block diagram.
  final BlockDiagram diagram;
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
  'requirementdiagram',
  'c4context',
  'packet-beta',
  'architecture-beta',
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
  if (first == 'gantt') return MermaidGantt(parseGantt(source));
  if (first == 'timeline') return MermaidTimeline(parseTimeline(source));
  if (first == 'journey') return MermaidJourney(parseJourney(source));
  if (first == 'gitgraph') return MermaidGitGraph(parseGitGraph(source));
  if (first == 'kanban') return MermaidKanban(parseKanban(source));
  if (first == 'quadrantchart') return MermaidQuadrant(parseQuadrant(source));
  if (first == 'xychart-beta') return MermaidXyChart(parseXyChart(source));
  if (first == 'sankey-beta' || first == 'sankey') {
    return MermaidSankey(parseSankey(source));
  }
  if (first == 'block-beta' || first == 'block') {
    return MermaidBlock(parseBlock(source));
  }
  if (first == 'classdiagram' || first == 'classdiagram-v2') {
    return MermaidFlowchart(parseClassDiagram(source));
  }
  if (first == 'statediagram' || first == 'statediagram-v2') {
    return MermaidFlowchart(parseStateDiagram(source));
  }
  if (first == 'erdiagram') return MermaidFlowchart(parseErDiagram(source));
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
