// The Mermaid entity-relationship parser (#530): entities and their
// attributes, the relationships with the crow's feet of their
// cardinalities, and the errors that name a line.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/er_parser.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';

FlowNode _entity(Flowchart chart, String id) =>
    chart.nodes.firstWhere((node) => node.id == id);

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

void main() {
  test('every cardinality ends in its crow foot, either side', () {
    final chart = parseErDiagram(
      'erDiagram\n'
      'CUSTOMER ||--o{ ORDER : places\n'
      'ORDER ||--|{ LINE-ITEM : contains\n'
      'CUSTOMER }|..|{ DELIVERY-ADDRESS : uses\n'
      'PERSON |o--o| PASSPORT : holds\n'
      'A}o--||B : "is in"',
    );
    final ends = [for (final e in chart.edges) (e.start, e.end)];
    expect(ends, [
      (FlowEdgeEnd.one, FlowEdgeEnd.zeroOrMore),
      (FlowEdgeEnd.one, FlowEdgeEnd.oneOrMore),
      (FlowEdgeEnd.oneOrMore, FlowEdgeEnd.oneOrMore),
      (FlowEdgeEnd.zeroOrOne, FlowEdgeEnd.zeroOrOne),
      (FlowEdgeEnd.zeroOrMore, FlowEdgeEnd.one),
    ]);
    expect(chart.edges.map((e) => e.label), [
      'places',
      'contains',
      'uses',
      'holds',
      'is in',
    ]);
    expect(chart.edges.map((e) => e.style == FlowEdgeStyle.dotted), [
      false, false, true, false, false, //
    ]);
    expect(chart.edges[1].to, 'LINE-ITEM');
  });

  test('an entity lists its attributes under its name', () {
    final chart = parseErDiagram(
      'erDiagram\n'
      'CUSTOMER {\n'
      '  string name\n'
      '  string custNumber PK "the number we give"\n'
      '  int sector FK,UK\n'
      '  varchar(255) note\n'
      '}\n'
      'CUSTOMER ||--o{ ORDER : places',
    );
    expect(_entity(chart, 'CUSTOMER').shape, FlowNodeShape.classBox);
    expect(_entity(chart, 'CUSTOMER').sections, [
      ['CUSTOMER'],
      [
        'string name',
        'string custNumber PK "the number we give"',
        'int sector FK, UK',
        'varchar(255) note',
      ],
    ]);
    expect(_entity(chart, 'ORDER').sections, [
      ['ORDER'],
    ]);
  });

  test('an entity may be quoted or drawn by an alias', () {
    final chart = parseErDiagram(
      'erDiagram\n"Order item" ||--|| p : for\np["Person"] {\n  string name\n}',
    );
    expect(chart.edges.single.from, 'Order item');
    expect(_entity(chart, 'p').sections.first, ['Person']);
  });

  test('direction turns the chart; styling is read past', () {
    final chart = parseErDiagram(
      'erDiagram\ndirection LR\nA:::warn ||--o{ B : has\n'
      'style A fill:#f9f\nclassDef warn fill:#f00',
    );
    expect(chart.direction, FlowDirection.leftRight);
    expect(chart.nodes.map((n) => n.id), ['A', 'B']);
  });

  test('an ER diagram dispatches to the graph engine', () {
    expect(parseMermaid('erDiagram\nA ||--|| B : x'), isA<MermaidFlowchart>());
  });

  test('an open entity and an unreadable line name their line', () {
    expect(
      () => parseErDiagram('erDiagram\nA {\n  string name\n'),
      _error(2, 'missing "}"'),
    );
    expect(
      () => parseErDiagram('erDiagram\nA {\n  just\n}'),
      _error(3, 'expected an attribute'),
    );
    expect(
      () => parseErDiagram('erDiagram\nA --> B'),
      _error(2, 'found "A --> B"'),
    );
  });
}
