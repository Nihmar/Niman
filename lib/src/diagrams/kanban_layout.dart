/// Laying a kanban board out (#530): its columns side by side, each its
/// title over its cards, a card's text wrapped to the column and its
/// ticket and assignee on a line under it.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/kanban_model.dart';
import 'package:niman/src/diagrams/sequence_text.dart';

const double _margin = 12;
const double _column = 200;
const double _gap = 14;
const double _pad = 8;

/// One column placed: its box, and its title's.
typedef KanbanColumnBox = ({Rect rect, Rect titleBox, String title});

/// One card placed: its box, its text wrapped, and its ticket and assignee
/// on a line under the text, when it has either.
typedef KanbanCardBox = ({
  KanbanCard card,
  Rect rect,
  Rect textBox,
  List<String> lines,
  Rect? metaBox,
  String? meta,
});

/// A kanban board with every part placed.
typedef KanbanLayout = ({
  Size size,
  List<KanbanColumnBox> columns,
  List<KanbanCardBox> cards,
});

/// Lays [board] out with [style].
KanbanLayout layoutKanban(KanbanBoard board, DiagramStyle style) {
  final fontSize = style.fontSize;
  final line = fontSize * style.lineHeight;
  const inner = _column - 2 * _pad;
  final columns = <KanbanColumnBox>[];
  final cards = <KanbanCardBox>[];
  var x = _margin;
  var bottom = _margin;
  for (final column in board.columns) {
    final titleBox = Rect.fromLTWH(x + _pad, _margin + _pad, inner, line);
    var y = titleBox.bottom + _pad;
    for (final card in column.cards) {
      final lines = wrapLabel(card.text, inner - 2 * _pad, fontSize);
      final meta = [?card.ticket, ?card.assigned].join(' · ');
      final height =
          lines.length * line + (meta.isEmpty ? 0 : line + 2) + 2 * _pad;
      final rect = Rect.fromLTWH(x + _pad, y, inner, height);
      final textBox = Rect.fromLTWH(
        rect.left + _pad + 2,
        rect.top + _pad,
        inner - 2 * _pad - 2,
        lines.length * line,
      );
      cards.add((
        card: card,
        rect: rect,
        textBox: textBox,
        lines: lines,
        metaBox: meta.isEmpty
            ? null
            : Rect.fromLTWH(
                textBox.left,
                textBox.bottom + 2,
                textBox.width,
                line,
              ),
        meta: meta.isEmpty ? null : meta,
      ));
      y = rect.bottom + _pad;
    }
    columns.add((
      rect: Rect.fromLTRB(x, _margin, x + _column, y),
      titleBox: titleBox,
      title: column.title,
    ));
    bottom = math.max(bottom, y);
    x += _column + _gap;
  }
  return (
    size: Size(x - _gap + _margin, bottom + _margin),
    columns: List.unmodifiable(columns),
    cards: List.unmodifiable(cards),
  );
}
