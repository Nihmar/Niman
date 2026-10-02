// Three Mermaid charts (#530) — kanban boards, quadrant charts and xy
// charts: each parsed as written, laid out, and drawn on the canvas and in
// the SVG.
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_painter.dart';
import 'package:niman/src/diagrams/diagram_result.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_svg.dart';
import 'package:niman/src/diagrams/kanban_layout.dart';
import 'package:niman/src/diagrams/kanban_model.dart';
import 'package:niman/src/diagrams/kanban_parser.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/quadrant_layout.dart';
import 'package:niman/src/diagrams/quadrant_parser.dart';
import 'package:niman/src/diagrams/xy_chart_layout.dart';
import 'package:niman/src/diagrams/xy_chart_model.dart';
import 'package:niman/src/diagrams/xy_chart_parser.dart';

const DiagramStyle _style = DiagramStyle();

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

const String _board = '''
kanban
  Todo
    [Create documentation]
    docs[Write the blog post about the new diagram]
  id2[In progress]
    id6[Build the renderer]@{ ticket: MC-2037, assigned: 'knsv', priority: 'Very High' }
  Done
''';

const String _quadrant = '''
quadrantChart
  title Reach and engagement
  x-axis Low Reach --> High Reach
  y-axis Low Engagement --> High Engagement
  quadrant-1 Expand
  quadrant-2 Promote
  quadrant-3 Re-evaluate
  quadrant-4 Improve
  Campaign A: [0.3, 0.6]
  Campaign B:::hot: [0.95, 0.05] radius: 10
''';

const String _xy = '''
xychart-beta
  title "Sales revenue"
  x-axis [jan, feb, mar, apr]
  y-axis "Revenue (in EUR)" 0 --> 10000
  bar "Actual" [5000, 6000, 7500, 8200]
  line "Plan" [4000, 6500, 7000, 9000]
''';

void _paints(String source) {
  final ready = resolveDiagram(source, _style) as DiagramReady;
  final recorder = ui.PictureRecorder();
  DiagramPainter(
    drawing: ready.drawing,
    style: _style,
  ).paint(ui.Canvas(recorder), ready.drawing.size);
  recorder.endRecording().dispose();
  expect(diagramSvg(source, _style), startsWith('<svg '));
}

