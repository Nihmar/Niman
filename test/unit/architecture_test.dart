// A Mermaid architecture diagram (#530): its groups, services, junctions
// and sided edges read, the services set on a grid by the sides their
// edges leave by, the groups' boxes round them, and drawn on the canvas
// and in the SVG.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/architecture_grid.dart';
import 'package:niman/src/diagrams/architecture_layout.dart';
import 'package:niman/src/diagrams/architecture_model.dart';
import 'package:niman/src/diagrams/architecture_parser.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_svg.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';

const String _source = '''
architecture-beta
    group api(cloud)[API #38; more]

    service db(database)[Database] in api
    service disk1(disk)[Storage] in api
    service disk2(disk)[Storage] in api
    service server(server)[Server] in api
    service gateway(internet)[Gateway]
    junction hub

    db:L -- R:server
    disk1:T -- B:server
    disk2:T -- B:db
    server:L <-[calls]-> R:gateway
    gateway:B --> T:hub
    hub:R -- L:disk1{group}
''';

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

ArchitectureLayout _layout(String source) =>
    layoutArchitecture(parseArchitecture(source), const DiagramStyle());

ArchNodeBox _node(ArchitectureLayout layout, String id) =>
    layout.nodes.firstWhere((n) => n.service.id == id);

void main() {
  test('groups, services, junctions and sided edges are read', () {
    final diagram = parseArchitecture(_source);
    expect(diagram.groups.single.title, 'API & more');
    expect(diagram.groups.single.icon, 'cloud');
    final db = diagram.services.first;
    expect(
      (db.id, db.title, db.icon, db.group),
      ('db', 'Database', 'database', 'api'),
    );
    final hub = diagram.services.last;
    expect(hub.isJunction, isTrue);
    final calls = diagram.edges[3];
    expect((calls.fromSide, calls.toSide), (ArchSide.left, ArchSide.right));
    expect(
      (calls.arrowAtFrom, calls.arrowAtTo, calls.label),
      (true, true, 'calls'),
    );
    expect(diagram.edges[4].arrowAtTo, isTrue);
    expect(diagram.edges[4].arrowAtFrom, isFalse);
    expect(diagram.edges.last.toGroup, isTrue);
  });

  test('a mistake names its line', () {
    const head = 'architecture-beta\n';
    expect(
      () => parseArchitecture('${head}service a\nservice a'),
      _error(3, 'twice'),
    );
    expect(
      () => parseArchitecture('${head}service a in nowhere'),
      _error(2, '"nowhere"'),
    );
    expect(
      () => parseArchitecture('${head}service a\na:R -- L:b'),
      _error(3, '"b"'),
    );
    expect(
      () => parseArchitecture('${head}service a\nservice b\na{group}:R -- L:b'),
      _error(4, 'in no group'),
    );
    expect(
      () => parseArchitecture('${head}service a\nservice b\na:X -- L:b'),
      _error(4, 'L, R, T or B'),
    );
    expect(
      () => parseArchitecture('${head}service a\na:R -- L:a'),
      _error(3, 'itself'),
    );
    expect(() => parseArchitecture('${head}server a'), _error(2, 'expected'));
    expect(() => parseArchitecture(head), _error(1, 'needs a service'));
  });

  test('an edge puts its other end a cell away on the side it leaves', () {
    final cells = placeArchitecture(parseArchitecture(_source));
    final (sx, sy) = cells['server']!;
    expect(cells['db'], (sx + 1, sy), reason: 'db:L -- R:server');
    expect(cells['disk1'], (sx, sy + 1), reason: 'disk1:T -- B:server');
    expect(cells['gateway'], (sx - 1, sy));
    expect(cells['hub'], (sx - 1, sy + 1));
  });

  test('a taken cell sends a service on; a loose one starts apart', () {
    final cells = placeArchitecture(
      parseArchitecture(
        'architecture-beta\nservice a\nservice b\nservice c\nservice d\n'
        'a:R -- L:b\na:R -- L:c\n',
      ),
    );
    expect(cells['b'], (1, 0));
    expect(cells['c'], (2, 0), reason: 'past b, the same way');
    expect(cells['d']!.$1, greaterThan(cells['c']!.$1 + 1));
  });

  test('a row is one icon line: an edge across it is straight', () {
    final layout = _layout(_source);
    final edge = layout.edges.first;
    expect(edge.points, hasLength(2));
    expect(edge.points.first, _node(layout, 'db').icon.centerLeft);
    expect(edge.points.last, _node(layout, 'server').icon.centerRight);
  });

  test('an edge runs at right angles, from side to side', () {
    final layout = _layout(_source);
    for (final edge in layout.edges) {
      final points = edge.points;
      for (var i = 0; i + 1 < points.length; i++) {
        final a = points[i];
        final b = points[i + 1];
        expect(
          (a.dx - b.dx).abs() < 1e-9 || (a.dy - b.dy).abs() < 1e-9,
          isTrue,
          reason: '${edge.edge.from}>${edge.edge.to}',
        );
      }
    }
  });

  test("a group's box holds its services and keeps the others out", () {
    final layout = _layout(_source);
    final box = layout.groups.single.rect;
    for (final node in layout.nodes) {
      final inside = node.service.group == 'api';
      expect(box.overlaps(node.icon), inside, reason: node.service.id);
    }
    // {group}: the edge reaches the box's side, level with the service.
    final last = layout.edges.last.points.last;
    expect(last.dx, box.left);
    expect(last.dy, _node(layout, 'disk1').icon.center.dy);
  });

  test('a label sits on its edge', () {
    final layout = _layout(_source);
    final calls = layout.edges[3];
    expect(calls.labelBox!.center.dy, closeTo(calls.points.first.dy, 1e-9));
  });

  test('an architecture fence dispatches and exports', () {
    expect(parseMermaid(_source), isA<MermaidArchitecture>());
    final svg = diagramSvg(_source, const DiagramStyle())!;
    expect(svg, contains('Gateway'));
    expect(svg, contains('calls'));
  });
}
