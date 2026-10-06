// A Mermaid Sankey diagram (#530): its flows read from CSV, laid out a
// column a step with bars and bands as big as their values, and drawn on
// the canvas and in the SVG.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_svg.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/sankey_layout.dart';
import 'package:niman/src/diagrams/sankey_parser.dart';

const DiagramStyle _style = DiagramStyle();

const String _energy = '''
sankey-beta

%% source,target,value
Solar,Grid,60
Wind,Grid,40
Grid,Homes,70
Grid,"Industry, heavy",25
Grid,Losses,5
Solar,Batteries,20
Batteries,Homes,20
''';

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

void main() {
  test('flows are read as CSV, a quoted field keeping its comma', () {
    final chart = parseSankey(_energy);
    expect(chart.nodes, [
      'Solar',
      'Grid',
      'Wind',
      'Homes',
      'Industry, heavy',
      'Losses',
      'Batteries',
    ]);
    expect(chart.links, hasLength(7));
    expect(chart.links[3].value, 25);
    expect(
      parseSankey('sankey-beta\n"Say ""hi""",B,1').nodes.first,
      'Say "hi"',
    );
  });

  test('a flow that loops back, or does not read, names its line', () {
    expect(
      () => parseSankey('sankey-beta\nA,B,1\nB,C,1\nC,A,1'),
      _error(4, 'cannot come back'),
    );
    expect(() => parseSankey('sankey-beta\nA,A,1'), _error(2, 'come back'));
    expect(
      () => parseSankey('sankey-beta\nA,B,lots'),
      _error(2, 'expected a value'),
    );
    // NaN and Infinity read as numbers, and no bar can be drawn from them.
    for (final value in ['NaN', 'Infinity', '1e400']) {
      expect(
        () => parseSankey('sankey-beta\nA,B,$value'),
        _error(2, 'expected a value'),
      );
    }
    expect(() => parseSankey('sankey-beta\nA,B'), _error(2, '2 fields'));
    expect(() => parseSankey('sankey-beta'), _error(1, 'needs a flow'));
  });

  test('columns follow the flow, the sinks in the last', () {
    final layout = layoutSankey(parseSankey(_energy), _style);
    double x(int node) => layout.nodes[node].rect.left;
    // Solar and Wind first, then Grid and Batteries, then the sinks.
    expect(x(0), x(2));
    expect(x(1), greaterThan(x(0)));
    expect(x(6), x(1));
    for (final sink in [3, 4, 5]) {
      expect(x(sink), greaterThan(x(1)));
    }
  });

  test('a bar is as tall as what passes through it', () {
    final layout = layoutSankey(parseSankey(_energy), _style);
    final grid = layout.nodes[1].rect.height;
    final homes = layout.nodes[3].rect.height;
    // Grid carries 100, Homes 90 (70 + 20).
    expect(homes / grid, closeTo(0.9, 0.01));
    final losses = layout.nodes[5].rect.height;
    expect(losses / grid, closeTo(0.05, 0.01));
  });

  test('a band runs from its source bar to its target bar', () {
    final layout = layoutSankey(parseSankey(_energy), _style);
    final first = layout.bands.first.outline;
    final solar = layout.nodes[0].rect;
    final grid = layout.nodes[1].rect;
    expect(first.first.dx, closeTo(solar.right, 0.01));
    expect(first[first.length ~/ 2 - 1].dx, closeTo(grid.left, 0.01));
  });

  test("a source has its own colour, a node downstream its inflow's", () {
    final layout = layoutSankey(parseSankey(_energy), _style);
    final colours = [for (final node in layout.nodes) node.colour];
    expect(colours[0], 0, reason: 'Solar');
    expect(colours[2], 1, reason: 'Wind');
    expect(colours[1], 0, reason: 'Grid draws most from Solar');
    expect(colours[6], 0, reason: 'Batteries, from Solar');
  });

  test('labels stay in the drawing', () {
    final layout = layoutSankey(parseSankey(_energy), _style);
    final bounds = Offset.zero & layout.size;
    for (final node in layout.nodes) {
      expect(bounds.contains(node.labelBox.topLeft), isTrue);
      expect(bounds.contains(node.labelBox.bottomRight), isTrue);
    }
  });

  test('a Sankey fence dispatches and exports', () {
    expect(parseMermaid(_energy), isA<MermaidSankey>());
    final svg = diagramSvg(_energy, _style)!;
    expect(svg, contains('Industry, heavy'));
    expect(svg, contains('rgba('));
  });
}
