// Entities in a Mermaid label (#530): `&amp;`, `&nbsp;`, `#quot;`, `#58;`
// are written out in every diagram kind — in what is drawn, after the
// line is split, so `#58;` puts a colon where a colon would split it.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/class_parser.dart';
import 'package:niman/src/diagrams/er_parser.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_parser.dart';
import 'package:niman/src/diagrams/gantt_parser.dart';
import 'package:niman/src/diagrams/git_graph_parser.dart';
import 'package:niman/src/diagrams/journey_parser.dart';
import 'package:niman/src/diagrams/kanban_parser.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';
import 'package:niman/src/diagrams/mindmap_parser.dart';
import 'package:niman/src/diagrams/pie_parser.dart';
import 'package:niman/src/diagrams/quadrant_parser.dart';
import 'package:niman/src/diagrams/sankey_parser.dart';
import 'package:niman/src/diagrams/sequence_model.dart';
import 'package:niman/src/diagrams/sequence_parser.dart';
import 'package:niman/src/diagrams/state_parser.dart';
import 'package:niman/src/diagrams/timeline_parser.dart';
import 'package:niman/src/diagrams/xy_chart_parser.dart';

String _label(Flowchart chart, String id) =>
    chart.nodes.firstWhere((node) => node.id == id).label;

