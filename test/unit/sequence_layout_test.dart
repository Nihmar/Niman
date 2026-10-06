// Laying a sequence diagram out (#530), and drawing it: every text fits
// where it is drawn, nothing reaches out of the drawing, frames nest, and
// the canvas and the SVG both draw it.
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/canvas_target.dart';
import 'package:niman/src/diagrams/diagram_drawing.dart';
import 'package:niman/src/diagrams/diagram_result.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_svg.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/sequence_geometry.dart';
import 'package:niman/src/diagrams/sequence_layout.dart';
import 'package:niman/src/diagrams/sequence_parser.dart';
import 'package:niman/src/diagrams/sequence_renderer.dart';

const DiagramStyle _style = DiagramStyle();

SequenceLayout _layout(String source) =>
    layoutSequence(parseSequence(source), _style);

/// Every rectangle the layout placed.
Iterable<Rect> _rects(SequenceLayout layout) => [
  for (final p in layout.participants) ...[p.head, p.foot],
  for (final m in layout.messages) ...[m.textBox, ?m.loop],
  for (final n in layout.notes) n.rect,
  for (final f in layout.frames) ...[f.rect, f.tab],
];

void _inside(SequenceLayout layout) {
  final bounds = Offset.zero & layout.size;
  for (final rect in _rects(layout)) {
    expect(
      bounds.inflate(0.01).contains(rect.topLeft),
      isTrue,
      reason: '$rect',
    );
    expect(
      bounds.inflate(0.01).contains(rect.bottomRight),
      isTrue,
      reason: '$rect',
    );
  }
}

void main() {
  test('a long message widens the gap until its text fits', () {
    final layout = _layout(
      'sequenceDiagram\nA->>B: a message far longer than the gap two short '
      'names would leave between their lifelines\nB-->>A: ok',
    );
    final first = layout.messages.first;
    expect(
      first.textBox.width,
      lessThanOrEqualTo((first.toX - first.fromX).abs()),
    );
    expect(first.text.length, greaterThan(1), reason: 'and it wraps');
    _inside(layout);
  });

  test('a message across columns widens all the gaps it spans', () {
    final layout = _layout(
      'sequenceDiagram\nparticipant A\nparticipant B\nparticipant C\n'
      'A->>C: a long message that passes over the middle lifeline',
    );
    final message = layout.messages.single;
    expect(
      message.textBox.width,
      lessThanOrEqualTo((message.toX - message.fromX).abs()),
    );
  });

  test('notes beside the outer lifelines stay in the drawing', () {
    final layout = _layout(
      'sequenceDiagram\nA->>B: hi\nNote left of A: a note on the far left\n'
      'Note right of B: and one on the far right',
    );
    final a = layout.participants.first.centerX;
    final b = layout.participants.last.centerX;
    expect(layout.notes.first.rect.right, lessThanOrEqualTo(a));
    expect(layout.notes.last.rect.left, greaterThanOrEqualTo(b));
    _inside(layout);
  });

  test('a note beside a lifeline keeps clear of the next one', () {
    final layout = _layout(
      'sequenceDiagram\nA->>B: hi\nNote right of A: a fairly wide note here',
    );
    expect(
      layout.notes.single.rect.right,
      lessThanOrEqualTo(layout.participants.last.centerX),
    );
  });

  test('a message to itself loops out and its text stays clear', () {
    final layout = _layout(
      'sequenceDiagram\nA->>A: think it over carefully\nA->>B: done',
    );
    final self = layout.messages.first;
    expect(self.loop, isNotNull);
    expect(
      self.textBox.right,
      lessThanOrEqualTo(layout.participants.last.centerX),
    );
    _inside(layout);
  });

  test('a frame holds what its block holds, a nested one inside it', () {
    final layout = _layout(
      'sequenceDiagram\nloop Every minute\n  alt sick\n    A->>B: not good\n'
      '  else well\n    A->>B: fine\n  end\nend',
    );
    final outer = layout.frames.first;
    final inner = layout.frames.last;
    expect(outer.kind.title, 'loop');
    expect(inner.kind.title, 'alt');
    expect(outer.rect.left, lessThan(inner.rect.left));
    expect(outer.rect.right, greaterThan(inner.rect.right));
    expect(outer.rect.bottom, greaterThanOrEqualTo(inner.rect.bottom));
    expect(inner.separators.single.label, '[well]');
    for (final message in layout.messages) {
      expect(inner.rect.contains(message.textBox.center), isTrue);
    }
    _inside(layout);
  });

  test('participants are drawn at the top and again at the foot', () {
    final layout = _layout('sequenceDiagram\nA->>B: hi');
    for (final participant in layout.participants) {
      expect(participant.foot.top, greaterThan(participant.head.bottom));
      expect(participant.foot.size, participant.head.size);
    }
    expect(
      layout.participants.first.foot.top,
      greaterThan(layout.messages.single.y),
    );
  });

  test('a sequence fence resolves, paints and exports', () {
    const source = 'sequenceDiagram\nAlice->>Bob: Hello <b>\nBob-->>Alice: Hi';
    expect(parseMermaid(source), isA<MermaidSequence>());
    final result = resolveDiagram(source, _style) as DiagramReady;
    final drawing = result.drawing as SequenceDrawing;
    final recorder = ui.PictureRecorder();
    SequenceRenderer(
      layout: drawing.layout,
      style: _style,
    ).paint(CanvasDiagramTarget(ui.Canvas(recorder)));
    recorder.endRecording().dispose();
    final svg = diagramSvg(source, _style)!;
    expect(svg, startsWith('<svg '));
    expect(svg, contains('Hello &lt;b&gt;'));
    expect(svg, contains('Alice'));
  });
}
