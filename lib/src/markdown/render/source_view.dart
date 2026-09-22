/// The source mode of the unified surface: the note's own text, styled by the
/// engine's tokenizer, editable (#245, phase 3).
///
/// This is the **degenerate case** of the surface and the reason the phase
/// starts here: the rendered text *is* the source text, so a selection offset
/// is
/// a source offset, and no render map can hide an editing bug. `live` mode then
/// adds the marker hiding on top of this.
///
/// Three decisions worth naming:
///
/// * **A source line is the unit of layout**, drawn by one `Text.rich` of the
///   tokenizer's runs, wrapping like prose (`re_editor` wrapped, and a note's
///   paragraphs are one long line each — a source view that did not wrap would
///   need horizontal scrolling to read a sentence).
/// * **The caret comes from this surface's own layout**, never from a metric
///   computed beside it: the line that holds the caret hands out its
///   `RenderParagraph` and the rectangle is `getOffsetForCaret`, which is the
///   quantity `EditableText` computes for you and a surface that paints its own
///   text has to compute itself (phase 3's own exit criterion, and the reason a
///   previous attempt at this surface went). A tap lands through the same
/// paragraph's `getPositionForOffset`, so the rectangle and the hit test agree
///   by construction.
/// * **The windowing is the read view's**: the same `SliverMarkdownBlocks` and
///   the same height map. A note is a note whether it is being read or written.
library;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/editor/highlight_style.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/edit_history.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/edit/source_input.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/markdown_blocks_sliver.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/theme/tokens.dart';

/// The colour a selected run is painted with.
const Color _selectionColor = Color(0x553B82F6);

/// The gap between the line numbers and the text.
///
/// A decision rather than leftover space: the numbers are right-aligned against
/// it,
/// so it is what keeps the text from touching them.
/// The gap between the numbers and the text: the room the legacy gutter kept
/// for
/// the fold arrows, which is why the old editor's text never touched its
/// numbers.
const double _gutterGap = 14;

/// The source surface: the note's text, its caret, and where a tap lands.
final class MarkdownSourceView extends StatefulWidget {
  /// Shows [buffer] with [selection], styled with [theme].
  const new({
    required this.buffer,
    required this.theme,
    this.selection,
    this.onSelection,
    this.onChanged,
    this.focusNode,
    this.controller,
    this.history,
    this.column = NoteColumn.off,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.showLineNumbers = true,
    this.hideMarkers = false,
    this.syntax,
    this.dark = false,
    super.key,
  });

  /// The text on screen.
  final SourceBuffer buffer;

  /// The typography: the read view's theme, in monospace.
  final MarkdownTheme theme;

  /// Where the caret is, and what it has selected.
  final SelectionModel? selection;

  /// Called when a tap, or the platform, moves the caret — and when an edit
  /// moves it for them.
  final ValueChanged<SelectionModel>? onSelection;

  /// Called after every edit with the note's text, so the shell can save it —
  /// and with nothing else: the debounce, the memento, the statistics and the
  /// preview all belong to whoever owns the note.
  final ValueChanged<String>? onChanged;

  /// The keyboard focus, when the caller owns it (the shell does).
  final FocusNode? focusNode;

  /// The scroll position, when the caller owns one (an anchor jump does).
  final ScrollController? controller;

  /// Where the note's text sits across the pane.
  ///
  /// The shell's note column, the same object the read mode and the legacy
  /// editor
  /// use, so switching panes does not move the text sideways — and it is the
  /// *text* that moves, not the pane: the side space is padding inside the
  /// scroll
  /// view, which keeps one coordinate system for the caret and the hit test.
  final NoteColumn column;

  /// The undo history, when the caller owns one (the shell keeps it per note,
  /// so
  /// moving a note between tabs does not lose it). Null keeps one here.
  final EditHistory? history;

  /// The page margins.
  final EdgeInsets padding;

  /// Whether the gutter shows line numbers.
  final bool showLineNumbers;

  /// Whether the structural markers are hidden.
  ///
  /// Hidden **by style**, never removed: the runs stay in the layout with their
  /// advance, so an offset in the text is an offset on the screen and the
  /// caret,
  /// the hit test and the selection need to know nothing about what is
  /// invisible.
  /// That is the whole reason `live` mode (phase 4) can be this surface with a
  /// flag rather than a second renderer — the marker's width is paid for, and
  /// what it buys is that every offset stays true.
  final bool hideMarkers;

  /// The token palette; null takes it from the ambient theme.
  final SyntaxColors? syntax;

  /// Whether bold is drawn a step lighter (the palette's own rule).
  final bool dark;

  @override
  State<MarkdownSourceView> createState() => MarkdownSourceViewState();
}

/// The source view's state, so a caller can ask where the caret is.
final class MarkdownSourceViewState extends State<MarkdownSourceView> {
  /// The tokenizer, kept across rebuilds: an edit re-tokenizes from the edit
  /// point on and nothing else (the 0.507 ms incremental-edit number the phase
  /// has to meet is this object's).
  late HighlightDocument _tokens;

