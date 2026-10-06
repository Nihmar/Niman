/// The one drawing of a Gantt chart (#530): the sections' bands, the grid,
/// the tasks' bars and milestones, the axis and the title.
///
/// Like the other renderers it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/gantt_geometry.dart';
import 'package:niman/src/diagrams/gantt_model.dart';

/// The fill of a task by its state, on a light surface and a dark one.
typedef _Fills = ({Color done, Color active, Color critical});

const _Fills _light = (
  done: Color(0xFFD3D3D3),
  active: Color(0xFFBFC7FF),
  critical: Color(0xFFFF9C9C),
);

const _Fills _dark = (
  done: Color(0xFF55585F),
  active: Color(0xFF4A4E7A),
  critical: Color(0xFF8C3A3A),
);

/// The outline of a critical task, whatever its fill.
const Color _criticalStroke = Color(0xFFE34948);

/// Draws a [GanttLayout] through a [DiagramTarget].
final class GanttRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final GanttLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  _Fills get _fills =>
      _palette.edgeLabelBackground.computeLuminance() > 0.5 ? _light : _dark;

  /// Paints the bands and the grid behind, then the bars, the axis and the
  /// title.
  void paint(DiagramTarget target) {
    final plot = layout.plot;
    for (final band in layout.bands) {
      if (band.shaded) {
        target.polygon(_corners(band.rect), fill: _palette.subgraphFill);
      }
      target.text(
        [band.name],
        band.nameBox,
        color: _palette.nodeText,
        fontSize: style.fontSize,
        alignLeft: true,
        weight: FontWeight.w600,
      );
    }
    for (final tick in layout.ticks) {
      target.line(
        Offset(tick.x, plot.top),
        Offset(tick.x, plot.bottom),
        color: _palette.subgraphStroke,
        dashed: true,
      );
    }
    for (final bar in layout.bars) {
      _bar(target, bar);
    }
    target.line(
      plot.bottomLeft,
      plot.bottomRight,
      color: _palette.edge,
      strokeWidth: 1.5,
    );
    for (final tick in layout.ticks) {
      target
        ..line(
          Offset(tick.x, plot.bottom),
          Offset(tick.x, plot.bottom + 4),
          color: _palette.edge,
        )
        ..text(
          [tick.label],
          tick.labelBox,
          color: _palette.nodeText,
          fontSize: style.fontSize,
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

  void _bar(DiagramTarget target, LaidOutBar bar) {
    final task = bar.task;
    final stroke = task.critical ? _criticalStroke : _palette.nodeStroke;
    if (task.milestone) {
      target.polygon(
        DiagramShapes.polygonFor(FlowNodeShape.diamond, bar.rect),
        fill: task.critical ? _criticalStroke : _palette.nodeStroke,
      );
    } else {
      target.polygon(
        DiagramShapes.polygonFor(FlowNodeShape.round, bar.rect, radius: 3),
        fill: _fill(task),
        stroke: stroke,
        strokeWidth: 1.5,
      );
    }
    target.text(
      [task.label],
      bar.labelBox,
      color: _palette.nodeText,
      fontSize: style.fontSize,
      alignLeft: !bar.labelInside,
    );
  }

  Color _fill(GanttTask task) {
    if (task.critical) return _fills.critical;
    if (task.done) return _fills.done;
    if (task.active) return _fills.active;
    return _palette.nodeFill;
  }

  static List<Offset> _corners(Rect rect) => [
    rect.topLeft,
    rect.topRight,
    rect.bottomRight,
    rect.bottomLeft,
  ];
}
