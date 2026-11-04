import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/fence_body.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/code_copy.dart';
import 'package:niman/src/markdown/render/live_hosts.dart';
import 'package:niman/src/markdown/render/source_folds.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_styler.dart';

/// The copy buttons of the fenced code blocks on screen in the source view's
/// `live` (#541): each at the top right of its block's part in view, so a
/// block taller than the pane has its button wherever it is scrolled to. A
/// diagram's fence has none: it is drawn as the diagram.
///
/// The view owns it and builds [build] in its [overlay], which rides its
/// scroll; it reads the note's layout through the narrow callbacks it is
/// handed.
final class SourceCodeCopies {
  /// The copy buttons over the view's [_buffer].
  new({
    required this._buffer,
    required this._live,
    required this._drawsTodo,
    required this._styler,
    required this._noteBox,
    required this._scroll,
    required this._heights,
    required this._folds,
    required this._padding,
    required this._lineBox,
    required this._columnOfLine,
    required this._rightInset,
    required this._columnsLeft,
    required this._gap,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// Whether the view draws `live`.
  final bool Function() _live;

  /// Whether a `todo` fence is drawn as its list here.
  final bool Function() _drawsTodo;

  /// The colours, whose blocks say where the fences are.
  final SourceStyler? Function() _styler;

  /// The box the note is drawn in.
  final RenderBox? Function() _noteBox;

  /// The note's scroll.
  final ScrollController Function() _scroll;

  /// The heights the rows are placed with.
  final BlockHeightMap Function() _heights;

  /// The folded sections, and the rows they leave.
  final SourceFolds _folds;

  /// The note's padding.
  final EdgeInsets Function() _padding;

  /// Where a line is drawn, in the scroll view's coordinates.
  final ({double top, double height}) Function(int line) _lineBox;

  /// The side-by-side block and column a line is drawn in, or null.
  final ({LiveLayout layout, int column})? Function(int line) _columnOfLine;

  /// The field's inset on the right.
  final double Function() _rightInset;

  /// The note box's x where a side-by-side block's columns start.
  final double Function(LiveLayout layout) _columnsLeft;

  /// The room between two columns.
  final double Function() _gap;

  /// The buttons' overlay (#541).
  final OverlayPortalController overlay = OverlayPortalController();

  /// Shows or hides the code blocks' copy buttons with the pane: they are
  /// overlay children, so an off stage pane must take them away itself.
  void sync({required bool onStage}) {
    if (onStage) {
      overlay.show();
    } else {
      overlay.hide();
    }
  }

  /// The buttons, in [overlayContext]'s overlay.
  Widget build(BuildContext overlayContext) {
    const nothing = SizedBox.shrink();
    // A `todo` fence is drawn as its list, like a diagram, where the tasks are
    // at hand: no code to copy.
    final drawsTodo = _drawsTodo();
    final styler = _styler();
    final note = _noteBox();
    final scroll = _scroll();
    final heights = _heights();
    final padding = _padding();
    final buffer = _buffer();
    final overlayBox = Overlay.of(overlayContext).context.findRenderObject();
    if (!_live() ||
        styler == null ||
        note == null ||
        overlayBox is! RenderBox ||
        !overlayBox.hasSize ||
        !scroll.hasClients ||
        heights.length == 0) {
      return nothing;
    }
    // The pane's top and bottom, in the rows' coordinates.
    final top = scroll.offset - padding.top;
    final bottom = top + note.size.height;
    final row = heights.indexAt(math.max(0, top));
    if (row == null) return nothing;
    final buttons = <Widget>[];
    for (var line = _folds.lineOf(row); line < buffer.lineCount;) {
      final block = styler.blockOf(line);
      if (block == null) {
        line++;
        continue;
      }
      // A block of a side-by-side column is placed by its column (#729):
      // the columns' blocks are not in the order they stand, so one below
      // the pane ends nothing.
      final placed = _columnOfLine(block.startLine);
      final start = _lineBox(block.startLine).top - padding.top;
      if (start >= bottom) {
        if (placed == null) break;
        line = math.max(block.endLine, line + 1);
        continue;
      }
      final info = block.fenceInfo?.toLowerCase();
      if (block.kind == BlockKind.fencedCode &&
          info != 'mermaid' &&
          !(info == 'todo' && drawsTodo)) {
        final lastBox = _lineBox(block.endLine - 1);
        final end = lastBox.top + lastBox.height - padding.top;
        final y =
            math.min(
              math.max(start, top),
              end - codeCopySize - 2 * codeCopyMargin,
            ) +
            codeCopyMargin;
        if (y >= start && y - top + codeCopySize <= note.size.height) {
          final at = overlayBox.globalToLocal(
            note.localToGlobal(
              Offset(
                (placed == null
                        ? note.size.width - _rightInset()
                        : _columnsLeft(placed.layout) +
                              LiveHosts.leftOf(
                                placed.layout,
                                placed.column,
                                _gap(),
                              ) +
                              placed.layout.widths[placed.column]) -
                    codeCopySize -
                    codeCopyMargin,
                y - top,
              ),
            ),
          );
          buttons.add(
            Positioned(
              left: at.dx,
              top: at.dy,
              child: CodeCopyButton(
                key: ValueKey<int>(block.startLine),
                code: () =>
                    fenceBody(
                      BlockParser.blockText(block, _buffer()).split('\n'),
                    )?.code ??
                    '',
              ),
            ),
          );
        }
      }
      line = math.max(block.endLine, line + 1);
    }
    return Stack(children: buttons);
  }
}
