// A Mermaid user journey (#530): its tasks, scores and actors as written,
// laid out a column a task with a face under each, and drawn on the canvas
// and in the SVG.
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/canvas_target.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/journey_layout.dart';
import 'package:niman/src/diagrams/journey_parser.dart';
import 'package:niman/src/diagrams/journey_renderer.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/svg_target.dart';

const DiagramStyle _style = DiagramStyle();

const String _day = '''
journey
  title My working day
  section Go to work
    Make tea: 5: Me
    Go upstairs: 3: Me
    Do work: 1: Me, Cat
  section Go home
    Go downstairs: 5: Me
    Sit down: 4
''';

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

void main() {
  test('tasks carry their score and actors, sections their tasks', () {
    final journey = parseJourney(_day);
    expect(journey.title, 'My working day');
    expect(journey.actors, ['Me', 'Cat']);
    expect(journey.sections.map((s) => s.name), ['Go to work', 'Go home']);
    final work = journey.sections.first.tasks;
    expect(work.map((t) => t.label), ['Make tea', 'Go upstairs', 'Do work']);
    expect(work.map((t) => t.score), [5, 3, 1]);
    expect(work.last.actors, [0, 1]);
    expect(journey.sections.last.tasks.last.actors, isEmpty);
  });

  test('what does not read names its line', () {
    expect(() => parseJourney('journey\nTea: 7: Me'), _error(2, 'from 0 to 5'));
    expect(
      () => parseJourney('journey\nTea: NaN: Me'),
      _error(2, 'from 0 to 5'),
    );
    expect(
      () => parseJourney('journey\nJust words'),
      _error(2, 'expected a task'),
    );
    expect(
      () => parseJourney('journey\ntitle Empty'),
      _error(1, 'needs a task'),
    );
  });

  test('a better task has its face higher, and smiling', () {
    final layout = layoutJourney(parseJourney(_day), _style);
    final tea = layout.tasks[0];
    final stairs = layout.tasks[1];
    final work = layout.tasks[2];
    expect(tea.face.center.dy, lessThan(stairs.face.center.dy));
    expect(stairs.face.center.dy, lessThan(work.face.center.dy));
    expect([tea.mood, stairs.mood, work.mood], [1, 0, -1]);
    for (final task in layout.tasks) {
      expect(task.face.top, greaterThan(task.box.bottom));
      expect(task.face.center.dx, closeTo(task.box.center.dx, 0.01));
    }
  });

  test('a task shows a dot for each actor, the legend names them', () {
    final layout = layoutJourney(parseJourney(_day), _style);
    expect(layout.tasks[2].dots.map((d) => d.$2), [0, 1]);
    for (final (at, _) in layout.tasks[2].dots) {
      expect(layout.tasks[2].box.contains(at), isTrue);
    }
    expect(layout.legend.map((r) => r.name), ['Me', 'Cat']);
    expect(
      layout.legend.first.textBox.right,
      lessThan(layout.tasks.first.box.left),
    );
  });

  test('a header spans its tasks, and everything is in the drawing', () {
    final layout = layoutJourney(parseJourney(_day), _style);
    final first = layout.sections.first.rect;
    expect(first.left, closeTo(layout.tasks[0].box.left, 0.01));
    expect(first.right, closeTo(layout.tasks[2].box.right, 0.01));
    final bounds = Offset.zero & layout.size;
    for (final task in layout.tasks) {
      expect(bounds.contains(task.face.bottomRight), isTrue);
      expect(bounds.contains(task.box.bottomRight), isTrue);
    }
  });

  test('a journey dispatches, paints and exports', () {
    expect(parseMermaid(_day), isA<MermaidJourney>());
    final layout = layoutJourney(parseJourney(_day), _style);
    final recorder = ui.PictureRecorder();
    JourneyRenderer(
      layout: layout,
      style: _style,
    ).paint(CanvasDiagramTarget(ui.Canvas(recorder)));
    recorder.endRecording().dispose();
    final svg = SvgDiagramTarget(
      width: layout.size.width,
      height: layout.size.height,
    );
    JourneyRenderer(layout: layout, style: _style).paint(svg);
    expect(svg.finish(), contains('Go upstairs'));
  });
}
