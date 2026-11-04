import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/live_table_commands.dart';
import 'package:niman/src/markdown/render/live_tables.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The source view's keys in a table `live` draws (#261): Tab to the next
/// cell, Enter to the one below, Shift+Enter out of the table — and the
/// commands on the table the caret is in, which its menus offer.
///
/// The view owns it and calls it from its keys; it moves the caret and
/// edits the note through the narrow callbacks it is handed.
final class SourceTableKeys {
  /// The table keys over the view's [_buffer] and [_selection].
  new({
    required this._buffer,
    required this._selection,
    required this._live,
    required this._blockOf,
    required this._select,
    required this._replace,
    required this._indent,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// The caret.
  final SelectionModel Function() _selection;

  /// Whether the view draws `live`, where a table is a grid.
  final bool Function() _live;

  /// The block holding a line, as the scan behind the colours has it.
  final Block? Function(int line) _blockOf;

  /// Makes a selection the view's, scrolled into view.
  final void Function(SelectionModel next) _select;

  /// Replaces `[start, end)` with a text, as one undoable edit, the caret
  /// at the one given or after the text.
  final void Function(int start, int end, String text, SelectionModel? caret)
  _replace;

  /// Indents the lines the selection touches, or outdents them: Tab off a
  /// table.
  final void Function({required bool outdent}) _indent;

  /// The table the caret is in and what can be done to it, in `live`; null
  /// anywhere else (#261). A menu reads it as it opens, so it is the
  /// caret's cell now.
  LiveTableCommands? commands() {
    if (!_live()) return null;
    final buffer = _buffer();
    final offset = _selection().extent.clamp(0, buffer.length);
    return LiveTableCommands.at(
      buffer,
      _blockOf(buffer.lineOf(offset)),
      offset,
      replace: (start, end, text, caret) =>
          _replace(start, end, text, SelectionModel.at(caret)),
    );
  }

  /// Tab and Shift+Tab: the next cell or the one before in a table in
  /// `live`, its text selected so what is typed replaces it; past the last
  /// cell a new row, as a spreadsheet goes on. Anywhere else the line's
  /// indent, as before.
  void tab({required bool forward}) {
    final commands = this.commands();
    if (commands == null) {
      _indent(outdent: !forward);
      return;
    }
    final buffer = _buffer();
    final rows = _tableRows(commands.block);
    final cell = commands.cell;
    var row = cell.row;
    var column = cell.column + (forward ? 1 : -1);
    List<(int, int)> cellsOf(int row) =>
        LiveTables.cellsOf(buffer.lineAt(rows[row]));
    if (column >= cellsOf(row).length) {
      row++;
      column = 0;
    } else if (column < 0) {
      row--;
      if (row < 0) return;
      column = cellsOf(row).length - 1;
    }
    if (row >= rows.length) {
      commands.addRowAtEnd();
      return;
    }
    final cells = cellsOf(row);
    if (cells.isEmpty) return;
    final (start, end) = cells[column.clamp(0, cells.length - 1)];
    final lineStart = buffer.offsetOfLine(rows[row]);
    _select(SelectionModel(anchor: lineStart + start, extent: lineStart + end));
  }

  /// The lines of table [block] that are rows: all of them but the
  /// delimiter row.
  static List<int> _tableRows(Block block) => <int>[
    for (var line = block.startLine; line < block.endLine; line++)
      if (line != block.startLine + 1) line,
  ];

  /// Enter in a table in `live`: the caret to the end of the cell below,
  /// in the same column, and from the last row out of the table. Answers
  /// whether the caret was in one. A line break typed into a row split it,
  /// and the table with it.
  bool enter() {
    final commands = this.commands();
    if (commands == null) return false;
    final buffer = _buffer();
    final rows = _tableRows(commands.block);
    final below = commands.cell.row + 1;
    if (below >= rows.length) {
      _caretOutOfTable(commands.block);
      return true;
    }
    final cells = LiveTables.cellsOf(buffer.lineAt(rows[below]));
    if (cells.isEmpty) {
      _caretOutOfTable(commands.block);
      return true;
    }
    final (_, end) = cells[commands.cell.column.clamp(0, cells.length - 1)];
    _select(SelectionModel.at(buffer.offsetOfLine(rows[below]) + end));
    return true;
  }

  /// Shift+Enter or Ctrl+Enter in a table in `live`: out of it, from any
  /// row. Answers whether the caret was in one.
  bool exit() {
    final commands = this.commands();
    if (commands == null) return false;
    _caretOutOfTable(commands.block);
    return true;
  }

  /// Down from a table's last row in `live`, when the note ends with it:
  /// a line to go to, rather than a caret that cannot leave. Answers
  /// whether it was that.
  bool downOut() {
    final commands = this.commands();
    if (commands == null) return false;
    final block = commands.block;
    final rows = _tableRows(block);
    if (commands.cell.row != rows.length - 1) return false;
    if (block.endLine < _buffer().lineCount) return false;
    _caretOutOfTable(block);
    return true;
  }

  /// The caret to the start of the line after table [block] — an empty one
  /// added when the note ends with the table, so there is always one.
  void _caretOutOfTable(Block block) {
    final buffer = _buffer();
    if (block.endLine < buffer.lineCount) {
      _select(SelectionModel.at(buffer.offsetOfLine(block.endLine)));
      return;
    }
    final last = block.endLine - 1;
    final end = buffer.offsetOfLine(last) + buffer.lineLengthAt(last);
    _replace(end, end, '\n', null);
  }
}