void main() {
  test('the helper writes entities out, an unknown one left as it is', () {
    expect(decodeMermaidEntities('a&nbsp;b'), 'a b');
    expect(
      decodeMermaidEntities('#quot;hi#quot; &amp; &#65;#66;&#x43;'),
      '"hi" & ABC',
    );
    expect(decodeMermaidEntities('&bogus; &12; #x;'), '&bogus; &12; #x;');
  });

  test('a flowchart: node, edge and subgraph title', () {
    final chart = parseFlowchart(
      'flowchart TD\nsubgraph s [Step #35;1]\n'
      'A["x &amp; y"] -- "p #quot;q#quot;" --> B\nend',
    );
    expect(_label(chart, 'A'), 'x & y');
    expect(chart.edges.single.label, 'p "q"');
    expect(chart.subgraphs.single.title, 'Step #1');
  });

  test('a mind map', () {
    final chart = parseMindmap(
      'mindmap\n  root((a #quot;b#quot;))\n    c &amp; d',
    );
    expect([for (final n in chart.nodes) n.label], ['a "b"', 'c & d']);
  });

  test('a class diagram: name, member, relation, note', () {
    final chart = parseClassDiagram(
      'classDiagram\nclass A["Box &lt;T&gt;"]\nA : +int x #38; y\n'
      'A --> B : uses #quot;it#quot;\nnote for A "n &amp; m"',
    );
    final box = chart.nodes.firstWhere((n) => n.id == 'A');
    expect(box.label, 'Box <T>');
    expect(box.sections[1], ['+int x & y']);
    expect(chart.edges.first.label, 'uses "it"');
    expect(
      chart.nodes.firstWhere((n) => n.shape == FlowNodeShape.note).label,
      'n & m',
    );
  });

  test('a state diagram: transition, description, note', () {
    final chart = parseStateDiagram(
      'stateDiagram\nA --> B : go #38; stop\nB : at #58; rest\n'
      'note right of A : n&amp;m',
    );
    expect(chart.edges.first.label, 'go & stop');
    expect(_label(chart, 'B'), 'at : rest');
    expect(
      chart.nodes.firstWhere((n) => n.shape == FlowNodeShape.note).label,
      'n&m',
    );
  });

  test('an entity-relationship diagram', () {
    final chart = parseErDiagram(
      'erDiagram\nA ||--o{ B : "has #38; holds"\nA {\n  string x "a #38; b"\n}',
    );
    expect(chart.edges.single.label, 'has & holds');
    expect(chart.nodes.first.sections[1].single, contains('a & b'));
  });

  test('a sequence: participant, message, note, frame', () {
    final diagram = parseSequence(
      'sequenceDiagram\nparticipant A as Ann #38; Bo\nloop every #58; tick\n'
      'A->>B: hi #quot;you#quot;\nend\nNote over A: n&amp;m',
    );
    expect(diagram.participants.first.label, 'Ann & Bo');
    final loop = diagram.items.first as SequenceBlock;
    expect(loop.sections.single.label, 'every : tick');
    final message = loop.sections.single.items.single as SequenceMessage;
    expect(message.text, 'hi "you"');
    expect((diagram.items.last as SequenceNote).text, 'n&m');
  });

  test('a pie', () {
    final pie = parsePie('pie title A #38; B\n"x #58; y" : 1');
    expect(pie.title, 'A & B');
    expect(pie.slices.single.label, 'x : y');
  });

  test('a Gantt chart: title, section, task', () {
    final gantt = parseGantt(
      'gantt\ntitle R #38; D\nsection S #38; T\n'
      'Task #58; one :a, 2026-01-01, 1d',
    );
    expect(gantt.title, 'R & D');
    expect(gantt.sections.single.name, 'S & T');
    expect(gantt.sections.single.tasks.single.label, 'Task : one');
  });

  test('a timeline: section, period, event', () {
    final timeline = parseTimeline(
      'timeline\nsection Early #38; late\n2026 #58; Q1 : x &amp; y',
    );
    final section = timeline.sections.single;
    expect(section.name, 'Early & late');
    expect(section.periods.single.label, '2026 : Q1');
    expect(section.periods.single.events, ['x & y']);
  });

  test('a journey: task and actor', () {
    final journey = parseJourney(
      'journey\nsection S\nGo #38; see: 5: Me #38; you',
    );
    expect(journey.sections.single.tasks.single.label, 'Go & see');
    expect(journey.actors, ['Me & you']);
  });

  test('a git graph: branch, commit and tag, matched as written', () {
    final graph = parseGitGraph(
      'gitGraph\ncommit id: "a#38;b" tag: "v#35;1"\nbranch "x#38;y"\n'
      'checkout "x#38;y"\ncommit\ncheckout main\ncherry-pick id: "a#38;b"',
    );
    expect(graph.commits.first.label, 'a&b');
    expect(graph.commits.first.tag, 'v#1');
    expect(graph.branches.last.name, 'x&y');
  });

  test('a kanban board: column, card and its data', () {
    final board = parseKanban(
      'kanban\n  c[To #38; do]\n    t[x &amp; y]@{ assigned: "A#38;B" }',
    );
    expect(board.columns.single.title, 'To & do');
    expect(board.columns.single.cards.single.text, 'x & y');
    expect(board.columns.single.cards.single.assigned, 'A&B');
  });

  test('a quadrant chart: title, axis, quadrant, point', () {
    final chart = parseQuadrant(
      'quadrantChart\ntitle T #38; U\nx-axis Lo #38; w --> Hi\n'
      'quadrant-1 Q #38; R\nP #38; S: [0.5, 0.5]',
    );
    expect(chart.title, 'T & U');
    expect(chart.xLow, 'Lo & w');
    expect(chart.quadrants.first, 'Q & R');
    expect(chart.points.single.label, 'P & S');
  });

  test('an xy chart: title, axis title, categories split first', () {
    final chart = parseXyChart(
      'xychart-beta\ntitle "T #38; U"\nx-axis "Mo #38; nth" [a #44; b, c]\n'
      'bar [1, 2]',
    );
    expect(chart.title, 'T & U');
    expect(chart.xTitle, 'Mo & nth');
    expect(chart.categories, ['a , b', 'c']);
  });

  test('a Sankey diagram: node names, one node however written', () {
    final chart = parseSankey('sankey-beta\nA #38; B,C,1\n"A &amp; B",D,2');
    expect(chart.nodes, ['A & B', 'C', 'D']);
  });
}
