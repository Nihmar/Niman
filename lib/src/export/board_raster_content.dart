/// What a rastered kanban board is made of (#1170): its rows of columns,
/// each column's head and the widgets of what it holds, then the footnotes.
///
/// The rows follow the printed page (`kanban_style.dart`, `KanbanSheet`):
/// every column in one row on a landscape sheet, sharing the width, and
/// [kanbanPortraitColumns] to a row on a portrait one, each as wide as a
/// grid cell. The text before the first column, and any prose between a
/// column's cards, keeps its place as the printed page keeps it; Obsidian's
/// settings footer is not drawn. The footnotes the note cites, numbered over
/// the whole note, are one more row after the board, in the read view's own
/// list.
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/export/board_raster_card.dart';
import 'package:niman/src/export/board_raster_context.dart';
import 'package:niman/src/export/board_raster_head.dart';
import 'package:niman/src/export/kanban_sheet.dart';
import 'package:niman/src/kanban/kanban_board.dart';
import 'package:niman/src/kanban/kanban_column.dart';
import 'package:niman/src/markdown/render/footnote_list.dart';

/// A millimetre in logical pixels (96 to the inch).
const double pxPerMm = 96 / 25.4;

/// One column of a row, or the prose that comes before the first.
final class BoardRasterLane {
  /// A lane [width] wide: [framed] in a box of its own with [head] on top,
  /// or bare, as the prose before the board is.
  const new({
    required this.width,
    required this.framed,
    required this.items,
    required this.line,
    this.head,
  });

  /// The lane's outer width.
  final double width;

  /// Whether the lane is a column's box.
  final bool framed;

  /// The colour of the box's line.
  final Color line;

  /// The column's head, laid out [innerWidth] wide; null for bare prose.
  final Widget? head;

  /// A card or a piece of prose each, [innerWidth] wide, with the space
  /// under it.
  final List<Widget> items;

  /// The width inside the box.
  double get innerWidth =>
      framed ? width - boardLanePadding.horizontal - 2 : width;

  /// The lane with items [from] to [to] of its own, under its head when
  /// [withHead].
  Widget slice(int from, int to, {required bool withHead}) {
    final shown = <Widget>[
      if (withHead && head != null) head!,
      ...items.sublist(from, to),
    ];
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: shown,
    );
    return SizedBox(
      width: width,
      child: framed ? BoardLaneBox(color: line, child: column) : column,
    );
  }
}

/// The rows of a board, top to bottom, ready to be measured and paged.
final class BoardRasterContent {
  /// The content of [board] for a [contentWidth]-wide page printed on
  /// [sheet], drawn with [context].
  factory({
    required KanbanBoard board,
    required KanbanSheet sheet,
    required double contentWidth,
    required BoardRasterContext context,
  }) {
    final columns = board.columns;
    final theme = context.theme;
    const gap = kanbanGapMm * pxPerMm;
    final perRow = sheet == KanbanSheet.landscape
        ? columns.length
        : kanbanPortraitColumns;
    final laneWidth = (contentWidth - (perRow - 1) * gap) / perRow;
    final innerWidth = laneWidth - boardLanePadding.horizontal - 2;
    final headStyle = boardHeadStyle(context, [
      for (final column in columns) column.name,
    ], innerWidth);
    final bands = <List<BoardRasterLane>>[];

    List<String> linesOf(int from, int to) => [
      for (var i = from; i < to; i++)
        if (board.lines[i].endsWith('\r'))
          board.lines[i].substring(0, board.lines[i].length - 1)
        else
          board.lines[i],
    ];

    /// The prose of lines [from] to [to] as an item, or null when there is
    /// none worth drawing: blank, or only definitions.
    Widget? prose(int from, int to, double width) {
      final lines = linesOf(from, to);
      if (onlyDefinitions(lines)) return null;
      return Padding(
        padding: const EdgeInsets.only(bottom: boardCardGap),
        child: context.blocks(lines.join('\n'), width),
      );
    }

    // The text before the first column, the frontmatter off.
    final lead = prose(
      board.frontmatterEnd,
      columns.first.headingLine,
      contentWidth,
    );
    if (lead != null) {
      bands.add([
        BoardRasterLane(
          width: contentWidth,
          framed: false,
          line: theme.tableBorder,
          items: [lead],
        ),
      ]);
    }

    BoardRasterLane lane(KanbanColumn column) {
      final items = <Widget>[];
      var at = column.headingLine + 1;
      for (final card in column.cards) {
        if (prose(at, card.line, innerWidth) case final piece?) {
          items.add(piece);
        }
        items.add(
          BoardRasterCard(card: card, width: innerWidth, context: context),
        );
        at = card.end;
      }
      if (prose(at, column.endLine, innerWidth) case final piece?) {
        items.add(piece);
      }
      return BoardRasterLane(
        width: laneWidth,
        framed: true,
        line: theme.tableBorder,
        head: BoardLaneHead(
          name: column.name,
          count: column.cards.length,
          width: innerWidth,
          style: headStyle,
          context: context,
        ),
        items: items,
      );
    }

    for (var from = 0; from < columns.length; from += perRow) {
      final to = from + perRow < columns.length
          ? from + perRow
          : columns.length;
      bands.add([for (final column in columns.sublist(from, to)) lane(column)]);
    }

    // The footnotes the note cites, once, after the board: a rule, then a
    // row each, as the read view ends a note.
    final notes = context.scope.footnotes;
    if (notes.isNotEmpty) {
      bands.add([
        BoardRasterLane(
          width: contentWidth,
          framed: false,
          line: theme.tableBorder,
          items: [
            Padding(
              padding: EdgeInsets.only(top: theme.blockSpacing),
              child: SizedBox(
                width: contentWidth,
                height: theme.ruleThickness,
                child: ColoredBox(color: theme.rule),
              ),
            ),
            for (var at = 0; at < notes.length; at++)
              SizedBox(
                width: contentWidth,
                child: FootnoteRow(
                  footnote: notes[at],
                  number: at + 1,
                  theme: theme,
                  parser: context.parser,
                  mathCache: context.mathCache,
                  scope: context.scope,
                ),
              ),
          ],
        ),
      ]);
    }
    return BoardRasterContent._(bands, gap);
  }

  const new _(this.bands, this.gap);

  /// The rows: the prose before the board, then the columns, a few to a row
  /// on a portrait sheet and all of them on a landscape one, then the
  /// footnotes.
  final List<List<BoardRasterLane>> bands;

  /// The space between two rows, and between two columns of a row.
  final double gap;
}