  /// The heights the sliver places lines with.
  late BlockHeightMap _heights;

  /// The keyboard, wired to the buffer this view draws.
  late SourceInput _input;

  late ScrollController _scroll;
  bool _ownsScroll = false;
  late FocusNode _focus;
  bool _ownsFocus = false;

  /// The edits that made the note what it is, and the way back.
  late EditHistory _history;

  /// Whether there is anything to undo, for a toolbar that shows it.
  bool get canUndo => _history.canUndo;

  /// Whether there is anything to redo.
  bool get canRedo => _history.canRedo;

  /// Where the caret is when the caller does not hold one — an uncontrolled
  /// view, which is what a test and a quick screen both are.
  SelectionModel _ownSelection = const SelectionModel.at(0);

  /// The caret, from the caller when it holds one.
  SelectionModel get _selection => widget.selection ?? _ownSelection;

  /// The paragraph of each line a frame has built, so a tap can ask the line it
  /// landed on where an offset is, and the caret can ask its own line for the
  /// rectangle. Only mounted lines keep a key: a long scroll forgets the lines
  /// it left, which is what keeps this from growing with the note.
  final Map<int, GlobalKey> _lineKeys = <int, GlobalKey>{};

  /// The caret rectangle in the caret line's coordinates, recomputed after the
  /// frame that laid that line out. A notifier rather than `setState`: neither
  /// the blink nor the measurement may rebuild the note.
  final ValueNotifier<Rect?> _caretRect = ValueNotifier<Rect?>(null);

  /// Whether the caret is drawn (it blinks).
  final ValueNotifier<bool> _caretOn = ValueNotifier<bool>(true);
  Timer? _blink;

  @override
  void initState() {
    super.initState();
    _tokens = HighlightDocument.fromText(widget.buffer.text);
    _scroll = widget.controller ?? ScrollController();
    _ownsScroll = widget.controller == null;
    _focus = widget.focusNode ?? FocusNode();
    _ownsFocus = widget.focusNode == null;
    _heights = _map();
    _history = widget.history ?? EditHistory();
    _input = SourceInput(
      buffer: widget.buffer,
      onRecord: _history.record,
      onTokenizer: (edit, buffer) =>
          SourceInput.retokenize(_tokens, edit, buffer),
      text: () => _wholeText,
      selection: () => _selection,
      onSelection: (next) {
        setState(() => _ownSelection = next);
        widget.onSelection?.call(next);
        _scheduleCaret();
      },
      onEdited: (_) {
        setState(() {
          _heights = _map();
          _ownSelection = _ownSelection.clampTo(widget.buffer.length);
        });
        _scheduleCaret();
        _ensureCaretVisible();
        _notifyChanged();
      },
    );
    _blink = Timer.periodic(const Duration(milliseconds: 550), (_) {
      _caretOn.value = !_caretOn.value;
    });
    _scheduleCaret();
  }

