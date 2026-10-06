// A Mermaid requirement diagram (#530): requirements and elements read
// into boxes of two compartments, relationships into labelled edges with
// Mermaid's ends, and the errors that name a line.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_svg.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flowchart_layout.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/requirement_parser.dart';

const String _source = '''
requirementDiagram
direction LR

requirement "disk first" {
  id: 1
  text: Every note is one Markdown file on disk #38; the index is rebuilt.
  risk: HIGH
  verifymethod: test
}

functionalRequirement search:::hot {
  id: 1.1
}

element fts {
  type: "SQLite FTS5"
  docref: lib/src/search
}

designConstraint empty {}

"disk first" - contains -> search
fts - satisfies -> search
search <- verifies - fts
style fts fill:#f9f
''';

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

FlowNode _box(Flowchart chart, String id) =>
    chart.nodes.firstWhere((node) => node.id == id);

void main() {
  test('a requirement is its kind and name over its attributes', () {
    final chart = parseRequirementDiagram(_source);
    expect(chart.direction, FlowDirection.leftRight);
    final disk = _box(chart, 'disk first');
    expect(disk.shape, FlowNodeShape.classBox);
    expect(disk.sections.first, ['«Requirement»', 'disk first']);
    final lines = disk.sections[1];
    expect(lines.first, 'ID: 1');
    expect(lines.last, 'Verification: Test');
    expect(lines, contains('Risk: High'));
    // The text wrapped at words, its entity written out.
    final text = lines.sublist(1, lines.length - 2);
    expect(text.first, startsWith('Text: Every note'));
    expect(text.join(' '), contains('on disk & the index'));
    expect(text.every((line) => line.length <= 36), isTrue);
    expect(text, hasLength(greaterThan(1)));
  });

  test('every kind has its stereotype, an element its own attributes', () {
    final chart = parseRequirementDiagram(_source);
    expect(
      _box(chart, 'search').sections.first.first,
      '«Functional Requirement»',
    );
    expect(_box(chart, 'empty').sections, [
      ['«Design Constraint»', 'empty'],
    ]);
    expect(_box(chart, 'fts').sections, [
      ['«Element»', 'fts'],
      ['Type: SQLite FTS5', 'Doc Ref: lib/src/search'],
    ]);
  });

  test('a relationship is an edge either way it is written', () {
    final edges = parseRequirementDiagram(_source).edges;
    expect(
      [for (final e in edges) '${e.from}>${e.to} ${e.label}'],
      [
        'disk first>search «contains»',
        'fts>search «satisfies»',
        'fts>search «verifies»',
      ],
    );
    final contains = edges.first;
    expect(contains.style, FlowEdgeStyle.solid);
    expect(contains.start, FlowEdgeEnd.containment);
    expect(contains.end, FlowEdgeEnd.none);
    expect(edges[1].style, FlowEdgeStyle.dotted);
    expect(edges[1].end, FlowEdgeEnd.arrow);
  });

  test('a mistake names its line', () {
    const head = 'requirementDiagram\n';
    expect(
      () => parseRequirementDiagram('${head}wish w {\n}'),
      _error(2, 'designConstraint'),
    );
    expect(
      () => parseRequirementDiagram('${head}requirement r {\n  type: x\n}'),
      _error(3, 'not "type"'),
    );
    expect(
      () => parseRequirementDiagram('${head}requirement r {\n  risk: dire\n}'),
      _error(3, 'low, medium or high'),
    );
    expect(
      () => parseRequirementDiagram(
        '${head}requirement r {\n  verifymethod: hope\n}',
      ),
      _error(3, 'analysis'),
    );
    expect(
      () => parseRequirementDiagram('${head}element e {}\ne - likes -> e'),
      _error(3, 'contains'),
    );
    expect(
      () => parseRequirementDiagram('${head}element e {}\ne - traces -> f'),
      _error(3, '"f"'),
    );
    expect(
      () => parseRequirementDiagram('${head}element e {}\nelement e {}'),
      _error(3, 'twice'),
    );
    expect(
      () => parseRequirementDiagram('${head}element e {\n  type: x'),
      _error(2, '"}"'),
    );
    expect(
      () => parseRequirementDiagram('${head}what is this'),
      _error(2, 'expected a requirement'),
    );
    expect(
      () => parseRequirementDiagram('${head}direction up'),
      _error(2, 'direction'),
    );
    expect(() => parseRequirementDiagram(head), _error(1, 'needs a'));
  });

  test('a requirement fence dispatches, lays out and exports', () {
    expect(parseMermaid(_source), isA<MermaidFlowchart>());
    final layout = layoutFlowchart(
      parseRequirementDiagram(_source),
      const DiagramStyle(),
    );
    expect(layout.nodes, hasLength(4));
    final svg = diagramSvg(_source, const DiagramStyle())!;
    expect(svg, contains('«satisfies»'));
    expect(svg, contains('Doc Ref: lib/src/search'));
  });
}
