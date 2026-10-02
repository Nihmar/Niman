/// The one drawing of a kanban board (#530): its columns, their titles and
/// their cards, a card's priority a stripe down its left side.
///
/// Like the other renderers it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/kanban_layout.dart';
import 'package:niman/src/diagrams/kanban_model.dart';

/// The stripe of each priority: warm and strong for the urgent, cool and
/// faint for the rest, so the order reads without its words.
Color _stripe(KanbanPriority priority) => switch (priority) {
  KanbanPriority.veryHigh => const Color(0xFFE34948),
  KanbanPriority.high => const Color(0xFFEB6834),
  KanbanPriority.low => const Color(0xFF2A78D6),
  KanbanPriority.veryLow => const Color(0xFF9AA0A6),
};

/// Draws a [KanbanLayout] through a [DiagramTarget].
final class KanbanRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final KanbanLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  /// Paints the columns, then their cards.
  void paint(DiagramTarget target) {
    for (final column in layout.columns) {
      target
        ..polygon(
          _rounded(column.rect),
          fill: _palette.subgraphFill,
          stroke: _palette.subgraphStroke,
        )
        ..text(
          [column.title],
          column.titleBox,
          color: _palette.subgraphTitle,
          fontSize: style.fontSize,
          alignLeft: true,
          weight: FontWeight.w600,
        );
    }
    for (final card in layout.cards) {
      target.polygon(
        _rounded(card.rect),
        fill: _palette.edgeLabelBackground,
        stroke: _palette.nodeStroke,
      );
      final priority = card.card.priority;
      if (priority != null) {
        target.polygon(
          DiagramShapes.polygonFor(
            FlowNodeShape.rect,
            Rect.fromLTWH(card.rect.left, card.rect.top, 4, card.rect.height),
          ),
          fill: _stripe(priority),
        );
      }
      target.text(
        card.lines,
        card.textBox,
        color: _palette.nodeText,
        fontSize: style.fontSize,
        alignLeft: true,
      );
      final meta = card.meta;
      final metaBox = card.metaBox;
      if (meta != null && metaBox != null) {
        target.text(
          [meta],
          metaBox,
          color: _palette.subgraphTitle,
          fontSize: style.fontSize * 0.85,
          alignLeft: true,
        );
      }
    }
  }

  List<Offset> _rounded(Rect rect) => DiagramShapes.polygonFor(
    FlowNodeShape.round,
    rect,
    radius: style.cornerRadius,
  );
}