  @override
  void didUpdateWidget(MarkdownSourceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buffer.revision != widget.buffer.revision) {
      // An edit this view did not make (a command, a revert): the tokenizer is
      // rebuilt rather than adjusted, because there is no `SourceEdit` to
      // follow.
      _tokens = HighlightDocument.fromText(widget.buffer.text);
      _heights = _map();
    }
    if (oldWidget.selection != widget.selection) _scheduleCaret();
    if (oldWidget.controller != widget.controller) {
      if (_ownsScroll) _scroll.dispose();
      _scroll = widget.controller ?? ScrollController();
      _ownsScroll = widget.controller == null;
    }
  }

  @override
  void dispose() {
    _input.detach();
    if (_ownsFocus) _focus.dispose();
    _blink?.cancel();
    _caretRect.dispose();
    _caretOn.dispose();
    if (_ownsScroll) _scroll.dispose();
    super.dispose();
  }

  /// How many source lines the note has.
  int get lineCount => _tokens.lineCount;

  /// The keyboard focus, for a shell that wants to raise the keyboard.
  FocusNode get focusNode => _focus;

  /// Whether the platform is attached to this surface (the keyboard is up).
  bool get isKeyboardAttached => _input.isAttached;

  /// How many updates arrived as deltas, and how many of those arrived with an
  /// `oldText` that disagreed with the buffer.
  int get deltaCount => _input.deltaCount;

  /// The count of deltas that had to be recovered onto the platform's text.
  int get recoveredDeltas => _input.recoveredDeltas;

  /// The box the note is drawn in, which is what a global point is measured
  /// against — not the state's own context, which may be wider (a centred
  /// column).
  RenderBox? get _noteBox {
    final object = _scrollKey.currentContext?.findRenderObject();
    return object is RenderBox && object.hasSize ? object : null;
  }

  final GlobalKey _scrollKey = GlobalKey();

  /// The caret's rectangle in the note's own coordinates, or null before the
  /// frame that measured it.
  Rect? get caretRect {
    final rect = _caretRect.value;
    final line = _paragraphAt(_caretLineIndex);
    if (rect == null || line == null || !line.attached) return null;
    return rect.shift(line.localToGlobal(Offset.zero));
  }

  /// The offset a tap at [global] lands on, or null when it lands outside a
  /// line.
  int? offsetAt(Offset global) {
    final box = _noteBox;
    if (box == null) return null;
    final local =
        box.globalToLocal(global) -
        widget.padding.topLeft -
        Offset(_sideSpace, 0);
    final line = _heights.indexAt(local.dy + _scroll.offset);
    if (line == null) return null;
    final paragraph = _paragraphAt(line);
    if (paragraph == null) return null;
    final lineTop = _heights.offsetOf(line) - _scroll.offset;
    // The paragraph's own coordinates start *after* the gutter, and the tap is
    // in
    // the view's: without this the caret lands as many characters right of the
    // finger as the gutter is wide.
    final position = paragraph.getPositionForOffset(
      Offset(local.dx - _gutterWidth, local.dy - lineTop),
    );
    return widget.buffer.offsetOfLine(line) + position.offset;
  }

  /// Scrolls so [line] is at the top, as far as the map knows.
  void jumpToLine(int line) {
    if (line < 0 || line >= _tokens.lineCount || !_scroll.hasClients) return;
    _scroll.jumpTo(
      _heights.offsetOf(line).clamp(0.0, _scroll.position.maxScrollExtent),
    );
    _scheduleCaret();
  }

  /// Undoes the last edit, and says whether there was one.
  bool undo() => _applyHistory(_history.undo(widget.buffer), forwards: false);

  /// Redoes the last undone edit, and says whether there was one.
  bool redo() => _applyHistory(_history.redo(widget.buffer), forwards: true);

  /// Rebuilds what an undo or a redo changed, the same way a platform edit
  /// does.
  bool _applyHistory(EditRecord? record, {required bool forwards}) {
    if (record == null) return false;
    // The whole tokenizer and the map are rebuilt rather than patched: an undo
    // can be a page away from the last edit, and `SourceEdit` describes a
    // change
    // the history record no longer has.
    _tokens = HighlightDocument.fromText(widget.buffer.text);
    final caret = forwards ? record.end : record.start;
    setState(() {
      _heights = _map();
      _ownSelection = _selection
          .collapsedTo(caret)
          .clampTo(widget.buffer.length);
    });
    widget.onSelection?.call(_ownSelection);
    _input.sendSelection();
    _scheduleCaret();
    _ensureCaretVisible();
    _notifyChanged();
    return true;
  }

  /// Moves the caret by [motion], the logical motions the key table calls.
  void moveCaretBy(CaretMotion motion, {bool extend = false}) {
    final next = moveCaret(
      _selection,
      motion,
      buffer: widget.buffer,
      extend: extend,
    );
    setState(() => _ownSelection = next);
    widget.onSelection?.call(next);
    _input.sendSelection();
    _scheduleCaret();
    _ensureCaretVisible();
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
  void moveCaretVertically(int rows, {bool extend = false}) {
    final line = _caretLineIndex;
    final paragraph = _paragraphAt(line);
    if (paragraph == null) return;
    final offsetInLine = (_selection.extent - widget.buffer.offsetOfLine(line))
        .clamp(0, paragraph.text.toPlainText().length);
    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: offsetInLine),
      const Rect.fromLTWH(0, 0, 1.5, 0),
    );
    // Half a row down, so a point on the boundary belongs to the row below it
    // rather than to whichever side the map's floor happens to fall.
    final y =
        _heights.offsetOf(line) +
        caret.dy +
        rows * widget.theme.lineHeight +
        widget.theme.lineHeight / 2;
    final targetLine = _heights.indexAt(y);
    final target = targetLine == null ? null : _paragraphAt(targetLine);
    if (targetLine == null || target == null) return;
    final position = target.getPositionForOffset(
      Offset(caret.dx, y - _heights.offsetOf(targetLine)),
    );
    final next = SelectionModel(
      anchor: extend
          ? _selection.anchor
          : widget.buffer.offsetOfLine(targetLine) + position.offset,
      extent: widget.buffer.offsetOfLine(targetLine) + position.offset,
    );
    setState(() => _ownSelection = next);
    widget.onSelection?.call(next);
    _input.sendSelection();
    _scheduleCaret();
    _ensureCaretVisible();
  }

  /// The selected text, or null when the selection is a caret.
  String? get selectedText {
    final selection = _selection;
    if (selection.isCollapsed) return null;
    return widget.buffer.substring(selection.start, selection.end);
  }

  /// Copies the selection to the platform's clipboard.
  Future<void> copySelection() async {
    final text = selectedText;
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Copies the selection and removes it, in one undo step with the removal.
  Future<void> cutSelection() async {
    final text = selectedText;
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    final selection = _selection;
    _replaceRange(
      selection.start,
      selection.end,
      '',
      SelectionModel.at(selection.start),
    );
  }

  /// Inserts the clipboard's text at the caret, replacing the selection.
  Future<void> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    final selection = _selection;
    _replaceRange(
      selection.start,
      selection.end,
      text,
      SelectionModel.at(selection.start + text.length),
    );
  }

  /// Replaces `[start, end)` with [text] because the *app* asked, not the
  /// platform: the history records it, the tokenizer follows it, and the
  /// platform
  /// is told where the caret went.
  void _replaceRange(int start, int end, String text, SelectionModel caret) {
    if (start < 0 || end < start || end > widget.buffer.length) return;
    _history.record(
      EditRecord(
        start: start,
        removed: widget.buffer.substring(start, end),
        inserted: text,
      ),
    );
    final edit = widget.buffer.replaceRange(start, end, text);
    SourceInput.retokenize(_tokens, edit, widget.buffer);
    final next = caret.clampTo(widget.buffer.length);
    setState(() {
      _heights = _map();
      _ownSelection = next;
    });
    widget.onSelection?.call(next);
    _input.sendSelection();
    _scheduleCaret();
    _ensureCaretVisible();
  }

  /// The note's whole text, as of the revision it was joined at.
  ///
  /// The platform is told a `TextEditingValue`, which means the text — and
  /// joining
  /// a 931 KB note to move a caret is the difference between a cursor that
  /// follows
  /// the finger and one that lags behind it. One join per *edit*, none per
  /// move.
  String get _wholeText {
    if (_textCache == null || _textRevision != widget.buffer.revision) {
      _textCache = widget.buffer.text;
      _textRevision = widget.buffer.revision;
    }
    return _textCache!;
  }

  String? _textCache;
  int _textRevision = -1;

  /// The note changed, so the shell can save it.
  void _notifyChanged() => widget.onChanged?.call(widget.buffer.text);

  /// How many taps have landed inside [_clickWindow], and when the last did.
  int _clicks = 0;
  DateTime? _lastClick;

  /// How long two taps may be apart and still be one gesture.
  static const Duration _clickWindow = Duration(milliseconds: 400);

  /// A tap: one places the caret, two take the word under it, three take the
  /// line.
  ///
  /// Counted here rather than with `onDoubleTap`, because a triple click is a
  /// *third* tap and not a second double one, and because the count has to
  /// survive
  /// the caret moving between taps — which is exactly what happens.
  void _tapUp(Offset position) {
    final offset = offsetAt(position);
    if (offset == null) return;
    final now = DateTime.now();
    final last = _lastClick;
    _clicks = last != null && now.difference(last) <= _clickWindow
        ? _clicks + 1
        : 1;
    _lastClick = now;
    switch (_clicks) {
      case 1:
        placeCaret(offset);
      case 2:
        final (start, end) = wordRangeAt(widget.buffer.text, offset);
        _select(start, end);
      default:
        final line = widget.buffer.lineOf(offset);
        _select(
          widget.buffer.offsetOfLine(line),
          widget.buffer.offsetOfLine(line) + widget.buffer.lineAt(line).length,
        );
        _clicks = 0;
    }
  }

  void _select(int start, int end) {
    final next = SelectionModel(anchor: start, extent: end);
    setState(() => _ownSelection = next);
    widget.onSelection?.call(next);
    _input.sendSelection();
    _scheduleCaret();
  }

  /// Inserts a line break at the caret.
  ///
  /// The *keyboard's* Enter, not the platform's action: an IME that commits a
  /// newline sends it as text, and doing both is how a note grows two lines for
  /// one press (`SourceInput.performAction` no longer inserts for that reason).
  void _newline() {
    final selection = _selection;
    _replaceRange(
      selection.start,
      selection.end,
      widget.buffer.eol,
      SelectionModel.at(selection.start + widget.buffer.eol.length),
    );
  }

  /// Selects everything.
  void selectAll() {
    final next = SelectionModel(anchor: 0, extent: widget.buffer.length);
    setState(() => _ownSelection = next);
    widget.onSelection?.call(next);
    _input.sendSelection();
    _scheduleCaret();
  }

  /// The offset a mouse drag started from, or null when no drag is running.
  int? _dragAnchor;

  /// [child] with mouse dragging selecting text.
  ///
  /// Mouse only, deliberately: on a phone a vertical drag on the text *scrolls*
  /// the note, and stealing that gesture to select would break the way people
  /// read. Selection by touch belongs to the platform's own handles, which is a
  /// separate piece of work.
  Widget _mouseSelection(Widget child) => Listener(
    onPointerDown: (event) {
      // Any pointer, not only a mouse: this is also where the keyboard is asked
      // for, and a finger has to be able to ask.
      _focus.requestFocus();
      if (event.kind != PointerDeviceKind.mouse) return;
      if (event.buttons != kPrimaryMouseButton) return;
      final offset = offsetAt(event.position);
      if (offset == null) return;
      _dragAnchor = offset;
      placeCaret(offset);
    },
    onPointerMove: (event) {
      final anchor = _dragAnchor;
      if (anchor == null) return;
      if (event.kind != PointerDeviceKind.mouse) return;
      final offset = offsetAt(event.position);
      if (offset == null) return;
      final next = SelectionModel(anchor: anchor, extent: offset);
      setState(() => _ownSelection = next);
      widget.onSelection?.call(next);
      _input.sendSelection();
      _scheduleCaret();
    },
    onPointerUp: (_) => _dragAnchor = null,
    onPointerCancel: (_) => _dragAnchor = null,
    child: child,
  );

  /// Puts the caret at [offset], tells the platform, and keeps it on screen.
  void placeCaret(int offset) {
    final next = _selection.collapsedTo(offset).clampTo(widget.buffer.length);
    setState(() => _ownSelection = next);
    widget.onSelection?.call(next);
    _input.sendSelection();
    _scheduleCaret();
    _ensureCaretVisible();
  }

  /// Scrolls the caret's line into view when an edit or a jump left it out.
  void _ensureCaretVisible() {
    if (!_scroll.hasClients) return;
    final line = _caretLineIndex;
    if (line < 0) return;
    final top = _heights.offsetOf(line);
    final bottom = top + _heights.extentFor(line);
    final viewport = _scroll.position.viewportDimension;
    if (top < _scroll.offset) {
      _scroll.jumpTo(top);
    } else if (bottom > _scroll.offset + viewport) {
      _scroll.jumpTo(
        (bottom - viewport).clamp(0.0, _scroll.position.maxScrollExtent),
      );
    }
  }

  /// The part of the selection that falls inside line [index], as offsets local
  /// to that line, or null when none of it does.
  ///
  /// The selection is painted as a *background on the runs it covers* rather
  /// than
  /// as rectangles over them: the runs already know how to wrap, and a
  /// rectangle
  /// would have to be recomputed from the layout on every frame that moved
  /// anything.
  (int, int)? _selectionIn(int index) {
    final selection = _selection;
    if (selection.isCollapsed) return null;
    final start = widget.buffer.offsetOfLine(index);
    final end = start + widget.buffer.lineAt(index).length;
    final from = selection.start < start ? start : selection.start;
    final to = selection.end > end ? end : selection.end;
    if (from >= to) return null;
    return (from - start, to - start);
  }

  /// The paragraph of line [line], when a frame has built it.
  RenderParagraph? _paragraphAt(int line) {
    final object = _lineKeys[line]?.currentContext?.findRenderObject();
    return object is RenderParagraph ? object : null;
  }

  /// The key of line `index`'s paragraph, created on first use.
  GlobalKey _keyFor(int index) {
    final key = _lineKeys.putIfAbsent(index, GlobalKey.new);
    if (_lineKeys.length > 512) {
      _lineKeys.removeWhere((_, key) => key.currentContext == null);
    }
    return key;
  }

  /// The line the caret sits on, or -1.
  int get _caretLineIndex {
    final line = widget.buffer.lineOf(_selection.extent);
    return line < 0 || line >= _tokens.lineCount ? -1 : line;
  }

  BlockHeightMap _map() =>
      BlockHeightMap(count: _tokens.lineCount, estimate: _estimate);

  /// The gutter's width: the widest number the note has, plus a gap.
  ///
  /// Computed rather than fixed, because a fixed one is either too wide for a
  /// three-digit note or too narrow for a ten-thousand-line one — and because
  /// the
  /// gap between the numbers and the text is a decision, not leftover space.
  double get _gutterWidth {
    if (!widget.showLineNumbers) return 0;
    // The legacy editor's own numbers: the editor's text style, same size and
    // same
    // (monospace) face, dimmed when the field is not focused — so the width is
    // the
    // digits' advance in that face, which is 0.6 em each.
    final digits = _tokens.lineCount.toString().length;
    final size = widget.theme.body.fontSize ?? 14;
    return digits * size * 0.6 + _gutterGap;
  }

  /// A line's height before a frame has drawn it: its character count over the
  /// width a line holds, which is the same shape the read view's estimator has
  /// and is corrected by the sliver's own measurement.
  double _estimate(int index) {
    // The *buffer*, never the tokenizer: `HighlightDocument.lineAt`
    // materializes
    // the line, so asking it for every line of a 10 000-line note to fill the
    // height map is a whole-note tokenize on every keystroke. The buffer's line
    // is
    // O(1) and its length is all an estimate needs.
    final text = widget.buffer.lineAt(index);
    final columns = _columnsPerLine;
    final visual = text.isEmpty ? 1 : (text.length / columns).ceil();
    return visual * widget.theme.lineHeight;
  }

  /// Roughly how many monospace characters fit a line at this width and size.
  ///
  /// The pane's real width is not known here (the estimator is asked before a
  /// frame), so this is deliberately a *shape* and not a measurement: the
  /// sliver
  /// replaces every estimate with the line's own height as soon as it draws it,
  /// and only a jump made before that first frame can see the difference.
  double get _columnsPerLine {
    final size = widget.theme.body.fontSize ?? 14;
    final advance = size * 0.6;
    if (advance <= 0) return 1;
    // The pane's real width once a frame has measured it; before that a guess,
    // which the sliver replaces with measured heights as it draws each line.
    final width = _paneWidth ?? 360;
    return (width - _gutterWidth) / advance;
  }

  /// The width the text has, from the last frame that laid it out.
  double? _paneWidth;

  /// The space the note column puts on each side of the text.
  double _sideSpace = 0;

  /// Measures the caret after the frame that laid its line out.
  void _scheduleCaret() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final line = _caretLineIndex;
      final paragraph = _paragraphAt(line);
      if (paragraph == null || line < 0) {
        _caretRect.value = null;
        return;
      }
      final local = _selection.extent - widget.buffer.offsetOfLine(line);
      final length = paragraph.text.toPlainText().length;
      final position = TextPosition(offset: local.clamp(0, length));
      // The caret is the *surface's* answer, not a metric computed beside it:
      // the painter reports the offset the way it paints it, over the run it is
      // really over. The prototype's width matters only on the RTL side and its
      // height not at all (the phase-1 spike), so the height comes from the
      // line.
      final rect = paragraph.getOffsetForCaret(
        position,
        const Rect.fromLTWH(0, 0, 1.5, 0),
      );
      _caretRect.value = Rect.fromLTWH(
        rect.dx,
        rect.dy,
        1.5,
        paragraph.getFullHeightForCaret(position),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final syntax = widget.syntax ?? SyntaxColors.of(context);
    final caretLine = _caretLineIndex;
    // The shortcuts wrap the focus, not the other way round: a
    // `CallbackShortcuts`
    // only sees a key that travels through it on the way to the focused node,
    // so
    // one *below* the `Focus` it belongs to never fires.
    final note = _shortcuts(
      Focus(
        focusNode: _focus,
        onFocusChange: (hasFocus) =>
            hasFocus ? _input.attach() : _input.detach(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _paneWidth = constraints.maxWidth;
            _sideSpace = widget.column.sideSpaceIn(constraints.maxWidth);
            final available =
                constraints.maxWidth -
                widget.padding.horizontal -
                2 * _sideSpace;
            return _mouseSelection(
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Focus on the *pointer going down*, not on a tap being
                // recognized: the scroll view competes for the same gesture,
                // and a
                // tap that the scroll wins is a keyboard that never appears.
                onTapDown: (details) => _focus.requestFocus(),
                onTapUp: (details) => _tapUp(details.globalPosition),
                child: CustomScrollView(
                  key: _scrollKey,
                  controller: _scroll,
                  slivers: <Widget>[
                    SliverPadding(
                      padding: widget.padding.copyWith(
                        left: widget.padding.left + _sideSpace,
                        right: widget.padding.right + _sideSpace,
                      ),
                      sliver: SliverMarkdownBlocks(
                        heights: _heights,
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _Line(
                            key: ValueKey<int>(index),
                            paragraphKey: _keyFor(index),
                            styled: _tokens.lineAt(index),
                            number: widget.showLineNumbers ? index + 1 : null,
                            gutterWidth: _gutterWidth,
                            theme: widget.theme,
                            syntax: syntax,
                            dark: widget.dark,
                            hideMarkers: widget.hideMarkers,
                            selected: _selectionIn(index),
                            width: available,
                            caret: index == caretLine ? _caretRect : null,
                            caretOn: _caretOn,
                          );
                        }, childCount: _tokens.lineCount),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    return note;
  }

  /// The keys the surface answers itself.
  ///
  /// The *logical* motions and undo/redo, which are this surface's own
  /// business.
  /// What the shell binds — the remappable command table, the toolbar, find —
  /// is
  /// dispatched to it by the shell, not captured here, so a user's rebinding
  /// wins.
  Widget _shortcuts(Widget child) => CallbackShortcuts(
    bindings: <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
          moveCaretVertically(-1),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
          moveCaretVertically(1),
      const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): () =>
          moveCaretVertically(-1, extend: true),
      const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): () =>
          moveCaretVertically(1, extend: true),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
          moveCaretBy(CaretMotion.characterLeft),
      const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
          moveCaretBy(CaretMotion.characterRight),
      const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () =>
          moveCaretBy(CaretMotion.characterLeft, extend: true),
      const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () =>
          moveCaretBy(CaretMotion.characterRight, extend: true),
      const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): () =>
          moveCaretBy(CaretMotion.wordLeft),
      const SingleActivator(LogicalKeyboardKey.arrowRight, control: true): () =>
          moveCaretBy(CaretMotion.wordRight),
      const SingleActivator(
        LogicalKeyboardKey.arrowLeft,
        control: true,
        shift: true,
      ): () =>
          moveCaretBy(CaretMotion.wordLeft, extend: true),
      const SingleActivator(
        LogicalKeyboardKey.arrowRight,
        control: true,
        shift: true,
      ): () =>
          moveCaretBy(CaretMotion.wordRight, extend: true),
      const SingleActivator(LogicalKeyboardKey.home): () =>
          moveCaretBy(CaretMotion.lineTextStart),
      const SingleActivator(LogicalKeyboardKey.end): () =>
          moveCaretBy(CaretMotion.lineEnd),
      const SingleActivator(LogicalKeyboardKey.home, control: true): () =>
          moveCaretBy(CaretMotion.documentStart),
      const SingleActivator(LogicalKeyboardKey.end, control: true): () =>
          moveCaretBy(CaretMotion.documentEnd),
      const SingleActivator(LogicalKeyboardKey.keyC, control: true):
          copySelection,
      const SingleActivator(LogicalKeyboardKey.keyC, meta: true): copySelection,
      const SingleActivator(LogicalKeyboardKey.keyX, control: true):
          cutSelection,
      const SingleActivator(LogicalKeyboardKey.keyX, meta: true): cutSelection,
      const SingleActivator(LogicalKeyboardKey.keyV, control: true): paste,
      const SingleActivator(LogicalKeyboardKey.keyV, meta: true): paste,
      const SingleActivator(LogicalKeyboardKey.keyA, control: true): selectAll,
      const SingleActivator(LogicalKeyboardKey.keyA, meta: true): selectAll,
      const SingleActivator(LogicalKeyboardKey.enter): _newline,
      const SingleActivator(LogicalKeyboardKey.numpadEnter): _newline,
      const SingleActivator(LogicalKeyboardKey.keyZ, control: true): undo,
      const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): undo,
      const SingleActivator(
        LogicalKeyboardKey.keyZ,
        control: true,
        shift: true,
      ): redo,
      const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
          redo,
      const SingleActivator(LogicalKeyboardKey.keyY, control: true): redo,
    },
    child: child,
  );
}

