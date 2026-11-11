import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/editor/typewriter_scroll.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/fence_band_painter.dart';
import 'package:niman/src/markdown/render/live_code_colors.dart';
import 'package:niman/src/markdown/render/live_hosts.dart';
import 'package:niman/src/markdown/render/live_quote_content.dart';
import 'package:niman/src/markdown/render/scroll_anchor.dart';
import 'package:niman/src/markdown/render/scrollbar_strip.dart';
import 'package:niman/src/markdown/render/source_caret.dart';
import 'package:niman/src/markdown/render/source_caret_motion.dart';
import 'package:niman/src/markdown/render/source_caret_rect.dart';
import 'package:niman/src/markdown/render/source_caret_reveal.dart';
import 'package:niman/src/markdown/render/source_editor.dart';
import 'package:niman/src/markdown/render/source_geometry.dart';
import 'package:niman/src/markdown/render/source_hit_test.dart';
import 'package:niman/src/markdown/render/source_line_marks.dart';
import 'package:niman/src/markdown/render/source_live_lines.dart';
import 'package:niman/src/markdown/render/source_metrics.dart';
import 'package:niman/src/markdown/render/source_paragraphs.dart';
import 'package:niman/src/markdown/render/source_pieces.dart';
import 'package:niman/src/markdown/render/source_rows.dart';
import 'package:niman/src/preview/math_cache.dart';

/// Where the source editor's note is on screen (#1261): the rows it is
/// drawn in and their heights, the pieces of each line, the caret's
/// rectangle, where a point lands, the scroll, and the caret's motions that
/// read them. The geometry part of [SourceEditor], which reads the text
/// from it.
final class SourceEditorLayout {
  /// The geometry of [editor]'s note, scrolled by [controller] when the
  /// caller owns one.
  new(this.editor, {ScrollController? controller})
    : scroll = controller ?? ScrollController(),
      _ownsScroll = controller == null;

  /// The editor whose note this lays out.
  final SourceEditor editor;

  /// The scroll position: the caller's, or one of its own.
  ScrollController scroll;
  bool _ownsScroll;

  /// The scroll view's key: the box a global point is measured against.
  final GlobalKey scrollKey = GlobalKey();

  /// Takes the caller's scroll position, when it changed.
  void useController(ScrollController? controller) {
    if (_ownsScroll ? controller == null : identical(controller, scroll)) {
      return;
    }
    if (_ownsScroll) scroll.dispose();
    scroll = controller ?? ScrollController();
    _ownsScroll = controller == null;
  }

  /// The rows the note is drawn in and the heights they are placed with:
  /// the lines nobody folded away, a side-by-side block's in its opener's
  /// row (#729).
  late final SourceRows rows = SourceRows(
    buffer: () => editor.buffer,
    live: () => editor.look.hideMarkers,
    styler: () => editor.styler,
    folds: editor.folds,
    hosts: hosts,
    sectionEnd: editor.sections.endOf,
    em: () => metrics.em,
    rowHeight: () => metrics.rowHeight,
    gap: () => metrics.gap,
    band: () => metrics.band,
    columnsPerLine: () => metrics.columnsPerLine,
    itemsIndent: metrics.itemsIndent,
  );

  /// The heights the sliver places the rows with ([SourceRows.heights]).
  BlockHeightMap get heights => rows.heights;

  /// The blocks drawn side by side at the pane's width (#729).
  final LiveHosts hosts = LiveHosts();

  /// The paragraph of each line a frame has built, and of each fragment of
  /// a wrapped table row: what a tap asks where an offset is, and the caret
  /// asks for its rectangle.
  final SourceParagraphs paragraphs = SourceParagraphs();

  /// What the last frame laid the note out with — the pane's width, the
  /// text's scale, the gutter, the text's width — and the lengths counted
  /// from them.
  late final SourceMetrics metrics = SourceMetrics(
    theme: () => editor.look.theme,
    column: () => editor.look.column,
    numberedLines: () =>
        editor.look.showLineNumbers ? editor.buffer.lineCount : null,
  );

