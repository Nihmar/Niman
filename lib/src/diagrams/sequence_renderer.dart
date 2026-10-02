/// The one drawing of a sequence diagram (#530): lifelines, frames,
/// messages, notes and the participant boxes.
///
/// Like the flowchart's renderer it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture, and every measurement
/// comes from the layout.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/sequence_geometry.dart';
import 'package:niman/src/diagrams/sequence_model.dart';

/// The width of a message's line.
const double _stroke = 1.5;

/// Draws a [SequenceLayout] through a [DiagramTarget].
final class SequenceRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final SequenceLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  /// Paints everything: lifelines and frames behind, then the messages and
  /// notes, the participant boxes on top.
  void paint(DiagramTarget target) {
    for (final participant in layout.participants) {
      target.line(
        Offset(participant.centerX, participant.head.bottom),
        Offset(participant.centerX, participant.foot.top),
        color: _palette.edge,
        dashed: true,
      );
    }
    for (final frame in layout.frames) {
      _frame(target, frame);
    }
    for (final message in layout.messages) {
      _message(target, message);
    }
    for (final note in layout.notes) {
      _note(target, note);
    }
    for (final participant in layout.participants) {
      _box(target, participant.head, participant.lines);
      _box(target, participant.foot, participant.lines);
    }
  }

  void _box(DiagramTarget target, Rect rect, List<String> lines) {
    target
      ..polygon(
        _rounded(rect),
        fill: _palette.nodeFill,
        stroke: _palette.nodeStroke,
        strokeWidth: style.nodeStrokeWidth,
      )
      ..text(lines, rect, color: _palette.nodeText, fontSize: style.fontSize);
  }

  void _frame(DiagramTarget target, LaidOutFrame frame) {
    final textHeight = style.fontSize * style.lineHeight;
    target
      ..polygon(_rounded(frame.rect), stroke: _palette.subgraphStroke)
      ..polygon(
        _rounded(frame.tab),
        fill: _palette.subgraphFill,
        stroke: _palette.subgraphStroke,
      )
      ..text(
        [frame.kind.title],
        frame.tab,
        color: _palette.subgraphTitle,
        fontSize: style.fontSize,
        weight: FontWeight.w600,
      );
    if (frame.label.isNotEmpty) {
      target.text(
        [frame.label],
        Rect.fromLTRB(
          frame.tab.right + 8,
          frame.tab.top,
          frame.rect.right - 8,
          frame.tab.bottom,
        ),
        color: _palette.subgraphTitle,
        fontSize: style.fontSize,
        alignLeft: true,
      );
    }
    for (final separator in frame.separators) {
      target.line(
        Offset(frame.rect.left, separator.y),
        Offset(frame.rect.right, separator.y),
        color: _palette.subgraphStroke,
        dashed: true,
      );
      if (separator.label.isEmpty) continue;
      target.text(
        [separator.label],
        Rect.fromLTWH(
          frame.rect.left + 8,
          separator.y + 4,
          frame.rect.width - 16,
          textHeight,
        ),
        color: _palette.subgraphTitle,
        fontSize: style.fontSize,
        alignLeft: true,
      );
    }
  }

  void _message(DiagramTarget target, LaidOutMessage laid) {
    final message = laid.message;
    final loop = laid.loop;
    if (loop != null) {
      // Out, down and back to its own lifeline.
      final points = [
        loop.topLeft,
        loop.topRight,
        loop.bottomRight,
        loop.bottomLeft,
      ];
      for (var i = 0; i + 1 < points.length; i++) {
        target.line(
          points[i],
          points[i + 1],
          color: _palette.edge,
          strokeWidth: _stroke,
          dashed: message.dashed,
        );
      }
      _cap(target, loop.bottomLeft, const Offset(-1, 0), message.arrow);
      if (message.twoWay) {
        _cap(target, loop.topLeft, const Offset(-1, 0), message.arrow);
      }
    } else {
      final from = Offset(laid.fromX, laid.y);
      final to = Offset(laid.toX, laid.y);
      final towards = laid.toX >= laid.fromX
          ? const Offset(1, 0)
          : const Offset(-1, 0);
      target.line(
        from,
        to,
        color: _palette.edge,
        strokeWidth: _stroke,
        dashed: message.dashed,
      );
      _cap(target, to, towards, message.arrow);
      if (message.twoWay) _cap(target, from, -towards, message.arrow);
    }
    if (laid.text.isEmpty) return;
    target.text(
      laid.text,
      laid.textBox,
      color: _palette.edge,
      fontSize: style.fontSize,
      alignLeft: loop != null,
    );
  }

  /// The head [arrow] draws at [tip], pointing along [direction].
  void _cap(
    DiagramTarget target,
    Offset tip,
    Offset direction,
    SequenceArrow arrow,
  ) {
    final normal = Offset(-direction.dy, direction.dx);
    switch (arrow) {
      case SequenceArrow.none:
        return;
      case SequenceArrow.filled:
        final back = tip - direction * 11;
        target.polygon([
          tip,
          back + normal * 5,
          back - normal * 5,
        ], fill: _palette.edge);
      case SequenceArrow.open:
        final back = tip - direction * 10;
        target
          ..line(tip, back + normal * 5, color: _palette.edge, strokeWidth: 1.5)
          ..line(
            tip,
            back - normal * 5,
            color: _palette.edge,
            strokeWidth: 1.5,
          );
      case SequenceArrow.cross:
        final back = tip - direction * 5;
        target
          ..line(
            back - normal * 5,
            tip + normal * 5,
            color: _palette.edge,
            strokeWidth: _stroke,
          )
          ..line(
            back + normal * 5,
            tip - normal * 5,
            color: _palette.edge,
            strokeWidth: _stroke,
          );
    }
  }

  void _note(DiagramTarget target, LaidOutNote note) {
    target
      ..polygon(
        _rounded(note.rect),
        fill: _palette.subgraphFill,
        stroke: _palette.subgraphStroke,
      )
      ..text(
        note.lines,
        note.rect,
        color: _palette.subgraphTitle,
        fontSize: style.fontSize,
      );
  }

  List<Offset> _rounded(Rect rect) => DiagramShapes.polygonFor(
    FlowNodeShape.round,
    rect,
    radius: style.cornerRadius,
  );
}
