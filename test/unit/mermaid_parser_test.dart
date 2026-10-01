// The Mermaid flowchart parser (#530): the shapes, the edge spellings and,
// above all, the errors that name a line.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';

Flowchart _chart(String source) =>
    (parseMermaid(source) as MermaidFlowchart).chart;

FlowNode _node(Flowchart chart, String id) =>
    chart.nodes.firstWhere((node) => node.id == id);

void main() {
  test('the header names the direction', () {
    expect(_chart('flowchart LR\nA --> B').direction, FlowDirection.leftRight);
    expect(_chart('graph BT\nA --> B').direction, FlowDirection.bottomUp);
  });

  test('a missing direction is an error on line 1', () {
    expect(
      () => parseMermaid('flowchart\nA --> B'),
      throwsA(
        isA<MermaidParseException>()
            .having((e) => e.line, 'line', 1)
            .having((e) => e.message, 'message', contains('a direction')),
      ),
    );
  });

  test('a missing header is an error', () {
    expect(
      () => parseMermaid('A --> B'),
      throwsA(
        isA<MermaidParseException>().having(
          (e) => e.message,
          'message',
          contains('"flowchart" or "graph"'),
        ),
      ),
    );
  });

  test('node shapes and labels are read', () {
    final chart = _chart(
      'flowchart TD\n'
      'A[Start]\n'
      'B(Decision)\n'
      'C([Stadium])\n'
      'D[[Sub]]\n'
      'E[(Store)]\n'
      'F((Circle))\n'
      'G{Diamond}\n'
      'H{{Hex}}\n'
      'I[/Para/]\n'
      'J[\\ParaAlt\\]\n'
      'K[/Trap\\]\n'
      'L[\\TrapAlt/]\n'
      'M>Flag]',
    );
    expect(_node(chart, 'A').shape, FlowNodeShape.rect);
    expect(_node(chart, 'A').label, 'Start');
    expect(_node(chart, 'B').shape, FlowNodeShape.round);
    expect(_node(chart, 'C').shape, FlowNodeShape.stadium);
    expect(_node(chart, 'D').shape, FlowNodeShape.subroutine);
    expect(_node(chart, 'E').shape, FlowNodeShape.database);
    expect(_node(chart, 'F').shape, FlowNodeShape.circle);
    expect(_node(chart, 'G').shape, FlowNodeShape.diamond);
    expect(_node(chart, 'H').shape, FlowNodeShape.hexagon);
    expect(_node(chart, 'I').shape, FlowNodeShape.parallelogram);
    expect(_node(chart, 'J').shape, FlowNodeShape.parallelogramAlt);
    expect(_node(chart, 'K').shape, FlowNodeShape.trapezoid);
    expect(_node(chart, 'L').shape, FlowNodeShape.trapezoidAlt);
    expect(_node(chart, 'M').shape, FlowNodeShape.asymmetric);
  });

  test('a node with no label carries its id', () {
    final chart = _chart('flowchart TD\nA --> B');
    expect(_node(chart, 'A').label, 'A');
  });

  test('edge spellings set the stroke and the caps', () {
    final chart = _chart(
      'flowchart TD\n'
      'A --> B\n'
      'B -.-> C\n'
      'C ==> D\n'
      'D --x E\n'
      'E o-- F\n'
      'F === G',
    );
    expect(chart.edges[0].style, FlowEdgeStyle.solid);
    expect(chart.edges[0].end, FlowEdgeEnd.arrow);
    expect(chart.edges[1].style, FlowEdgeStyle.dotted);
    expect(chart.edges[2].style, FlowEdgeStyle.thick);
    expect(chart.edges[3].end, FlowEdgeEnd.cross);
    expect(chart.edges[4].start, FlowEdgeEnd.circle);
    expect(chart.edges[5].end, FlowEdgeEnd.none);
  });

  test('labels are read inline and in pipes', () {
    final chart = _chart(
      'flowchart TD\n'
      'A -- yes --> B\n'
      'B -->|no| C',
    );
    expect(chart.edges[0].label, 'yes');
    expect(chart.edges[1].label, 'no');
  });

  test('& fans an edge out to several nodes', () {
    final chart = _chart('flowchart TD\nA --> B & C\nB --> D');
    expect(chart.edges.map((e) => '${e.from}->${e.to}'), [
      'A->B',
      'A->C',
      'B->D',
    ]);
  });

  test('a subgraph gathers its nodes', () {
    final chart = _chart(
      'flowchart TD\n'
      'subgraph one [Group]\n'
      'A --> B\n'
      'end\n'
      'C --> A',
    );
    expect(chart.subgraphs, hasLength(1));
    expect(chart.subgraphs.first.title, 'Group');
    expect(chart.subgraphs.first.nodeIds, ['A', 'B']);
    expect(chart.nodes.map((n) => n.id), ['A', 'B', 'C']);
  });

  test('a dangling edge names the line and the suggestions', () {
    expect(
      () => parseMermaid('flowchart TD\nA -- B'),
      throwsA(
        isA<MermaidParseException>()
            .having((e) => e.line, 'line', 2)
            .having((e) => e.message, 'message', contains('after "--"'))
            .having((e) => e.message, 'message', contains('-->')),
      ),
    );
  });

  test('an unclosed subgraph is an error', () {
    expect(
      () => parseMermaid('flowchart TD\nsubgraph s\nA --> B'),
      throwsA(
        isA<MermaidParseException>().having(
          (e) => e.message,
          'message',
          contains('missing "end"'),
        ),
      ),
    );
  });

  test('an unsupported diagram type is refused, not mis-drawn', () {
    expect(
      () => parseMermaid('sequenceDiagram\nA->>B: hi'),
      throwsA(
        isA<MermaidParseException>().having(
          (e) => e.message,
          'message',
          contains('unsupported diagram type'),
        ),
      ),
    );
  });

  test('comments and directives are skipped', () {
    final chart = _chart(
      'flowchart TD\n'
      '%% a comment\n'
      'classDef red fill:#f00\n'
      'A --> B %% trailing',
    );
    expect(chart.nodes.map((n) => n.id), ['A', 'B']);
    expect(chart.edges, hasLength(1));
  });

  test('the reported line is the diagram source line', () {
    expect(
      () => parseMermaid('flowchart TD\nA[ok]\nB --> C\nD -- E'),
      throwsA(isA<MermaidParseException>().having((e) => e.line, 'line', 4)),
    );
  });
}