  /// The pieces a line is drawn in, and a table's rows as `live` lays them
  /// out: what the caret, a tap and the table's grid ask.
  late final SourcePieces pieces = SourcePieces(
    buffer: () => editor.buffer,
    live: () => editor.look.hideMarkers,
    styler: () => editor.styler,
    caretSpot: () => caret.spot.value,
    paragraphs: paragraphs,
    tokensOf: (line) => editor.lineAt(line).tokens,
    syntax: () => metrics.syntax,
    dark: () => editor.look.dark,
    theme: () => editor.look.theme,
    scaler: () => metrics.scaler,
    widthOf: _widthOf,
  );

  /// Where the lines are drawn, in the scroll view's coordinates, and which
  /// line a point is on, off the height map and the side-by-side layouts.
  late final SourceGeometry geometry = SourceGeometry(
    heights: () => heights,
    folds: editor.folds,
    hosts: hosts,
    padding: () => editor.look.padding,
    band: () => metrics.band,
    gap: () => metrics.gap,
    columnsLeft: metrics.columnsLeft,
  );

  /// Where a point over the note lands in it: asked of the drawn lines,
  /// and of the height map for a point no drawn line is under.
  late final SourceHitTest hits = SourceHitTest(
    buffer: () => editor.buffer,
    hosts: hosts,
    noteBox: () => noteBox,
    scroll: () => scroll,
    heights: () => heights,
    paragraphs: paragraphs,
    pieces: pieces,
    geometry: geometry,
  );

  /// What a line is marked with beyond its colours: the selection, the
  /// composing range, the spelling, the dead links, the find bar's matches.
  late final SourceLineMarks marks = SourceLineMarks(
    buffer: () => editor.buffer,
    selection: () => editor.selection,
    composing: () => editor.input.composing,
    spellCheck: () => editor.services.spellCheck,
    tokensAt: editor.tokensAt,
    deadLinks: () => editor.services.deadLinks,
    linkHrefAt: (index, start) => editor.styler?.linkHrefAt(index, start),
    findMatches: () => editor.services.findMatches,
  );

  /// The caret as the lines and the toolbar are told it: its spot, its
  /// rectangle and its piece's shift, measured off its line's layout.
  late final SourceCaret caret = SourceCaret(
    buffer: () => editor.buffer,
    selection: () => editor.selection,
    mounted: () => editor.mounted,
    fragmentAt: (line, local) => pieces.fragmentAt(line, local),
    width: () => caretWidth,
    caretOnLine: (line) => editor.typing.brackets.caretOnLine(line),
    activeItems: () => editor.services.activeItems,
    tokensOf: editor.tokensOf,
    measured: _sendGeometry,
  );

  /// How wide the caret is drawn.
  double get caretWidth => editor.look.caretWidth ?? 1.5;

  /// The caret kept in view: after an edit or a jump, and when the
  /// keyboard comes up over it (#728).
  late final SourceCaretReveal reveal = SourceCaretReveal(
    scroll: () => scroll,
    mounted: () => editor.mounted,
    caretLine: () => caret.line,
    anchorLine: () => editor.buffer.lineOf(editor.selection.anchor),
    rowOf: editor.folds.rowOf,
    lineBounds: geometry.lineBounds,
    bottomInsetNow: () => View.of(editor.context()).viewInsets.bottom,
    typing: () => editor.controls.focus.hasFocus && editor.input.isAttached,
  );

  /// Where the caret goes when the keys move it: by a logical motion, by
  /// visual rows, by a page.
  late final SourceCaretMotion motion = SourceCaretMotion(
    buffer: () => editor.buffer,
    selection: () => editor.selection,
    live: () => editor.look.hideMarkers,
    mounted: () => editor.mounted,
    blockOf: (line) => editor.styler?.blockOf(line),
    fenceOf: fenceOf,
    folds: editor.folds,
    hosts: hosts,
    noteBox: () => noteBox,
    scroll: () => scroll,
    caretRect: () => caretRect,
    caretLine: () => caret.line,
    paintedOffsetAt: hits.paintedOffsetAt,
    mappedOffsetAt: hits.mappedOffsetAt,
    paragraphAt: paragraphs.paragraphAt,
    band: () => metrics.band,
    gap: () => metrics.gap,
    rowHeight: () => metrics.rowHeight,
    verbatimQuotes: editor.verbatimQuotes,
    apply: editor.applySelection,
  );

