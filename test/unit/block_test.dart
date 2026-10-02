// A Mermaid block diagram (#530): its blocks read into a grid of columns,
// groups nesting a grid of their own, laid out with the columns lined up
// and edges from outline to outline, and drawn on the canvas and in the
// SVG.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/block_layout.dart';
import 'package:niman/src/diagrams/block_model.dart';
import 'package:niman/src/diagrams/block_parser.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_svg.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';

const DiagramStyle _style = DiagramStyle();

const String _system = '''
block-beta
  columns 3
  front["Frontend"]:3
  space down<["&nbsp;"]>(down) space
  block:services:3
    columns 3
    api(["API"]) auth{{"Auth"}} jobs[["Jobs"]]
  end
  db[("Database")] space cache(("Cache"))
  api --> db
  api -- "reads" --> cache
  jobs -.-> db
  style api fill:#f9f
''';

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

BlockLayout _layout(String source) => layoutBlock(parseBlock(source), _style);

Rect _rect(BlockLayout layout, String id) =>
    layout.blocks.firstWhere((b) => b.node.id == id).rect;

void main() {
  test('blocks, spaces and a group fill the grid in order', () {
    final root = parseBlock(_system).root;
    expect(root.columns, 3);
    final kinds = [for (final item in root.children) item.runtimeType];
    expect(kinds, [
      BlockNode,
      BlockSpace,
      BlockNode,
      BlockSpace,
      BlockGroup,
      BlockNode,
      BlockSpace,
      BlockNode,
    ]);
    final front = root.children.first as BlockNode;
    expect((front.label, front.span), ('Frontend', 3));
    final arrow = root.children[2] as BlockNode;
    expect(arrow.arrow, BlockArrowDirection.down);
    expect(arrow.label, ' ', reason: '&nbsp; is written out');
    final group = root.children[4] as BlockGroup;
    expect((group.id, group.span, group.columns), ('services', 3, 3));
    expect(
      [for (final c in group.children) (c as BlockNode).shape],
      [FlowNodeShape.stadium, FlowNodeShape.hexagon, FlowNodeShape.subroutine],
    );
    expect((root.children[5] as BlockNode).shape, FlowNodeShape.database);
  });

  test('edges join blocks by id, their stroke and label read', () {
    final edges = parseBlock(_system).edges;
    expect(
      [for (final e in edges) '${e.from}>${e.to}'],
      ['api>db', 'api>cache', 'jobs>db'],
    );
    expect(edges[1].label, 'reads');
    expect(edges[2].style, FlowEdgeStyle.dotted);
    expect(edges[0].end, FlowEdgeEnd.arrow);
  });

  test('a line with an edge names its blocks without placing them', () {
    final root = parseBlock('block-beta\na --> b\nb a').root;
    expect([for (final c in root.children) (c as BlockNode).id], ['b', 'a']);
    // A block named only in an edge goes after the group it was named in.
    final late = parseBlock('block-beta\nblock:g\nx --> y\nend\nz')
        .root
        .children;
    expect(late.first, isA<BlockGroup>());
    expect(
      [
        for (final c in (late.first as BlockGroup).children)
          (c as BlockNode).id,
      ],
      ['x', 'y'],
    );
  });

  test('a mistake names its line', () {
    expect(() => parseBlock('block-beta\nblock:g\na'), _error(2, '"end"'));
    expect(() => parseBlock('block-beta\na\nend'), _error(3, 'closes no'));
    expect(() => parseBlock('block-beta\ncolumns x'), _error(2, 'columns'));
    expect(
      () => parseBlock('block-beta\na<["go"]>(sideways)'),
      _error(2, 'direction'),
    );
    expect(() => parseBlock('block-beta\na --> a'), _error(2, 'itself'));
    expect(() => parseBlock('block-beta\na["open'), _error(2, '"]"'));
    expect(() => parseBlock('block-beta\n'), _error(1, 'needs a block'));
  });

  test('entities are written out, an unknown one left as it is', () {
    expect(decodeMermaidEntities('a&nbsp;b'), 'a b');
    expect(
      decodeMermaidEntities('#quot;hi#quot; &amp; &#65;#66;'),
      '"hi" & AB',
    );
    expect(decodeMermaidEntities('&bogus; &12; #x;'), '&bogus; &12; #x;');
  });

  test('cells of one column line up, a span as wide as its columns', () {
    final layout = _layout(
      'block-beta\ncolumns 3\na b["a much longer one"] c\nd:2 e',
    );
    final a = _rect(layout, 'a');
    final b = _rect(layout, 'b');
    final c = _rect(layout, 'c');
    final d = _rect(layout, 'd');
    final e = _rect(layout, 'e');
    expect(d.left, a.left);
    expect(e.left, c.left);
    expect(d.right, closeTo(b.right, 1e-9));
    // Every column as wide as the widest needs.
    expect(a.width, closeTo(b.width, 1e-9));
    expect(d.top, greaterThan(a.bottom));
  });

  test('a block that does not fit the rest of its row starts the next', () {
    final layout = _layout('block-beta\ncolumns 3\na b c:2');
    expect(_rect(layout, 'c').left, _rect(layout, 'a').left);
    expect(_rect(layout, 'c').top, greaterThan(_rect(layout, 'a').bottom));
  });

  test('without columns every block shares one row', () {
    final layout = _layout('block-beta\na b c');
    final tops = {for (final b in layout.blocks) b.rect.top};
    expect(tops, hasLength(1));
  });

  test("a group's box holds its blocks", () {
    final layout = _layout(_system);
    final box = layout.groups.single;
    for (final id in ['api', 'auth', 'jobs']) {
      final rect = _rect(layout, id);
      expect(
        box.contains(rect.topLeft) && box.contains(rect.bottomRight),
        isTrue,
      );
    }
  });

  test('an edge runs from one outline to the other', () {
    final layout = _layout(_system);
    final edge = layout.edges.first;
    final api = _rect(layout, 'api');
    final db = _rect(layout, 'db');
    expect(edge.start.dy, closeTo(api.bottom, 0.5));
    expect(edge.end.dy, closeTo(db.top, 0.5));
  });

  test('a label fits between the blocks it joins, clear of the caps', () {
    final layout = _layout('block-beta\na b\na -- "a long label here" --> b');
    final edge = layout.edges.single;
    final a = _rect(layout, 'a');
    final b = _rect(layout, 'b');
    expect(edge.labelBox!.left, greaterThanOrEqualTo(a.right + 11));
    expect(edge.labelBox!.right, lessThanOrEqualTo(b.left - 11));
  });

  test('an arrow grows along itself only', () {
    final layout = _layout(
      'block-beta\ncolumns 1\nwide["a block much wider than the arrow"]\n'
      'go<["go"]>(down)',
    );
    final arrow = _rect(layout, 'go');
    expect(arrow.width, lessThan(_rect(layout, 'wide').width / 2));
    expect(arrow.center.dx, closeTo(_rect(layout, 'wide').center.dx, 1e-9));
  });

  test('a block fence dispatches and exports', () {
    expect(parseMermaid(_system), isA<MermaidBlock>());
    expect(parseMermaid('block\na'), isA<MermaidBlock>());
    final svg = diagramSvg(_system, _style)!;
    expect(svg, contains('Frontend'));
    expect(svg, contains('reads'));
  });
}
