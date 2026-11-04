import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/edit/caret_spot.dart';
import 'package:niman/src/markdown/render/live_table_commands.dart';
import 'package:niman/src/markdown/render/live_table_grid_tracker.dart';
import 'package:niman/src/markdown/render/live_table_handles.dart';
import 'package:niman/src/markdown/render/live_tables.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_line.dart';
import 'package:niman/src/markdown/render/source_paragraphs.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/strings.dart';

/// The `+` handles of the table in play in the source view's `live` (#261):
/// the one under the mouse on the desktop, the caret's on a phone — the
/// table it is, its grid on screen, and the handles drawn over it.
///
/// The view owns it, shows its [overlay] and hands it the mouse's hover; it
/// reads the note's layout through the narrow callbacks it is handed.
final class SourceTableHover {
  /// The handles over the view's [_buffer].
  new({
    required this._buffer,
    required this._live,
    required this._mounted,
    required this._blockOf,
    required this._caretSpot,
    required this._noteBox,
    required this._scroll,
    required this._tableRowAt,
    required this._piecesOf,
    required this._lineBox,
    required this._drawnHeightOf,
    required this._theme,
    required this._replace,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// Whether the view draws `live`, where a table is a grid.
  final bool Function() _live;

  /// Whether the view is still mounted.
  final bool Function() _mounted;

  /// The block holding a line, or null while there is no scan.
  final Block? Function(int line) _blockOf;

  /// Where the caret is, as the lines that draw it care.
  final ValueListenable<CaretSpot> _caretSpot;

  /// The box the note is drawn in.
  final RenderBox? Function() _noteBox;

  /// The note's scroll.
  final ScrollController Function() _scroll;

  /// How a line of a table is laid out with the caret at a spot.
  final LiveTableRow? Function(int line, Block block, CaretSpot at) _tableRowAt;

  /// The paragraphs a line is drawn in.
  final List<SourcePiece> Function(int line) _piecesOf;

  /// Where a line is drawn, in the scroll view's coordinates.
  final ({double top, double height}) Function(int line) _lineBox;

  /// How tall a line is drawn.
  final double Function(int line) _drawnHeightOf;

  /// The theme the lines are drawn with.
  final MarkdownTheme Function() _theme;

  /// Writes a text over a range of the note, as the table's commands do.
  final TableReplace _replace;

  /// The handles' overlay, always up: it draws nothing while nothing is in
  /// play.
  final OverlayPortalController overlay = OverlayPortalController();

  /// The first line of the table under the mouse, or null.
  final ValueNotifier<int?> hover = ValueNotifier<int?>(null);

  /// Settles the grid the handles are built on against the frame that drew
  /// the table.
  late final LiveTableGridTracker settled = LiveTableGridTracker(
    drawn: () {
      final block = _tableInPlay;
      return block == null ? null : _drawnTableGrid(block);
    },
  );

  /// Whether the mouse is on one of the handles, off the table itself.
  bool _overTableHandles = false;

  /// Lets the handles go a moment after the mouse left the table: the move
  /// from the table onto a handle leaves the note before it reaches the
  /// handle, and letting go at once took the handle from under it.
  Timer? _tableHoverClear;

  /// Whether this platform's tables show their handles where the caret is,
  /// having no pointer to hover with.
  static bool get _touchTables =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// The table whose handles show: under the mouse, or the caret's on a
  /// phone. Null in `source`, where a table is text.
  Block? get _tableInPlay {
    if (!_live()) return null;
    final hovered = hover.value;
    final line = hovered ?? (_touchTables ? _caretSpot.value.line : null);
    if (line == null || line < 0 || line >= _buffer().lineCount) return null;
    final block = _blockOf(line);
    return block?.kind == BlockKind.table ? block : null;
  }

  /// Follows the mouse over the note: the table it is on, or — while it is
  /// on the handles' side of the table it was on — that one still.
  ///
  /// [offset] is the offset under the pointer, computed once by the hover
  /// handler and shared with the cursor.
  void hoverAt(int? offset, Offset global) {
    if (!_live() || _touchTables) return;
    int? table;
    if (offset != null) {
      final line = _buffer().lineOf(offset);
      final block = _blockOf(line);
      if (block?.kind == BlockKind.table) table = block!.startLine;
    }
    final current = hover.value;
    if (table == null && current != null) {
      final block = _blockOf(current);
      final grid = block == null ? null : _tableGrid(block);
      const reach = LiveTableHandles.thickness + 8;
      if (grid != null &&
          Rect.fromLTRB(
            grid.left,
            grid.top,
            grid.right + reach,
            grid.bottom + reach,
          ).contains(global)) {
        table = current;
      }
    }
    if (table == null) {
      leave();
      return;
    }
    _tableHoverClear?.cancel();
    hover.value = table;
    overlay.show();
  }

  /// The mouse is off the table: its handles go, unless it is on them.
  void leave() {
    if (hover.value == null) return;
    _tableHoverClear?.cancel();
    _tableHoverClear = Timer(const Duration(milliseconds: 200), () {
      if (_mounted() && !_overTableHandles) hover.value = null;
    });
  }

  /// [block]'s grid, globally: from its first row's top to its last row's
  /// foot, as wide as its columns — or null while no row of it is drawn.
  ///
  /// Its height is worked out from the map the note is laid out by
  /// ([_lineBox]) at the scroll offset the note has *now*, not read off the
  /// drawn rows: a scroll notifies before the frame that moves them, and
  /// what a row's paragraph says is the last frame's. [settled] checks it
  /// against the rows once a frame has drawn them.
  ///
  /// Only the left edge is read from a drawn row — a row laid out in fitted
  /// columns stands away from its box's left, which the grid painter draws
  /// from — and a scroll does not move it.
  Rect? _tableGrid(Block block) {
    final note = _noteBox();
    final scroll = _scroll();
    if (note == null || !scroll.hasClients) return null;
    final row = _tableRowAt(block.startLine, block, _caretSpot.value);
    if (row == null) return null;
    double? left;
    for (var line = block.startLine; line < block.endLine; line++) {
      final piece = _piecesOf(line).firstOrNull;
      final render = piece == null
          ? null
          : SourceParagraphs.renderOf(piece.key);
      if (piece == null || render == null) continue;
      left = render.localToGlobal(Offset(-piece.x, 0)).dx;
      break;
    }
    if (left == null) return null;
    final top = _lineBox(block.startLine).top;
    final foot = _lineBox(block.endLine - 1);
    final origin = note.localToGlobal(Offset(0, -scroll.offset));
    return Rect.fromLTRB(
      left,
      origin.dy + top,
      left + row.edges.last,
      origin.dy + foot.top + foot.height,
    );
  }

  /// [block]'s grid as the rows are drawn, globally: each row's own
  /// paragraph says where it stands. That is the last frame's layout, so it
  /// is for checking [_tableGrid] against once a frame has drawn
  /// ([LiveTableGridTracker]), never to build on.
  ///
  /// A row laid out in fitted columns is as tall as its wrapped pieces, and
  /// its pieces stand away from its left edge: the grid reaches its foot,
  /// not the height of its first paragraph.
  Rect? _drawnTableGrid(Block block) {
    final firstLine = block.startLine;
    final lastLine = block.endLine - 1;
    final row = _tableRowAt(firstLine, block, _caretSpot.value);
    if (row == null) return null;
    final firstPiece = _piecesOf(firstLine).firstOrNull;
    final lastPiece = _piecesOf(lastLine).firstOrNull;
    if (firstPiece == null || lastPiece == null) return null;
    final first = SourceParagraphs.renderOf(firstPiece.key);
    final last = SourceParagraphs.renderOf(lastPiece.key);
    if (first == null || last == null) return null;
    final pad = _theme().tableCellPadding;
    final wrapped = row.wrapped.isNotEmpty;
    final top = first.localToGlobal(
      Offset(-firstPiece.x, -(wrapped ? firstPiece.y : pad.top)),
    );
    final bottom = wrapped
        ? last.localToGlobal(Offset(-lastPiece.x, -lastPiece.y)).dy +
              _drawnHeightOf(lastLine) +
              pad.top +
              pad.bottom
        : last.localToGlobal(Offset.zero).dy +
              _drawnHeightOf(lastLine) +
              pad.bottom;
    return Rect.fromLTRB(top.dx, top.dy, top.dx + row.edges.last, bottom);
  }

  /// The handles of the table in play, in the overlay's coordinates.
  Widget buildHandles(BuildContext overlayContext) {
    final block = _tableInPlay;
    final grid = settled.settle(block == null ? null : _tableGrid(block));
    final note = _noteBox();
    final overlayBox = Overlay.of(overlayContext).context.findRenderObject();
    if (block == null ||
        grid == null ||
        note == null ||
        overlayBox is! RenderBox ||
        !overlayBox.hasSize) {
      return const SizedBox.shrink();
    }
    Rect local(Rect rect) => Rect.fromPoints(
      overlayBox.globalToLocal(rect.topLeft),
      overlayBox.globalToLocal(rect.bottomRight),
    );
    final box = note.localToGlobal(Offset.zero) & note.size;
    LiveTableCommands? commands() {
      final buffer = _buffer();
      return LiveTableCommands.at(
        buffer,
        block,
        buffer.offsetOfLine(block.startLine),
        replace: _replace,
      );
    }

    return LiveTableHandles(
      grid: local(grid),
      clip: local(box),
      color: _theme().markerDim,
      addRowLabel: AppStrings.tableAddRow,
      addColumnLabel: AppStrings.tableAddColumn,
      onAddRow: () => commands()?.addRowAtEnd(),
      onAddColumn: () => commands()?.addColumnAtEnd(),
      onHover: (over) {
        _overTableHandles = over;
        if (over) {
          _tableHoverClear?.cancel();
        } else {
          leave();
        }
      },
    );
  }

  /// Stops the timer and lets the notifiers go.
  void dispose() {
    _tableHoverClear?.cancel();
    hover.dispose();
    settled.dispose();
  }
}