  /// Moves the caret by [motion], the logical motions the key table calls.
  void moveCaretBy(CaretMotion motion, {bool extend = false}) =>
      this.motion.moveBy(motion, extend: extend);

  /// Moves the caret [rows] visual rows up (negative) or down, keeping its
  /// horizontal place ([SourceCaretMotion.moveVertically]).
  void moveCaretVertically(int rows, {bool extend = false}) =>
      motion.moveVertically(rows, extend: extend);

  /// A quote's content read again as blocks, so `live` draws a quote's lines
  /// as the blocks they are inside it, as the read view does.
  final LiveQuoteContent quotes = LiveQuoteContent();

  /// The colours of the code blocks `live` draws, highlighted a block at a
  /// time as the read view highlights them.
  final LiveCodeColors codeColors = LiveCodeColors();

  /// What the footnotes `live` ends the note with are parsed with.
  final ReadParser footnoteParser = ReadParser();

  /// The formulas of those footnotes, for a surface given no math cache.
  final MathCache footnoteMath = MathCache();

  /// Ticks on every caret move, so the note's semantics — its text around the
  /// caret, and the selection in it — follow without rebuilding the note.
  final ValueNotifier<int> semanticsTick = ValueNotifier<int>(0);

  /// Typewriter mode's glide to the caret, one per burst of moves.
  late final TypewriterFollow _typewriter = TypewriterFollow(_centerCaret);

  /// Lets go of the caret, the glide and a scroll position of its own.
  void dispose() {
    _typewriter.dispose();
    semanticsTick.dispose();
    caret.dispose();
    footnoteMath.dispose();
    if (_ownsScroll) scroll.dispose();
  }

  /// The box the note is drawn in, which is what a global point is measured
  /// against — not the view's own context, which may be wider (a centred
  /// column).
  RenderBox? get noteBox {
    final object = scrollKey.currentContext?.findRenderObject();
    return object is RenderBox && object.hasSize ? object : null;
  }

  /// The caret's rectangle in the note's own coordinates, or null before the
  /// frame that measured it.
  Rect? get caretRect {
    final rect = caret.rect.value;
    final line = caret.line;
    if (rect == null || line < 0) return null;
    final local = editor.selection.extent - editor.buffer.offsetOfLine(line);
    final (_, paragraph) = pieces.fragmentAt(line, local);
    if (paragraph == null || !paragraph.attached) return null;
    return rect.shift(paragraph.localToGlobal(Offset.zero));
  }

  /// The caret rectangle at [offset] in global coordinates, from the piece of
  /// its line the offset is drawn in — or null when that line is not built.
  ///
  /// A wrapped table row is drawn as one paragraph per piece, so the rectangle
  /// is measured in that piece's own coordinates and shifted by where it
  /// stands of the line's box, as [caretRect] is.
  Rect? caretRectAt(int offset) {
    final buffer = editor.buffer;
    final line = buffer.lineOf(offset.clamp(0, buffer.length));
    final lineStart = buffer.offsetOfLine(line);
    final (piece, paragraph) = pieces.fragmentAt(line, offset - lineStart);
    if (piece == null || paragraph == null) return null;
    return sourcePieceCaretRect(piece, paragraph, offset - lineStart);
  }

