import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/fence_band_painter.dart';
import 'package:niman/src/markdown/render/live_hosts.dart';
import 'package:niman/src/markdown/render/live_run.dart';
import 'package:niman/src/markdown/render/live_tables.dart';
import 'package:niman/src/markdown/render/source_folds.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Where the source view's caret goes when the keys move it: by a logical
/// motion, by visual rows, by a page — past what `live` draws as nothing to
/// stop on (a fence's band, a table's room) and across side-by-side columns
/// (#729).
///
/// The view owns it and calls it from its keys; the motions that need the
/// layout ask the view's drawn paragraphs through the narrow callbacks it
/// is handed, and every move lands through [_apply].
final class SourceCaretMotion {
  /// The motions over the view's [_buffer] and [_selection].
  new({
    required this._buffer,
    required this._selection,
    required this._live,
    required this._mounted,
    required this._blockOf,
    required this._fenceOf,
    required this._folds,
    required this._hosts,
    required this._noteBox,
    required this._scroll,
    required this._caretRect,
    required this._caretLine,
    required this._paintedOffsetAt,
    required this._mappedOffsetAt,
    required this._paragraphAt,
    required this._band,
    required this._gap,
    required this._rowHeight,
    required this._verbatimQuotes,
    required this._apply,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// The caret.
  final SelectionModel Function() _selection;

  /// Whether the view draws `live`.
  final bool Function() _live;

  /// Whether the view is still mounted.
  final bool Function() _mounted;

  /// The block holding a line, as the scan behind the colours has it.
  final Block? Function(int line) _blockOf;

  /// What a line, in its block, draws as a fence line in `live`, or null.
  final LiveFence? Function(int line, Block? block) _fenceOf;

  /// The folded sections, and the blocks hosted side by side.
  final SourceFolds _folds;

  /// The blocks drawn side by side at the pane's width.
  final LiveHosts _hosts;

  /// The box the note is drawn in.
  final RenderBox? Function() _noteBox;

  /// The note's scroll.
  final ScrollController Function() _scroll;

  /// The caret's rectangle in global coordinates, or null while it is not
  /// laid out.
  final Rect? Function() _caretRect;

  /// The line the caret sits on, or -1.
  final int Function() _caretLine;

  /// The offset under a global point on a line a frame has drawn, or null.
  final int? Function(Offset global) _paintedOffsetAt;

  /// The offset under a global point as the height map places the lines.
  final int? Function(Offset global) _mappedOffsetAt;

  /// The paragraph of a line, when a frame has built it.
  final RenderParagraph? Function(int line) _paragraphAt;

  /// A fence line's band, as drawn.
  final double Function() _band;

  /// The room between two columns.
  final double Function() _gap;

  /// One row's height as the lines are drawn.
  final double Function() _rowHeight;

  /// The quote marks before a verbatim line's text, null for a line with
  /// syntax of its own (#579).
  final int? Function(int line) _verbatimQuotes;

  /// Makes a selection the view's — scrolled into view with `reveal`.
  final void Function(SelectionModel next, {required bool reveal}) _apply;

  int get _lineCount => _buffer().lineCount;

  /// Moves the caret by [motion], the logical motions the key table calls.
  void moveBy(CaretMotion motion, {bool extend = false}) {
    final selection = _selection();
    var next = moveCaret(
      selection,
      motion,
      buffer: _buffer(),
      extend: extend,
      verbatimQuotes: _verbatimQuotes,
    );
    final into = switch (motion) {
      CaretMotion.characterLeft || CaretMotion.wordLeft => -1,
      CaretMotion.characterRight || CaretMotion.wordRight => 1,
      // Home goes to the row's first cell, End to its last one.
      CaretMotion.lineStart || CaretMotion.lineTextStart => 1,
      CaretMotion.lineEnd => -1,
      CaretMotion.documentStart => 1,
      CaretMotion.documentEnd => -1,
    };
    final line =
        motion == CaretMotion.lineStart ||
        motion == CaretMotion.lineTextStart ||
        motion == CaretMotion.lineEnd;
    var extent = inCell(next.extent, into, keepLine: line);
    // A fence out of the caret's reach is no stop (#729): the caret steps
    // over it, in the direction it travels — Right at a column's last
    // character goes to the next column's first. Home at the start of a
    // column's first line steps onto the column's opener, the keyboard's
    // way to its width.
    if (!line &&
        motion != CaretMotion.documentStart &&
        motion != CaretMotion.documentEnd) {
      extent = _overFences(selection.extent, extent, into);
    } else if (motion == CaretMotion.lineStart ||
        motion == CaretMotion.lineTextStart) {
      extent = _homeOntoOpener(selection.extent, extent);
    }
    if (extent != next.extent) {
      next = extend
          ? SelectionModel(anchor: next.anchor, extent: extent)
          : SelectionModel.at(extent);
    }
    _apply(next, reveal: true);
  }

  /// Whether line [line] is one `live` draws as nothing to stop on (#729):
  /// a fence line's band, or a blank line between two side-by-side
  /// columns, which no column draws.
  bool passedOver(int line) {
    if (!_live() || line < 0 || line >= _lineCount) return false;
    final block = _blockOf(line);
    if (block == null) return false;
    if (_fenceOf(line, block) != null) return true;
    final host = _folds.hostOf(line);
    final layout = host == null ? null : _hosts.openedOn(host);
    return layout != null && layout.run.columnOf(line) < 0;
  }

  /// Where a caret going [direction]-wards from [from] to [to] lands: [to],
  /// unless that is on a line [passedOver] the caret was not on, and then
  /// the first character past the run of such lines that way.
  int _overFences(int from, int to, int direction) {
    if (!_live() || direction == 0) return to;
    final buffer = _buffer();
    final start = buffer.lineOf(from);
    var line = buffer.lineOf(to);
    if (line == start || !passedOver(line)) return to;
    while (passedOver(line) && line != start) {
      final next = line + (direction > 0 ? 1 : -1);
      if (next < 0 || next >= _lineCount) return to;
      line = next;
    }
    return direction > 0
        ? buffer.offsetOfLine(line)
        : buffer.offsetOfLine(line) + buffer.lineLengthAt(line);
  }

  /// Where Home from [from] lands, when [to] is where it would: the end of
  /// a column's opener, revealed, when the caret is already at the start
  /// of the column's first line (#729).
  int _homeOntoOpener(int from, int to) {
    if (!_live()) return to;
    final buffer = _buffer();
    final line = buffer.lineOf(from);
    if (line == 0 || from != buffer.offsetOfLine(line)) return to;
    final above = _blockOf(line - 1);
    if (above?.divRole != DivRole.opensColumn ||
        _fenceOf(line - 1, above) == null) {
      return to;
    }
    return buffer.offsetOfLine(line - 1) + buffer.lineLengthAt(line - 1);
  }

  /// Moves the caret [rows] visual rows up (negative) or down, keeping its
  /// horizontal place.
  ///
  /// This is the motion that needs the *layout* and not the note: a wrapped
  /// paragraph is one source line and many screen rows, and which row a press
  /// of
  /// the down key lands on depends on where every character was drawn. So the
  /// answer comes from the same two questions the caret itself does — where the
  /// caret is (`getOffsetForCaret`) and which offset a point lands on
  /// (`getPositionForOffset`) — asked of the paragraphs that drew the rows,
  /// with
  /// the height map saying which line a y falls in.
  void moveVertically(int rows, {bool extend = false}) {
    final caret = _caretRect();
    if (caret == null || rows == 0) return;
    final buffer = _buffer();
    // The caret's own row is the row height — its line's, at the scale it is
    // drawn at — and the point is the middle of the row [rows] away, so a
    // boundary never decides which row it is.
    var point = Offset(caret.center.dx, caret.center.dy + rows * caret.height);
    final caretLine = _caretLine();
    // At a side-by-side column's edge the motion follows the source: on
    // to the next column, or out of the block (#729).
    final edge = _acrossColumns(caretLine, point, rows, caret);
    if (edge != null) {
      moveTo(edge, extend: extend);
      return;
    }
    var offset = _paintedOffsetAt(point);
    // A fence's band is no row to stop on: the point goes on past it.
    for (
      var step = 0;
      step < 4 &&
          offset != null &&
          buffer.lineOf(offset) != caretLine &&
          passedOver(buffer.lineOf(offset));
      step++
    ) {
      point = point.translate(0, rows.sign * _band());
      offset = _paintedOffsetAt(point);
    }
    if (offset != null) {
      moveTo(offset, extend: extend);
      return;
    }
    // The row is not drawn: move the note under the caret by as much, and ask
    // the line that is there once the frame has built it.
    final scroll = _scroll();
    if (!scroll.hasClients) return;
    final from = scroll.offset;
    final to = (from + rows * caret.height).clamp(
      0.0,
      scroll.position.maxScrollExtent,
    );
    if (to == from) {
      // Nothing further in that direction: the caret goes to the note's end.
      moveBy(
        rows < 0 ? CaretMotion.documentStart : CaretMotion.documentEnd,
        extend: extend,
      );
      return;
    }
    scroll.jumpTo(to);
    final shifted = point - Offset(0, to - from);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_mounted()) return;
      final landed = _paintedOffsetAt(shifted) ?? _mappedOffsetAt(shifted);
      if (landed != null) moveTo(landed, extend: extend);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Where Up or Down — [rows] rows, the point it asks being [point] —
  /// takes a caret on [line], in [caret], when that line is in a
  /// side-by-side column and the point is past the column's own lines: the
  /// next column's first line going down, the previous one's last going
  /// up, at the same distance from the column's left edge; past the last
  /// column the line after the block, past the first the line before it.
  /// Null when the motion stays in the column, or the line is in none.
  int? _acrossColumns(int line, Offset point, int rows, Rect caret) {
    final host = line < 0 ? null : _folds.hostOf(line);
    final layout = host == null ? null : _hosts.openedOn(host);
    final box = _noteBox();
    if (layout == null || box == null) return null;
    final run = layout.run;
    final column = run.columnOf(line);
    if (column < 0) return null;
    final landed = _paintedOffsetAt(point);
    if (landed != null) {
      final at = _buffer().lineOf(landed);
      if (run.columnOf(at) == column && !passedOver(at)) return null;
    } else {
      // Not drawn: past the column's lines only if its first or last
      // line is the caret's.
      final lines = run.columns[column];
      final first = firstOf(lines, forward: true);
      final last = firstOf(lines, forward: false);
      if (rows > 0 ? line != last : line != first) return null;
    }
    final down = rows > 0;
    final next = column + (down ? 1 : -1);
    final int target;
    double? x;
    if (next < 0 || next >= run.columns.length) {
      target = down ? run.end : run.start - 1;
      if (target < 0 || target >= _lineCount) return null;
      x = box.globalToLocal(caret.center).dx;
    } else {
      target = firstOf(run.columns[next], forward: down);
      final gap = _gap();
      final from = LiveHosts.leftOf(layout, column, gap);
      final to = LiveHosts.leftOf(layout, next, gap);
      x = box.globalToLocal(caret.center).dx - from + to;
    }
    return _offsetOnLine(target, x, top: down);
  }

  /// The first line of [column] a caret stops on, going [forward], or its
  /// last going back: past its fences.
  int firstOf(LiveColumn column, {required bool forward}) {
    if (forward) {
      var line = column.start;
      while (line < column.end - 1 && passedOver(line)) {
        line++;
      }
      return line;
    }
    var line = column.end - 1;
    while (line > column.start && passedOver(line)) {
      line--;
    }
    return line;
  }

  /// The offset on [line] at [x], the note box's, on its first visual row
  /// ([top]) or its last; the line's start or end when it is not drawn.
  int _offsetOnLine(int line, double x, {required bool top}) {
    final buffer = _buffer();
    final paragraph = _paragraphAt(line);
    final box = _noteBox();
    if (paragraph == null || !paragraph.attached || box == null) {
      return top
          ? buffer.offsetOfLine(line)
          : buffer.offsetOfLine(line) + buffer.lineLengthAt(line);
    }
    final global = box.localToGlobal(Offset(x, 0));
    final local = paragraph.globalToLocal(global);
    final y = top ? 1.0 : paragraph.size.height - 1;
    return buffer.offsetOfLine(line) +
        paragraph.getPositionForOffset(Offset(local.dx, y)).offset;
  }

  /// Where the caret goes from [offset] in `live`: [offset] itself, unless
  /// it is in a table's room — the pipes and spaces round the cells, or the
  /// delimiter row, which are drawn as nothing — and then the nearest
  /// cell's text [direction]-wards (`LiveTables.cellColumn`): past the
  /// row's end onto the next line going forward, back onto the previous
  /// one going back, unless [keepLine] keeps it on its row.
  int inCell(int offset, int direction, {bool keepLine = false}) {
    if (!_live()) return offset;
    final buffer = _buffer();
    var at = offset;
    while (true) {
      final line = buffer.lineOf(at);
      if (line < 0 || line >= buffer.lineCount) return offset;
      if (_blockOf(line)?.kind != BlockKind.table) return at;
      final start = buffer.offsetOfLine(line);
      final column = LiveTables.cellColumn(
        buffer.lineAt(line),
        at - start,
        direction,
      );
      if (column != null) return start + column;
      if (direction == 0 || keepLine) return at;
      if (direction > 0) {
        if (line + 1 >= buffer.lineCount) return at;
        at = buffer.offsetOfLine(line + 1);
      } else {
        if (line == 0) return at;
        at = buffer.offsetOfLine(line - 1) + buffer.lineLengthAt(line - 1);
      }
    }
  }

  /// Puts the caret at [offset] — extending the selection with [extend] — and
  /// tells everyone who needs to know.
  void moveTo(int offset, {bool extend = false}) {
    final to = inCell(offset, 0);
    _apply(
      extend
          ? SelectionModel(anchor: _selection().anchor, extent: to)
          : SelectionModel.at(to),
      reveal: true,
    );
  }

  /// PageUp and PageDown: the note moves a viewport, and the caret moves with
  /// it by as many rows, the way every editor pages.
  void page(int direction, {bool extend = false}) {
    final scroll = _scroll();
    if (!scroll.hasClients) return;
    final rowHeight = _rowHeight();
    final viewport = scroll.position.viewportDimension;
    final rows = (viewport / rowHeight).floor() - 1;
    if (rows <= 0) return;
    final from = scroll.offset;
    final to = (from + direction * rows * rowHeight).clamp(
      0.0,
      scroll.position.maxScrollExtent,
    );
    if (to == from) {
      // Nothing left to page through: the caret goes to that end of the note.
      moveBy(
        direction < 0 ? CaretMotion.documentStart : CaretMotion.documentEnd,
        extend: extend,
      );
      return;
    }
    // The caret keeps its place *on the screen* while the note moves under
    // it, and that place is asked of whatever line is there after the jump —
    // the caret's own line may no longer be built at all.
    final box = _noteBox();
    final point =
        _caretRect()?.center ??
        box?.localToGlobal(Offset(0, viewport / 2)) ??
        Offset.zero;
    scroll.jumpTo(to);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_mounted()) return;
      final offset = _paintedOffsetAt(point) ?? _mappedOffsetAt(point);
      if (offset == null) return;
      final next = extend
          ? SelectionModel(anchor: _selection().anchor, extent: offset)
          : SelectionModel.at(offset);
      _apply(next, reveal: false);
    });
    WidgetsBinding.instance.scheduleFrame();
  }
}
