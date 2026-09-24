/// A table's edits in `live`, from the cell the caret is in (#261).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/editor/context_menu_items.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/render/live_tables.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/table/markdown_table.dart';
import 'package:niman/src/markdown/table/table_edits.dart';
import 'package:niman/src/ui/strings.dart';

/// Writes [text] over `[start, end)` of the note, the caret left at
/// [caret]: one edit, one undo step.
typedef TableReplace = void Function(
  int start,
  int end,
  String text,
  int caret,
);

/// The table a caret is in, the cell it is in, and what can be done to
/// them: each edit reads the table's lines, changes the table, and writes
/// its lines back in one replacement, the caret in the cell the edit
/// leaves it in.
final class LiveTableCommands {
  /// Commands on [table], written as [block]'s lines of [buffer], from
  /// [cell]; [replace] writes an edit.
  const new _({
    required this.buffer,
    required this.block,
    required this.table,
    required this.cell,
    required this.replace,
  });

  /// The commands for the caret at [offset] of [buffer], [block] being its
  /// line's block; null when that is not a table.
  static LiveTableCommands? at(
    SourceBuffer buffer,
    Block? block,
    int offset, {
    required TableReplace replace,
  }) {
    if (block == null || block.kind != BlockKind.table) return null;
    final table = MarkdownTable.parse(_lines(buffer, block));
    if (table == null) return null;
    final line = buffer.lineOf(offset);
    final column = MarkdownTable.columnAt(
      buffer.lineAt(line),
      offset - buffer.offsetOfLine(line),
      table.columns,
    );
    // The header is row 0, the delimiter row is not a row, the body counts
    // on from 1; a caret on the delimiter row is the header's.
    final index = line - block.startLine;
    final row = index < 2 ? 0 : index - 1;
    return LiveTableCommands._(
      buffer: buffer,
      block: block,
      table: table,
      cell: (row: row, column: column),
      replace: replace,
    );
  }

  /// The note.
  final SourceBuffer buffer;

  /// The table's block.
  final Block block;

  /// The table as its lines read.
  final MarkdownTable table;

  /// The cell the caret is in.
  final TableSpot cell;

  /// Writes an edit.
  final TableReplace replace;

  /// Runs [edit] and writes what it made; nothing when it does not apply.
  void run(TableEdit? edit) {
    if (edit == null) return;
    final lines = edit.table.toLines();
    final start = buffer.offsetOfLine(block.startLine);
    final last = block.endLine - 1;
    final end = buffer.offsetOfLine(last) + buffer.lineLengthAt(last);
    final caret = edit.caret;
    final line = caret.row == 0 ? 0 : caret.row + 1;
    var offset = 0;
    for (var at = 0; at < line; at++) {
      offset += lines[at].length + 1;
    }
    final cells = LiveTables.cellsOf(lines[line]);
    if (caret.column < cells.length) offset += cells[caret.column].$2;
    replace(start, end, lines.join('\n'), start + offset);
  }

  /// A new row at the table's foot: the `+` under it.
  void addRowAtEnd() => run(TableEdits.addRowAtEnd(table));

  /// A new column at the table's right edge: the `+` beside it.
  void addColumnAtEnd() => run(TableEdits.addColumnAtEnd(table));

  /// The table's part of the context menu, for [cell]: its row's and its
  /// column's submenus, and the sorts.
  ContextMenuPart menu() {
    ContextMenuAction action(
      String id,
      String label,
      IconData icon,
      TableEdit? edit,
    ) => ContextMenuAction(
      id: 'table-$id',
      label: label,
      icon: icon,
      onPressed: edit == null ? null : () => run(edit),
    );

    final at = cell;
    return [
      [
        ContextMenuGroup(
          id: 'table-row',
          label: AppStrings.tableRow,
          icon: Icons.table_rows_outlined,
          sections: [
            [
              action(
                'row-above',
                AppStrings.tableAddRowAbove,
                Icons.add,
                TableEdits.addRowAbove(table, at),
              ),
              action(
                'row-below',
                AppStrings.tableAddRowBelow,
                Icons.add,
                TableEdits.addRowBelow(table, at),
              ),
            ],
            [
              action(
                'row-up',
                AppStrings.tableMoveRowUp,
                Icons.arrow_upward,
                TableEdits.moveRowUp(table, at),
              ),
              action(
                'row-down',
                AppStrings.tableMoveRowDown,
                Icons.arrow_downward,
                TableEdits.moveRowDown(table, at),
              ),
            ],
            [
              action(
                'row-duplicate',
                AppStrings.tableDuplicateRow,
                Icons.content_copy_outlined,
                TableEdits.duplicateRow(table, at),
              ),
              action(
                'row-delete',
                AppStrings.tableDeleteRow,
                Icons.delete_outline,
                TableEdits.deleteRow(table, at),
              ),
            ],
          ],
        ),
        ContextMenuGroup(
          id: 'table-column',
          label: AppStrings.tableColumn,
          icon: Icons.view_column_outlined,
          sections: [
            [
              action(
                'column-left',
                AppStrings.tableAddColumnLeft,
                Icons.add,
                TableEdits.addColumnLeft(table, at),
              ),
              action(
                'column-right',
                AppStrings.tableAddColumnRight,
                Icons.add,
                TableEdits.addColumnRight(table, at),
              ),
            ],
            [
              action(
                'column-move-left',
                AppStrings.tableMoveColumnLeft,
                Icons.arrow_back,
                TableEdits.moveColumnLeft(table, at),
              ),
              action(
                'column-move-right',
                AppStrings.tableMoveColumnRight,
                Icons.arrow_forward,
                TableEdits.moveColumnRight(table, at),
              ),
            ],
            [
              action(
                'align-left',
                AppStrings.tableAlignLeft,
                Icons.format_align_left,
                TableEdits.alignColumn(table, at, TableAlign.left),
              ),
              action(
                'align-center',
                AppStrings.tableAlignCenter,
                Icons.format_align_center,
                TableEdits.alignColumn(table, at, TableAlign.center),
              ),
              action(
                'align-right',
                AppStrings.tableAlignRight,
                Icons.format_align_right,
                TableEdits.alignColumn(table, at, TableAlign.right),
              ),
            ],
            [
              action(
                'column-duplicate',
                AppStrings.tableDuplicateColumn,
                Icons.content_copy_outlined,
                TableEdits.duplicateColumn(table, at),
              ),
              action(
                'column-delete',
                AppStrings.tableDeleteColumn,
                Icons.delete_outline,
                TableEdits.deleteColumn(table, at),
              ),
            ],
          ],
        ),
        action(
          'sort-ascending',
          AppStrings.tableSortAscending,
          Icons.sort_by_alpha,
          TableEdits.sortByColumn(table, at),
        ),
        action(
          'sort-descending',
          AppStrings.tableSortDescending,
          Icons.sort,
          TableEdits.sortByColumn(table, at, descending: true),
        ),
      ],
    ];
  }

  static List<String> _lines(SourceBuffer buffer, Block block) => [
    for (var line = block.startLine; line < block.endLine; line++)
      buffer.lineAt(line),
  ];
}