/// One source line: its gutter number, its styled runs, and its caret.
final class _Line extends StatelessWidget {
  const new({
    required this.paragraphKey,
    required this.styled,
    required this.number,
    required this.gutterWidth,
    required this.theme,
    required this.syntax,
    required this.dark,
    required this.hideMarkers,
    required this.selected,
    required this.width,
    required this.caret,
    required this.caretOn,
    super.key,
  });

  /// The key of the line's own paragraph, so the surface can ask it for a caret
  /// offset or a caret rectangle.
  final GlobalKey paragraphKey;

  final StyledLine styled;
  final int? number;

  /// How wide the gutter is, computed from the numbers the note has.
  final double gutterWidth;

  final MarkdownTheme theme;
  final SyntaxColors syntax;
  final bool dark;

  /// Whether the structural markers are drawn invisibly.
  final bool hideMarkers;

  /// The selected range, as offsets local to this line, or null.
  final (int, int)? selected;

  /// The width the line's text wraps at (the pane minus the gutter).
  final double width;

  /// The caret rectangle, for the line that holds the caret.
  final ValueNotifier<Rect?>? caret;
  final ValueNotifier<bool> caretOn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (number != null)
            SizedBox(
              width: gutterWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: _gutterGap),
                child: Text(
                  '$number',
                  textAlign: TextAlign.right,
                  // The text's own face and size, dimmed: what the legacy
                  // editor's
                  // `DefaultCodeLineNumber` does, so the numbers line up with
                  // the
                  // characters they count instead of drifting from them.
                  style: theme.body.copyWith(color: theme.markerDim),
                ),
              ),
            ),
          Expanded(
            child: _caretBox(
              Padding(
                padding: EdgeInsets.only(left: _indent()),
                child: Text.rich(
                  _span(),
                  key: paragraphKey,
                  style: _lineStyle(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// [child] with the caret painted over it.
  ///
  /// A `foregroundPainter` rather than a `Stack`: a sliver lays its children
  /// out
  /// with unbounded main-axis constraints — that is what makes it measure them
  /// —
  /// and a `Stack` needs a bound it cannot have here. The painter draws on top
  /// of
  /// the text it belongs to, which is also what a caret is.
  Widget _caretBox(Widget child) {
    final rect = caret;
    if (rect == null) return child;
    return ValueListenableBuilder<Rect?>(
      valueListenable: rect,
      builder: (context, value, child) => ValueListenableBuilder<bool>(
        valueListenable: caretOn,
        builder: (context, on, child) => CustomPaint(
          foregroundPainter: on && value != null ? _CaretPainter(value) : null,
          child: child,
        ),
        child: child,
      ),
      child: child,
    );
  }

  /// The style the line is set in.
  ///
  /// In live mode a heading is drawn at its own size, which is the difference
  /// between hiding a hash and *being* a heading; a source view shows the note
  /// as
  /// written and keeps one size for everything, so the markers keep their own
  /// advance there.
  TextStyle _lineStyle() {
    if (!hideMarkers) return theme.body;
    final text = styled.text;
    var level = 0;
    while (level < text.length && level < 6 && text[level] == '#') {
      level++;
    }
    if (level == 0 || (level < text.length && text[level] != ' ')) {
      return theme.body;
    }
    return switch (level) {
      1 => theme.heading1,
      2 => theme.heading2,
      3 => theme.heading3,
      4 => theme.heading4,
      5 => theme.heading5,
      _ => theme.heading6,
    };
  }

  /// How far the line is indented, in live mode.
  ///
  /// A list item's marker is hidden and takes no room, so without this its text
  /// would start at the margin where the bullet used to be — the note would
  /// read
  /// as prose that happens to begin with a word. The indent is one level per
  /// marker the line carries, which is the depth the tokenizer already worked
  /// out.
  ///
  /// It is pure layout: no offset moves, because the text underneath is still
  /// the
  /// note's own text, character for character.
  double _indent() {
    if (!hideMarkers) return 0;
    var levels = 0;
    for (final token in styled.tokens) {
      if (token.kind == TokenKind.listMarker) levels++;
    }
    return levels * theme.listIndentPerLevel;
  }

  /// The line's tokens as styled runs. A token's override never changes the
  /// size
  /// or the height, so a line keeps the surface's metrics whatever it contains
  /// (`highlight_style.dart`).
  TextSpan _span() {
    final spans = <InlineSpan>[];
    var at = 0;
    // The runs are the tokenizer's; the selection cuts them where it starts and
    // ends, so a highlighted range is the same text with a background.
    for (final token in styled.tokens) {
      if (token.start > at) {
        _add(spans, at, token.start, null);
      }
      _add(
        spans,
        token.start,
        token.end,
        hideMarkers && _isMarker(token.kind)
            ? _hiddenMarker
            : markdownTokenStyle(token.kind, syntax, dark: dark),
      );
      at = token.end;
    }
    if (at < styled.text.length) _add(spans, at, styled.text.length, null);
    return TextSpan(children: spans);
  }

  /// Adds `[start, end)` to [spans], cut at the selection's edges so the
  /// covered
  /// part carries the highlight and the rest keeps the run's own style.
  void _add(List<InlineSpan> spans, int start, int end, TextStyle? style) {
    final selection = selected;
    if (selection == null || end <= selection.$1 || start >= selection.$2) {
      spans.add(
        TextSpan(text: styled.text.substring(start, end), style: style),
      );
      return;
    }
    final from = start < selection.$1 ? selection.$1 : start;
    final to = end > selection.$2 ? selection.$2 : end;
    if (from > start) {
      spans.add(
        TextSpan(text: styled.text.substring(start, from), style: style),
      );
    }
    spans.add(
      TextSpan(
        text: styled.text.substring(from, to),
        style: (style ?? const TextStyle()).copyWith(
          background: Paint()..color = _selectionColor,
        ),
      ),
    );
    if (to < end) {
      spans.add(TextSpan(text: styled.text.substring(to, end), style: style));
    }
  }
}

/// The style a hidden marker is drawn with: invisible, and small enough that
/// the
/// room it takes is nothing a reader notices.
///
/// The marker is still *there* — still a character at its own offset — which is
/// what keeps every text offset true; it is the room it takes that is given up,
/// so
/// a heading reads as a heading instead of starting with a gap the width of a
/// hash.
const TextStyle _hiddenMarker = TextStyle(
  color: Color(0x00000000),
  fontSize: 0.01,
);

/// Whether [kind] is a marker a formatted surface hides rather than shows.
///
/// The structural ones, which the tokenizer emits as runs of their own. The
/// inline
/// ones — the `**` around a bold word, the `$` around a formula — are part of
/// the
/// run they mark today, so hiding those means splitting them in the tokenizer
/// first; that is the next step, and this list is where it will show up.
bool _isMarker(TokenKind kind) => switch (kind) {
  TokenKind.headingMarker ||
  TokenKind.listMarker ||
  TokenKind.blockquote ||
  TokenKind.codeFence ||
  TokenKind.codeLanguage ||
  TokenKind.taskBox => true,
  _ => false,
};

/// Draws the caret: a thin vertical bar at the rectangle the line's own layout
/// answered with.
final class _CaretPainter extends CustomPainter {
  const new(this.rect);

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height),
      Paint()..color = const Color(0xFF7AA2F7),
    );
  }

  @override
  bool shouldRepaint(_CaretPainter oldDelegate) => oldDelegate.rect != rect;
}
