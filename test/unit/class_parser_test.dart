// The Mermaid class-diagram parser (#530): classes and their members, the
// relations with UML's ends and cardinalities, notes, namespaces, and the
// errors that name a line.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/class_parser.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';

FlowNode _class(Flowchart chart, String id) =>
    chart.nodes.firstWhere((node) => node.id == id);

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

void main() {
  test('a class body splits into attributes and methods', () {
    final chart = parseClassDiagram(
      'classDiagram\n'
      'class Animal {\n'
      '  <<interface>>\n'
      '  +String name\n'
      '  +int age\n'
      '  +makeSound() void\n'
      '  +count()\$\n'
      '}',
    );
    final animal = _class(chart, 'Animal');
    expect(animal.shape, FlowNodeShape.classBox);
    expect(animal.sections, [
      ['«interface»', 'Animal'],
      ['+String name', '+int age'],
      ['+makeSound() void', '+count()'],
    ]);
  });

  test('members may be written one a line, outside the body', () {
    final chart = parseClassDiagram(
      'classDiagram\nAnimal : +int age\nAnimal : +isMammal()\n'
      '<<abstract>> Animal\nclass Duck',
    );
    expect(_class(chart, 'Animal').sections, [
      ['«abstract»', 'Animal'],
      ['+int age'],
      ['+isMammal()'],
    ]);
    expect(_class(chart, 'Duck').sections, [
      ['Duck'],
      <String>[],
      <String>[],
    ]);
  });

  test('a generic is drawn in angle brackets, a label in place of the id', () {
    final chart = parseClassDiagram(
      'classDiagram\nclass Square~Shape~\nclass Db["Database"]\n'
      'Square : +List~int~ sides\nSquare --> Db',
    );
    expect(_class(chart, 'Square').sections.first, ['Square<Shape>']);
    expect(_class(chart, 'Square').sections[1], ['+List<int> sides']);
    expect(_class(chart, 'Db').sections.first, ['Database']);
    expect(chart.edges.single.from, 'Square');
  });

  test('every relation sets its ends and its line', () {
    final chart = parseClassDiagram(
      'classDiagram\n'
      'A <|-- B\nC *-- D\nE o-- F\nG --> H\nI -- J\nK ..> L\nM ..|> N\n'
      'O .. P\nQ --* R\nS <|--|> T',
    );
    final ends = [for (final e in chart.edges) (e.start, e.end)];
    expect(ends, [
      (FlowEdgeEnd.triangle, FlowEdgeEnd.none),
      (FlowEdgeEnd.diamond, FlowEdgeEnd.none),
      (FlowEdgeEnd.hollowDiamond, FlowEdgeEnd.none),
      (FlowEdgeEnd.none, FlowEdgeEnd.arrow),
      (FlowEdgeEnd.none, FlowEdgeEnd.none),
      (FlowEdgeEnd.none, FlowEdgeEnd.arrow),
      (FlowEdgeEnd.none, FlowEdgeEnd.triangle),
      (FlowEdgeEnd.none, FlowEdgeEnd.none),
      (FlowEdgeEnd.none, FlowEdgeEnd.diamond),
      (FlowEdgeEnd.triangle, FlowEdgeEnd.triangle),
    ]);
    expect(chart.edges.map((e) => e.style == FlowEdgeStyle.dotted), [
      false, false, false, false, false, true, true, true, false, false, //
    ]);
  });

  test('a relation carries its cardinalities and its label', () {
    final chart = parseClassDiagram(
      'classDiagram\nCustomer "1" --> "*" Ticket : buys\nA-->B',
    );
    final buys = chart.edges.first;
    expect((buys.startLabel, buys.endLabel, buys.label), ('1', '*', 'buys'));
    expect((chart.edges.last.from, chart.edges.last.to), ('A', 'B'));
  });

  test('a note stands alone or is tied to its class', () {
    final chart = parseClassDiagram(
      'classDiagram\nnote "From Duck till Zebra"\nclass Duck\n'
      r'note for Duck "can fly\ncan swim"',
    );
    final notes = chart.nodes.where((n) => n.shape == FlowNodeShape.note);
    expect(notes.map((n) => n.label), [
      'From Duck till Zebra',
      'can fly\ncan swim',
    ]);
    expect(chart.edges.single.to, 'Duck');
    expect(chart.edges.single.end, FlowEdgeEnd.none);
  });

  test('a namespace boxes its classes, and direction turns the chart', () {
    final chart = parseClassDiagram(
      'classDiagram\ndirection LR\nnamespace Shapes {\n'
      '  class Triangle\n  class Square\n}\nclass Other',
    );
    expect(chart.direction, FlowDirection.leftRight);
    expect(chart.subgraphs.single.title, 'Shapes');
    expect(chart.subgraphs.single.nodeIds, ['Triangle', 'Square']);
  });

  test('styling, links and accessibility lines are stepped over', () {
    final chart = parseClassDiagram(
      'classDiagram\nclass Account:::warn\nstyle Account fill:#f9f\n'
      'cssClass "Account" warn\nclick Account href "https://x"\n'
      'accTitle: Accounts\naccDescr {\n  many lines\n}\nAccount --> Bank',
    );
    expect(chart.nodes.map((n) => n.id), ['Account', 'Bank']);
  });

  test('a class diagram dispatches to the graph engine', () {
    expect(parseMermaid('classDiagram-v2\nclass A'), isA<MermaidFlowchart>());
  });

  test('a body or a namespace left open names its line', () {
    expect(
      () => parseClassDiagram('classDiagram\nclass A {\n+x\n'),
      _error(2, 'missing "}"'),
    );
    expect(
      () => parseClassDiagram('classDiagram\nnamespace N {\nclass A'),
      _error(2, 'missing "}"'),
    );
    expect(
      () => parseClassDiagram('classDiagram\nclass A\n}'),
      _error(3, 'unexpected "}"'),
    );
  });

  test('a line that reads as nothing names itself', () {
    expect(
      () => parseClassDiagram('classDiagram\nA => B'),
      _error(2, 'found "A => B"'),
    );
  });
}