void main() {
  group('kanban', () {
    test('indentation tells a column from its cards', () {
      final board = parseKanban(_board);
      expect(board.columns.map((c) => c.title), [
        'Todo',
        'In progress',
        'Done',
      ]);
      expect(board.columns.first.cards.map((c) => c.text), [
        'Create documentation',
        'Write the blog post about the new diagram',
      ]);
      final card = board.columns[1].cards.single;
      expect(card.text, 'Build the renderer');
      expect(card.ticket, 'MC-2037');
      expect(card.assigned, 'knsv');
      expect(card.priority, KanbanPriority.veryHigh);
      expect(board.columns.last.cards, isEmpty);
    });

    test('cards stack in their column, wrapped to it', () {
      final layout = layoutKanban(parseKanban(_board), _style);
      final todo = layout.columns.first.rect;
      final cards = layout.cards.take(2).toList();
      expect(cards[1].rect.top, greaterThan(cards[0].rect.bottom));
      expect(cards[1].lines.length, greaterThan(1));
      for (final card in cards) {
        expect(todo.contains(card.rect.center), isTrue);
      }
      expect(layout.cards[2].meta, 'MC-2037 · knsv');
      expect(layout.columns[1].rect.left, greaterThan(todo.right));
    });

    test('a board dispatches, paints and exports', () {
      expect(parseMermaid(_board), isA<MermaidKanban>());
      _paints(_board);
    });

    test('an unclosed metadata names its line', () {
      expect(
        () => parseKanban('kanban\n  Todo\n    [a]@{ ticket: 1'),
        _error(3, 'expected "}"'),
      );
      expect(() => parseKanban('kanban'), _error(1, 'needs a column'));
    });
  });

  group('quadrant chart', () {
    test('axes, quadrants and points read as written', () {
      final chart = parseQuadrant(_quadrant);
      expect((chart.xLow, chart.xHigh), ('Low Reach', 'High Reach'));
      expect((chart.yLow, chart.yHigh), ('Low Engagement', 'High Engagement'));
      expect(chart.quadrants, ['Expand', 'Promote', 'Re-evaluate', 'Improve']);
      expect(chart.points.map((p) => (p.label, p.x, p.y)), [
        ('Campaign A', 0.3, 0.6),
        ('Campaign B', 0.95, 0.05),
      ]);
      expect(chart.points.last.radius, 10);
    });

    test('a point sits where its coordinates say, its name in the plot', () {
      final layout = layoutQuadrant(parseQuadrant(_quadrant), _style);
      final plot = layout.plot;
      final a = layout.dots.first.centre;
      expect(a.dx, closeTo(plot.left + 0.3 * plot.width, 0.01));
      expect(a.dy, closeTo(plot.bottom - 0.6 * plot.height, 0.01));
      for (final dot in layout.dots) {
        expect(plot.contains(dot.labelBox.topLeft), isTrue);
        expect(plot.contains(dot.labelBox.bottomRight), isTrue);
      }
      // Quadrant 1 is the top right.
      expect(layout.quadrants.first.rect.left, closeTo(plot.center.dx, 0.01));
      expect(layout.quadrants.first.rect.top, closeTo(plot.top, 0.01));
    });

    test('a chart dispatches, paints and exports', () {
      expect(parseMermaid(_quadrant), isA<MermaidQuadrant>());
      _paints(_quadrant);
    });

    test('a point off the chart names its line', () {
      expect(
        () => parseQuadrant('quadrantChart\nA: [1.5, 0.2]'),
        _error(2, 'from 0 to 1'),
      );
      expect(
        () => parseQuadrant('quadrantChart\nA point'),
        _error(2, 'expected a point'),
      );
    });
  });

  group('xy chart', () {
    test('categories, the value range and the series read as written', () {
      final chart = parseXyChart(_xy);
      expect(chart.title, 'Sales revenue');
      expect(chart.categories, ['jan', 'feb', 'mar', 'apr']);
      expect(chart.yTitle, 'Revenue (in EUR)');
      expect(chart.yRange, (0.0, 10000.0));
      expect(chart.series.map((s) => (s.kind, s.name)), [
        (XySeriesKind.bar, 'Actual'),
        (XySeriesKind.line, 'Plan'),
      ]);
    });

    test('without named categories, the x range numbers them', () {
      final chart = parseXyChart(
        'xychart-beta horizontal\nx-axis 0 --> 30\nbar [1, 2, 3, 4]',
      );
      expect(chart.horizontal, isTrue);
      expect(chart.categories, ['0', '10', '20', '30']);
    });

    test('a bar stands on zero to its value, a line through the slots', () {
      final layout = layoutXyChart(parseXyChart(_xy), _style);
      final plot = layout.plot;
      final first = layout.bars.first.rect;
      expect(first.bottom, closeTo(plot.bottom, 0.01));
      expect(first.top, closeTo(plot.bottom - 0.5 * plot.height, 0.01));
      final line = layout.lines.single.points;
      expect(line, hasLength(4));
      expect(line[1].dy, closeTo(plot.bottom - 0.65 * plot.height, 0.01));
      expect(line.first.dx, closeTo(first.left + plot.width / 4 * 0.35, 1));
      expect(layout.legend.map((e) => e.name.text), ['Actual', 'Plan']);
      // Round steps: 0, 2000, … 10000.
      expect(layout.valueLabels.map((v) => v.text).first, '0');
      expect(layout.valueLabels.map((v) => v.text).last, '10000');
    });

    test('a horizontal chart turns the bars across', () {
      final layout = layoutXyChart(
        parseXyChart('xychart-beta horizontal\nx-axis [a, b]\nbar [1, 3]'),
        _style,
      );
      final bars = layout.bars.map((b) => b.rect).toList();
      expect(bars[1].width, greaterThan(bars[0].width));
      expect(bars[1].top, greaterThan(bars[0].top));
    });

    test('the drawing ends under its lowest text, wherever titles sit', () {
      for (final source in [
        // The value title over the plot: nothing of it under the labels.
        'xychart-beta\ny-axis "Notes" 0 --> 120\nx-axis [a, b]\nbar [1, 2]',
        // The category title under the labels: room for it.
        'xychart-beta\nx-axis "Month" [a, b]\nbar [1, 2]',
      ]) {
        final layout = layoutXyChart(parseXyChart(source), _style);
        var lowest = layout.plot.bottom;
        for (final text in [
          ...layout.valueLabels,
          ...layout.categoryLabels,
          ...layout.axisTitles,
        ]) {
          lowest = lowest > text.box.bottom ? lowest : text.box.bottom;
        }
        expect(layout.size.height - lowest, closeTo(6 + 12, 1e-9));
      }
    });

    test('a chart dispatches, paints and exports', () {
      expect(parseMermaid(_xy), isA<MermaidXyChart>());
      _paints(_xy);
    });

    test('what does not read names its line', () {
      expect(
        () => parseXyChart('xychart-beta\nx-axis [a, b, c]\nbar [1, 2]'),
        _error(3, 'expected 3 values'),
      );
      expect(
        () => parseXyChart('xychart-beta\nbar [1, many]'),
        _error(2, 'expected a number'),
      );
      expect(
        () => parseXyChart('xychart-beta\npie [1]'),
        _error(2, 'found "pie [1]"'),
      );
      expect(() => parseXyChart('xychart-beta'), _error(1, 'a bar or a line'));
    });
  });
}
