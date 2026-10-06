// A Mermaid C4 diagram (#530): elements read into cards — stereotype,
// name, technology, description — boundaries into nested subgraphs and
// relationships into dashed edges, and the errors that name a line.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/c4_parser.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_svg.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_node_size.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';

const String _source = r'''
C4Container
  title Containers
  Person(user, "User", "Writes notes #38; reads them.")
  Container_Boundary(app, "Niman") {
    Container(ui, "App", "Flutter", "Edits and shows notes, on every platform, the same.")
    ContainerDb(db, "Index", $techn="SQLite", $descr="Rebuilt from disk")
    Boundary(sync, "Sync", "Service") {
      ContainerQueue_Ext(q, "Queue")
    }
    Deployment_Node(empty, "Spare", "VM") {
    }
  }
  Rel(user, ui, "Uses", "touch")
  BiRel(ui, db, "Reads, writes")
  Rel_Back(q, ui, "Pushes")
  RelIndex(1, ui, empty, "Wakes")
  Rel_U(q, empty, $label="Feeds")
  UpdateElementStyle(user, $bgColor="grey")
  UpdateLayoutConfig($c4ShapeInRow="3")
''';

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

FlowNode _node(Flowchart chart, String id) =>
    chart.nodes.firstWhere((node) => node.id == id);

void main() {
  test('an element is a card: stereotype, name, technology, description', () {
    final chart = parseC4(_source);
    final user = _node(chart, 'user');
    expect(user.shape, FlowNodeShape.round);
    expect(user.sections, [
      ['«person»'],
      ['User'],
      ['Writes notes & reads them.'],
    ]);
    final ui = _node(chart, 'ui');
    expect(ui.sections.last.first, '[Flutter]');
    expect(ui.sections.last.length, greaterThan(2), reason: 'wrapped');
    final db = _node(chart, 'db');
    expect(db.shape, FlowNodeShape.database);
    expect(db.sections, [
      ['«container_db»'],
      ['Index'],
      ['[SQLite]', 'Rebuilt from disk'],
    ]);
    final q = _node(chart, 'q');
    expect(q.shape, FlowNodeShape.stadium);
    expect(q.sections.first, ['«external_container_queue»']);
  });

  test('boundaries nest, titled with their type; an empty one is a box', () {
    final chart = parseC4(_source);
    expect(
      [for (final s in chart.subgraphs) (s.id, s.title, s.parent)],
      [('sync', 'Sync [Service]', 'app'), ('app', 'Niman [Container]', null)],
    );
    final app = chart.subgraphs.last;
    expect(app.nodeIds, containsAll(['ui', 'db', 'q', 'empty']));
    expect(_node(chart, 'empty').sections, [
      ['[VM]'],
      ['Spare'],
      <String>[],
    ]);
  });

  test('relationships: label and technology, arrows as each one says', () {
    final edges = parseC4(_source).edges;
    expect(
      [for (final e in edges) '${e.from}>${e.to} ${e.label}'],
      [
        'user>ui Uses [touch]',
        'ui>db Reads, writes',
        'q>ui Pushes',
        'ui>empty 1: Wakes',
        'q>empty Feeds',
      ],
    );
    expect(edges.every((e) => e.style == FlowEdgeStyle.dotted), isTrue);
    expect(
      (edges[0].start, edges[0].end),
      (FlowEdgeEnd.none, FlowEdgeEnd.arrow),
    );
    expect(
      (edges[1].start, edges[1].end),
      (FlowEdgeEnd.arrow, FlowEdgeEnd.arrow),
    );
    expect(
      (edges[2].start, edges[2].end),
      (FlowEdgeEnd.arrow, FlowEdgeEnd.none),
    );
  });

  test('a card is as big as its lines, and its name is drawn bold', () {
    final chart = parseC4(_source);
    final ui = _node(chart, 'ui');
    final size = flowNodeSize(ui, [ui.label], const DiagramStyle());
    const line = 14 * 1.25;
    expect(size.height, greaterThanOrEqualTo(ui.stackedLines.length * line));
    final svg = diagramSvg(_source, const DiagramStyle())!;
    expect(RegExp('font-weight="600"[^>]*>App<').hasMatch(svg), isTrue);
  });

  test('every C4 header dispatches to the graph engine', () {
    for (final header in [
      'C4Context',
      'C4Container',
      'C4Component',
      'C4Dynamic',
      'C4Deployment',
    ]) {
      expect(
        parseMermaid('$header\nSystem(s, "S")'),
        isA<MermaidFlowchart>(),
        reason: header,
      );
    }
  });

  test('a mistake names its line', () {
    const head = 'C4Context\n';
    expect(() => parseC4('${head}Robot(r, "R")'), _error(2, 'Person'));
    expect(() => parseC4('${head}PersonDb(p, "P")'), _error(2, 'Person'));
    expect(() => parseC4('${head}System(s)'), _error(2, 'alias and a label'));
    expect(
      () => parseC4('${head}System(s, "S")\nSystem(s, "T")'),
      _error(3, 'twice'),
    );
    expect(
      () => parseC4('${head}System(s, "S")\nRel(s, t, "x")'),
      _error(3, '"t"'),
    );
    expect(
      () => parseC4('${head}Boundary(b, "B") {\nSystem(s, "S")\n}\nRel(s, b)'),
      _error(5, 'boundary'),
    );
    expect(() => parseC4('${head}Boundary(b, "B")'), _error(2, '"{"'));
    expect(() => parseC4('${head}System(s, "S") {'), _error(2, 'cannot hold'));
    expect(() => parseC4('${head}Boundary(b, "B") {'), _error(2, '"}"'));
    expect(() => parseC4('$head}'), _error(2, 'unexpected'));
    expect(() => parseC4('${head}System(s, "S)'), _error(2, 'quote'));
    expect(() => parseC4('${head}just words'), _error(2, 'expected an'));
    expect(() => parseC4('${head}title T'), _error(1, 'needs an element'));
  });
}