  /// The rectangle a problem's span covers, in global coordinates, or null
  /// while the piece that holds it is not built.
  ///
  /// As [caretRect], the span is measured in the piece it is drawn in and
  /// shifted by where that piece stands of the line's box — the piece its own
  /// text ends in, since a piece a wrap broke after a space ends on that
  /// space, and the span after it begins where the next piece does.
  Rect? templateSpanRect(int start, int end) {
    final buffer = editor.buffer;
    final line = buffer.lineOf(start);
    final lineStart = buffer.offsetOfLine(line);
    final lineEnd = lineStart + buffer.lineLengthAt(line);
    final last = (end > start ? end - 1 : start).clamp(lineStart, lineEnd);
    final (piece, paragraph) = pieces.fragmentAt(line, last - lineStart);
    if (piece == null || paragraph == null) return null;
    return sourcePieceSpanRect(
      piece,
      paragraph,
      start - lineStart,
      end.clamp(lineStart, lineEnd) - lineStart,
    );
  }

  /// The offset a tap at [global] lands on, or null when it lands outside a
  /// line.
  int? offsetAt(Offset global) => hits.offsetAt(global);

  /// Whether [global], a position in the window, is on the scrollbar's track
  /// (#1106): a mouse there belongs to the scrollbar, not to the text. Asked
  /// of the bar itself ([pointerOnScrollbar]), so there is no strip when the
  /// platform builds no bar or the note has nothing to scroll.
  bool onScrollbar(Offset global) => pointerOnScrollbar(
    scrollView: scrollKey.currentContext?.findRenderObject(),
    metrics: scroll.hasClients ? scroll.position : null,
    global: global,
  );

  /// Scrolls so [line] is at the top, as far as the map knows.
  void jumpToLine(int line) {
    if (line < 0 || line >= editor.buffer.lineCount || !scroll.hasClients) {
      return;
    }
    rows.reshape(() => editor.folds.reveal(line));
    scroll.jumpTo(
      (geometry.lineBox(line).top - editor.look.padding.top).clamp(
        0.0,
        scroll.position.maxScrollExtent,
      ),
    );
    scheduleCaret();
  }

  /// How far the note is scrolled, for a memento.
  double get scrollOffset => scroll.hasClients ? scroll.offset : 0;

  /// Scrolls to [offset], as far as the note reaches.
  void jumpToOffset(double offset) {
    if (!scroll.hasClients) return;
    scroll.jumpTo(offset.clamp(0.0, scroll.position.maxScrollExtent));
    scheduleCaret();
  }

  /// The source line at the top of the view, and how far into its rows
  /// ([ScrollAnchor]). Null while there is nothing drawn to ask.
  ScrollAnchor? get topAnchor {
    if (!scroll.hasClients || heights.length == 0) return null;
    final y = scroll.offset - editor.look.padding.top;
    if (y <= 0) return (line: 0, fraction: 0.0);
    final line = geometry.lineAtY(scroll.offset);
    final box = geometry.lineBox(line);
    final into = box.height > 0 ? (scroll.offset - box.top) / box.height : 0.0;
    return (line: line, fraction: into.clamp(0.0, 1.0));
  }

  /// Whether the view has the note drawn to show an anchor in ([showAnchor]):
  /// it is laid out and holds lines.
  bool get acceptsAnchor => scroll.hasClients && editor.buffer.lineCount > 0;

