// A Mermaid timeline (#530): its periods, their events and sections as
// written, laid out a column a period, and drawn on the canvas and in the
// SVG.
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/canvas_target.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/svg_target.dart';
import 'package:niman/src/diagrams/timeline_layout.dart';
import 'package:niman/src/diagrams/timeline_model.dart';
import 'package:niman/src/diagrams/timeline_parser.dart';
import 'package:niman/src/diagrams/timeline_renderer.dart';

const DiagramStyle _style = DiagramStyle();

const String _history = '''
timeline
  title History of Social Media
  2002 : LinkedIn
  2004 : Facebook : Google
       : Orkut
  2005 : YouTube
  2006 : Twitter
''';

List<TimelinePeriod> _periods(TimelineChart chart) => [
  for (final section in chart.sections) ...section.periods,
];

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

void main() {
  test('a period carries the events after it, on its line and after', () {
    final chart = parseTimeline(_history);
    expect(chart.title, 'History of Social Media');
    expect(_periods(chart).map((p) => '${p.label}: ${p.events.join(', ')}'), [
      '2002: LinkedIn',
      '2004: Facebook, Google, Orkut',
      '2005: YouTube',
      '2006: Twitter',
    ]);
  });

  test('a colon in a time is part of it, and a period may have no event', () {
    final chart = parseTimeline(
      'timeline\n10:30 : Coffee : Mail\nLunch\n%% a note\n14:00 : Call',
    );
    expect(_periods(chart).map((p) => '${p.label}: ${p.events.join(', ')}'), [
      '10:30: Coffee, Mail',
      'Lunch: ',
      '14:00: Call',
    ]);
  });

  test('sections group their periods', () {
    final chart = parseTimeline(
      'timeline\nEarly : a\nsection Industry\n1.0 : Steam\n2.0 : Power\n'
      'section Digital\n3.0 : Computers',
    );
    expect(chart.sections.map((s) => s.name), [null, 'Industry', 'Digital']);
    expect(chart.sections[1].periods.map((p) => p.label), ['1.0', '2.0']);
  });

  test('what does not read names its line', () {
    expect(
      () => parseTimeline('timeline\n: orphan'),
      _error(2, 'needs a period'),
    );
    expect(
      () => parseTimeline('timeline\ntitle Empty'),
      _error(1, 'needs a period'),
    );
  });

  test('a column a period, its events under it, in its order', () {
    final layout = layoutTimeline(parseTimeline(_history), _style);
    final periods = layout.boxes.where((b) => !b.event).toList();
    final events = layout.boxes.where((b) => b.event).toList();
    expect(periods, hasLength(4));
    expect(events, hasLength(6));
    for (var i = 1; i < periods.length; i++) {
      expect(periods[i].rect.left, greaterThan(periods[i - 1].rect.right));
    }
    // 2004's three events under it, one below the other.
    final under = events.where(
      (e) => e.rect.center.dx == periods[1].rect.center.dx,
    );
    expect(under.map((e) => e.lines.single), ['Facebook', 'Google', 'Orkut']);
    final (from, to) = layout.axis;
    for (final period in periods) {
      expect(period.rect.bottom, lessThan(from.dy));
    }
    for (final event in events) {
      expect(event.rect.top, greaterThan(from.dy));
    }
    expect(to.dx, greaterThan(periods.last.rect.right));
    expect(layout.connectors, hasLength(4));
  });

  test('a named section takes a colour, its periods and events with it', () {
    final layout = layoutTimeline(
      parseTimeline(
        'timeline\nEarly : a\nsection One\nX : x\nsection Two\nY : y',
      ),
      _style,
    );
    expect(layout.sections.map((s) => (s.lines.single, s.colour)), [
      ('One', 0),
      ('Two', 1),
    ]);
    expect(layout.boxes.map((b) => b.colour), [null, null, 0, 0, 1, 1]);
    final one = layout.sections.first.rect;
    expect(one.left, closeTo(layout.boxes[2].rect.left, 0.01));
    expect(one.right, closeTo(layout.boxes[2].rect.right, 0.01));
  });

  test('a timeline paints and exports', () {
    final layout = layoutTimeline(parseTimeline(_history), _style);
    final recorder = ui.PictureRecorder();
    TimelineRenderer(
      layout: layout,
      style: _style,
    ).paint(CanvasDiagramTarget(ui.Canvas(recorder)));
    recorder.endRecording().dispose();
    final svg = SvgDiagramTarget(
      width: layout.size.width,
      height: layout.size.height,
    );
    TimelineRenderer(layout: layout, style: _style).paint(svg);
    final text = svg.finish();
    expect(text, contains('LinkedIn'));
    expect(text, contains('History of Social Media'));
  });

  test('a timeline fence dispatches to its own drawing', () {
    expect(parseMermaid(_history), isA<MermaidTimeline>());
  });
}
