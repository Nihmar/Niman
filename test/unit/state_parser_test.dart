// The Mermaid state-diagram parser (#530): states, `[*]` as a start and an
// end, forks, joins and choices, composite states and the transitions in
// and out of them, notes, and the errors that name a line.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/state_parser.dart';

FlowNode _state(Flowchart chart, String id) =>
    chart.nodes.firstWhere((node) => node.id == id);

List<String> _edges(Flowchart chart) => [
  for (final e in chart.edges)
    '${e.from}>${e.to}${e.label == null ? '' : ':${e.label}'}',
];

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

void main() {
  test('[*] starts and ends, a transition carries its label', () {
    final chart = parseStateDiagram(
      'stateDiagram-v2\n[*] --> Still\nStill --> Moving : push\n'
      'Moving --> Still\nMoving-->[*]',
    );
    expect(_edges(chart), [
      '[*] start >Still',
      'Still>Moving:push',
      'Moving>Still',
      'Moving>[*] end ',
    ]);
    expect(_state(chart, '[*] start ').shape, FlowNodeShape.start);
    expect(_state(chart, '[*] end ').shape, FlowNodeShape.end);
    expect(_state(chart, 'Still').shape, FlowNodeShape.round);
  });

  test('a state is named by its description or its alias', () {
    final chart = parseStateDiagram(
      'stateDiagram\nstate "Waiting for input" as Idle\n'
      'Busy : Working\nBusy : on a job\nIdle --> Busy',
    );
    expect(_state(chart, 'Idle').label, 'Waiting for input');
    expect(_state(chart, 'Busy').label, 'Working\non a job');
  });

  test('fork and join are bars, choice a small diamond', () {
    final chart = parseStateDiagram(
      'stateDiagram-v2\nstate split <<fork>>\nstate merge <<join>>\n'
      'state ok <<choice>>\n[*] --> split\nsplit --> A\nsplit --> B\n'
      'A --> merge\nB --> merge\nmerge --> ok\nok --> [*] : yes',
    );
    expect(_state(chart, 'split').shape, FlowNodeShape.bar);
    expect(_state(chart, 'merge').shape, FlowNodeShape.bar);
    expect(_state(chart, 'ok').shape, FlowNodeShape.diamond);
    expect(_state(chart, 'ok').label, isEmpty);
  });

  test('a composite state is a subgraph, entered by its start', () {
    final chart = parseStateDiagram(
      'stateDiagram-v2\n'
      '[*] --> First\n'
      'state First {\n'
      '  [*] --> second\n'
      '  second --> [*]\n'
      '}\n'
      'First --> Done',
    );
    expect(chart.subgraphs.single.id, 'First');
    expect(chart.subgraphs.single.nodeIds, [
      '[*] start First',
      'second',
      '[*] end First',
    ]);
    // `First` is the box round them, not a state of its own.
    expect(chart.nodes.map((n) => n.id), isNot(contains('First')));
    expect(_edges(chart), [
      '[*] start >[*] start First',
      '[*] start First>second',
      'second>[*] end First',
      '[*] end First>Done',
    ]);
  });

  test('composites nest, a transition reaching the innermost one', () {
    final chart = parseStateDiagram(
      'stateDiagram\nstate Outer {\n  state Inner {\n    a --> b\n  }\n}\n'
      'start --> Outer\nOuter --> stop',
    );
    expect(chart.subgraphs.map((s) => (s.id, s.parent)), [
      ('Inner', 'Outer'),
      ('Outer', null),
    ]);
    expect(_edges(chart), ['a>b', 'start>a', 'b>stop']);
  });

  test('a note is tied to its state, on one line or several', () {
    final chart = parseStateDiagram(
      'stateDiagram\nA --> B\nnote right of A : first\n'
      'note left of B\n  two\n  lines\nend note',
    );
    final notes = chart.nodes.where((n) => n.shape == FlowNodeShape.note);
    expect(notes.map((n) => n.label), ['first', 'two\nlines']);
    expect(
      chart.edges.where((e) => e.style == FlowEdgeStyle.dotted),
      hasLength(2),
    );
  });

  test('direction, styling and concurrency borders are read past', () {
    final chart = parseStateDiagram(
      'stateDiagram-v2\ndirection LR\nclassDef bad fill:#f00\n'
      'state Active {\n  a --> b\n  --\n  c --> d\n}\nX:::bad --> Active\n'
      'class X bad\nhide empty description',
    );
    expect(chart.direction, FlowDirection.leftRight);
    expect(_edges(chart).last, 'X>a');
  });

  test('a state diagram dispatches to the graph engine', () {
    expect(parseMermaid('stateDiagram\nA --> B'), isA<MermaidFlowchart>());
  });

  test('a composite or a note left open names its line', () {
    expect(
      () => parseStateDiagram('stateDiagram\nstate A {\n  b --> c'),
      _error(2, 'missing "}"'),
    );
    expect(
      () => parseStateDiagram('stateDiagram\nA --> B\nnote left of A\n  text'),
      _error(3, 'missing "end note"'),
    );
    expect(
      () => parseStateDiagram('stateDiagram\nA --> B\n}'),
      _error(3, 'unexpected "}"'),
    );
  });

  test('a line that reads as nothing names itself', () {
    expect(
      () => parseStateDiagram('stateDiagram\nA -> B'),
      _error(2, 'found "A -> B"'),
    );
  });
}