  /// Scrolls the view so [anchor]'s line is at its top, as far into it as
  /// the anchor says; the caret stays where it is. The rows it lands among
  /// may be estimates — a switch of mode draws every row anew — so it looks
  /// again after each frame that measured them, as long as that moves it.
  void showAnchor(ScrollAnchor anchor, {int attempt = 0}) {
    final lineCount = editor.buffer.lineCount;
    if (!scroll.hasClients || lineCount == 0) return;
    final box = geometry.lineBox(anchor.line.clamp(0, lineCount - 1));
    final atTop = anchor.line == 0 && anchor.fraction == 0;
    final offset = atTop
        ? 0.0
        : (box.top + anchor.fraction * box.height).clamp(
            0.0,
            scroll.position.maxScrollExtent,
          );
    if ((scroll.position.pixels - offset).abs() > 0.5) {
      scroll.jumpTo(offset);
    } else if (attempt > 0) {
      return;
    }
    if (attempt >= 12) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (editor.mounted) showAnchor(anchor, attempt: attempt + 1);
    });
  }

  /// The note's offsets the platform's input window may reach around a
  /// caret at [caret]: a side-by-side column's lines past its fences, when
  /// the caret is in one (#729); the whole note otherwise.
  (int, int) inputReach(int caret) {
    final buffer = editor.buffer;
    final whole = (0, buffer.length);
    if (hosts.layouts.isEmpty) return whole;
    final line = buffer.lineOf(caret.clamp(0, buffer.length));
    final host = editor.folds.hostOf(line);
    final layout = host == null ? null : hosts.openedOn(host);
    if (layout == null) return whole;
    final column = layout.run.columnOf(line);
    if (column < 0 || motion.passedOver(line)) return whole;
    final lines = layout.run.columns[column];
    final first = motion.firstOf(lines, forward: true);
    final last = motion.firstOf(lines, forward: false);
    return (
      buffer.offsetOfLine(first),
      buffer.offsetOfLine(last) + buffer.lineLengthAt(last),
    );
  }

  /// The width line [line] is drawn at: its side-by-side column's, or the
  /// text's.
  double _widthOf(int line) {
    final placed = geometry.columnOfLine(line);
    if (placed == null) return metrics.textWidth;
    return placed.layout.widths[placed.column];
  }

  /// What line [index], in [block], draws as a fence line in `live`, or
  /// null ([liveFenceOf]).
  LiveFence? fenceOf(int index, Block? block) => editor.look.hideMarkers
      ? liveFenceOf(
          index,
          block,
          editor.buffer,
          runs: () => rows.liveRuns,
          isHost: editor.folds.isHost,
        )
      : null;

  /// Measures the caret after the frame that laid its line out.
  void scheduleCaret() {
    semanticsTick.value++;
    // The caret moved: the hint follows it off the problems as they stand.
    editor.controls.hints.refresh();
    editor.revealCaret();
    editor.controls.blink.restart();
    followCaret();
    // Measured *now*, from the layout the last frame left, and again after the
    // next frame: a caret that moved because of a tap or a key is on screen
    // immediately, and the frame that may have re-laid its line corrects it.
    // Waiting only for the post-frame callback makes the caret a frame late,
    // which is how a cursor feels slow when it is doing nothing slow.
    caret.measure();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (editor.mounted) caret.measure();
    });
  }

  /// Measures the caret again once the next frame has laid its line out:
  /// the caret stayed where it was while its line was laid out anew, in
  /// another mode or at another width.
  void measureCaretAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (editor.mounted) caret.measure();
    });
  }

  /// The caret moved, or the text under it did: typewriter mode brings its
  /// row to the middle. Only while someone is writing here — the note or its
  /// find bar has the focus — so a note loading, or its place being put back,
  /// stays where it was put.
  void followCaret() {
    if (!editor.behaviour.typewriter) return;
    final finding = editor.services.findMatches?.visible ?? false;
    if (!editor.controls.focus.hasFocus && !finding) return;
    _typewriter.caretMoved();
  }

  /// Glides the note so the caret's row is in the middle of the pane; false
  /// while that row is not laid out yet, so the follow asks again next frame.
  bool _centerCaret() {
    final caret = caretRect;
    final box = noteBox;
    if (caret == null || box == null || !scroll.hasClients) return false;
    centerCaret(scroll, box.globalToLocal(caret.center).dy);
    return true;
  }

  /// Tells the IME where the note is and where the caret is in it, so its
  /// candidate window (and a phone's handles) sit by the text rather than at
  /// the window's corner.
  void _sendGeometry() {
    final input = editor.input;
    if (!input.isAttached) return;
    final box = noteBox;
    final caret = caretRect;
    if (box == null || caret == null) return;
    input.setGeometry(
      box.size,
      box.getTransformTo(null),
      box.globalToLocal(caret.topLeft) & caret.size,
    );
  }
}
