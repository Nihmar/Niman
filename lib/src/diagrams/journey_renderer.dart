/// The one drawing of a user journey (#530): the sections' headers, the
/// tasks with their actors' dots, a face under each and the legend.
///
/// Like the other renderers it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture. An actor takes the
/// palette's next series colour; the actors past its eight share the
/// neutral outline rather than a colour handed out twice.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/journey_geometry.dart';

/// How many straight pieces draw a face's mouth.
const int _mouthSteps = 8;

/// Draws a [JourneyLayout] through a [DiagramTarget].
final class JourneyRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final JourneyLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  /// Paints the headers, the tasks and their faces, the legend and the
  /// title.
  void paint(DiagramTarget target) {
    for (final section in layout.sections) {
      target
        ..polygon(
          _rounded(section.rect),
          fill: _palette.subgraphFill,
          stroke: _palette.subgraphStroke,
        )
        ..text(
          section.lines,
          section.rect,
          color: _palette.subgraphTitle,
          fontSize: style.fontSize,
          weight: FontWeight.w600,
        );
    }
    for (final task in layout.tasks) {
      target
        ..line(
          Offset(task.box.center.dx, task.box.bottom),
          Offset(task.face.center.dx, task.face.top),
          color: _palette.subgraphStroke,
          dashed: true,
        )
        ..polygon(
          _rounded(task.box),
          fill: _palette.nodeFill,
          stroke: _palette.nodeStroke,
          strokeWidth: style.nodeStrokeWidth,
        )
        ..text(
          task.lines,
          task.textBox,
          color: _palette.nodeText,
          fontSize: style.fontSize,
        );
      for (final (at, actor) in task.dots) {
        _dot(target, at, actor);
      }
      _face(target, task.face, task.mood);
    }
    for (final (index, row) in layout.legend.indexed) {
      _dot(target, row.dot, index);
      target.text(
        [row.name],
        row.textBox,
        color: _palette.nodeText,
        fontSize: style.fontSize,
        alignLeft: true,
      );
    }
    final title = layout.title;
    final box = layout.titleBox;
    if (title != null && box != null) {
      target.text(
        [title],
        box,
        color: _palette.nodeText,
        fontSize: style.fontSize * 1.2,
        weight: FontWeight.w600,
      );
    }
  }

  /// Actor [actor]'s dot at [at].
  void _dot(DiagramTarget target, Offset at, int actor) {
    final series = _palette.series;
    target.polygon(
      DiagramShapes.polygonFor(
        FlowNodeShape.circle,
        Rect.fromCircle(center: at, radius: 5),
      ),
      fill: actor < series.length ? series[actor] : _palette.nodeStroke,
      stroke: _palette.edgeLabelBackground,
    );
  }

  /// A face in [box]: two eyes and a mouth that smiles, frowns or stays
  /// straight by [mood].
  void _face(DiagramTarget target, Rect box, int mood) {
    final centre = box.center;
    final r = box.width / 2;
    target.polygon(
      DiagramShapes.polygonFor(FlowNodeShape.circle, box),
      fill: _palette.subgraphFill,
      stroke: _palette.edge,
      strokeWidth: 1.5,
    );
    for (final side in [-1, 1]) {
      target.polygon(
        DiagramShapes.polygonFor(
          FlowNodeShape.circle,
          Rect.fromCircle(
            center: centre + Offset(side * r * 0.35, -r * 0.25),
            radius: 1.6,
          ),
        ),
        fill: _palette.edge,
      );
    }
    // The mouth: a curve sampled in straight pieces, bowed down for a
    // smile and up for a frown.
    Offset mouth(double t) {
      final across = (t - 0.5) * r;
      final bow = math.cos((t - 0.5) * math.pi) * r * 0.22 * mood;
      return centre + Offset(across, r * 0.32 + bow - mood * r * 0.1);
    }

    for (var i = 0; i < _mouthSteps; i++) {
      target.line(
        mouth(i / _mouthSteps),
        mouth((i + 1) / _mouthSteps),
        color: _palette.edge,
        strokeWidth: 1.5,
      );
    }
  }

  List<Offset> _rounded(Rect rect) => DiagramShapes.polygonFor(
    FlowNodeShape.round,
    rect,
    radius: style.cornerRadius,
  );
}
