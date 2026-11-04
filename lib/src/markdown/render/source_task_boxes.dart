import 'package:flutter/rendering.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/live_decorations.dart';
import 'package:niman/src/markdown/render/live_quote_content.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_paragraphs.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/task_cascade.dart';

/// The task boxes `live` draws in the source view: which one is under a
/// point, and the tick a click on it makes (#505).
///
/// Only a box that is drawn: on the caret's line the markers are the
/// source, written out, and a click there is a click in the text. The box
/// is where the painter puts it ([liveItemSlot]), asked of the same
/// paragraph, so the two agree by construction.
final class SourceTaskBoxes {
  /// The boxes of the view's [_buffer], drawn in [_paragraphs].
  new({
    required this._buffer,
    required this._live,
    required this._caretLine,
    required this._paragraphs,
    required this._lineAt,
    required this._blockOf,
    required this._blocks,
    required this._quotes,
    required this._theme,
    required this._cascade,
    required this._selection,
    required this._seal,
    required this._replace,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// Whether the view draws `live`, where a task box is drawn.
  final bool Function() _live;

  /// The line the lines are told holds the caret.
  final int Function() _caretLine;

  /// The paragraphs the lines are drawn in.
  final SourceParagraphs _paragraphs;

  /// A line as the view draws it.
  final StyledLine Function(int index) _lineAt;

  /// The block holding a line, as the scan behind the colours has it.
  final Block? Function(int line) _blockOf;

  /// The note's blocks, or null while the scan owes them.
  final List<Block>? Function() _blocks;

  /// A quote's content read again as blocks.
  final LiveQuoteContent _quotes;

  /// The theme the lines are drawn with.
  final MarkdownTheme Function() _theme;

  /// Whether ticking a parent ticks its branch (#326).
  final bool Function() _cascade;

  /// The caret, which a tick leaves where it is.
  final SelectionModel Function() _selection;

  /// Ends the typing step, so a tick is an undo step of its own.
  final void Function() _seal;

  /// Replaces `[start, end)` with a text, the caret at the one given, the view
  /// left where it is.
  final void Function(int start, int end, String text, SelectionModel caret)
  _replace;

  /// The `[ ]` or `[x]` of the task box `live` draws under [global] — its
  /// source range, and whether it is ticked — or null when no box is there.
  ({int line, int start, int end, bool ticked})? at(Offset global) {
    if (!_live()) return null;
    final buffer = _buffer();
    final caretLine = _caretLine();
    for (final index in _paragraphs.lines) {
      if (index == caretLine || index >= buffer.lineCount) continue;
      final hit = _slotAt(index, global);
      if (hit == null) continue;
      for (final token in _lineAt(index).tokens) {
        if (token.kind != TokenKind.taskBox) continue;
        final start = buffer.offsetOfLine(index) + token.start;
        return (
          line: index,
          start: start,
          end: start + token.end - token.start,
          ticked: hit,
        );
      }
    }
    return null;
  }

  /// Whether line [index] draws a task box under [global], and whether it is
  /// ticked — or null when the line draws no box or the point is off it.
  ///
  /// The one place the box's hit region is asked for, so the cursor (#505)
  /// and the click ([at]) can never disagree: both read the same
  /// [liveItemSlot] of the same paragraph.
  bool? _slotAt(int index, Offset global) {
    final paragraph = _paragraphs.paragraphAt(index);
    if (paragraph == null || !paragraph.attached || !paragraph.hasSize) {
      return null;
    }
    final styled = _lineAt(index);
    final block = _blockOf(index);
    final shape = LineShape.of(
      styled,
      block,
      index,
      quoted: _quotes.of(index, block, _buffer()),
    );
    final ticked = shape.task;
    if (shape.marker == null || ticked == null) return null;
    final slot = liveItemSlot(paragraph, shape, _theme());
    return slot.contains(paragraph.globalToLocal(global)) ? ticked : null;
  }

  /// Whether a drawn task box is under [global]. Reads the one line the point
  /// is on, not the note, so a hover costs no scan of the note; the box is
  /// where the painter puts it ([liveItemSlot]), so the cursor and the click
  /// agree. [offset] is the offset under the pointer, from the hover handler.
  bool over(int? offset, Offset global) {
    if (!_live() || offset == null) return false;
    final index = _buffer().lineOf(offset);
    // On the caret's line the markers are drawn as written: a click is a
    // caret, not a tick.
    if (index == _caretLine()) return false;
    return _slotAt(index, global) != null;
  }

  /// Ticks or unticks the task box under [global], and answers whether
  /// there was one: one edit and one undo step, the `x` written or taken out
  /// inside the brackets, the caret and the view left where they were.
  bool toggleAt(Offset global) {
    final box = at(global);
    if (box == null) return false;
    // Ticking a parent takes its branch with it (#326); clearing one does
    // not, and neither does a library that turned the sweep off.
    if (!box.ticked && _cascade()) {
      final blocks = _blocks();
      final edit = blocks == null
          ? null
          : checklistTickEdit(
              buffer: _buffer(),
              blocks: blocks,
              line: box.line,
              ticked: true,
            );
      if (edit != null) {
        _seal();
        _replace(edit.start, edit.end, edit.text, _selection());
        _seal();
        return true;
      }
    }
    _seal();
    _replace(
      box.start + 1,
      box.start + 2,
      box.ticked ? ' ' : 'x',
      _selection(),
    );
    _seal();
    return true;
  }
}
