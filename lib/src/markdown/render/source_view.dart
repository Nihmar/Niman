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
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/editor/highlight_style.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/md_editing.dart';
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
    this.indentWidth = 2,
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

  /// How many spaces Tab indents by (the library's own setting).
  final int indentWidth;

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

  /// Where the caret is, and what it has selected.
  SelectionModel get selection => _selection;

  /// The paragraph of each line a frame has built, so a tap can ask the line it
  /// landed on where an offset is, and the caret can ask its own line for the
  /// rectangle. Only mounted lines keep a key: a long scroll forgets the lines
  /// it left, which is what keeps this from growing with the note.
  final Map<int, GlobalKey> _lineKeys = <int, GlobalKey>{};

  /// The caret rectangle in the caret line's coordinates, recomputed after the
  /// frame that laid that line out. A notifier rather than `setState`: neither
  /// the blink nor the measurement may rebuild the note.
  final ValueNotifier<Rect?> _caretRect = ValueNotifier<Rect?>(null);

  /// The line the caret is on, so that moving the caret repaints two lines
  /// rather than the viewport: the delegate no longer depends on the caret.
  final ValueNotifier<int> _caretLine = ValueNotifier<int>(0);

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
      onNewline: _newline,
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
        _syncLines();
        setState(() {
          _ownSelection = _ownSelection.clampTo(widget.buffer.length);
        });
        _scheduleCaret();
        _ensureCaretVisible();
        _notifyChanged();
      },
    );
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
      // And the platform's copy is now of a note that is not there any more.
      _input.sendSelection();
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
    _caretLine.dispose();
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

  /// How many times the platform's copy had to be told the note again.
  int get resyncs => _input.resyncs;

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
    if (box == null || _heights.length == 0) return null;
    // The map says which line a y falls in — above the first line is the
    // first, below the last is the last, so a tap under a short note puts the
    // caret at its end rather than nowhere.
    final y =
        box.globalToLocal(global).dy - widget.padding.top + _scroll.offset;
    final line = y < 0 ? 0 : _heights.indexAt(y) ?? _heights.length - 1;
    final paragraph = _paragraphAt(line);
    if (paragraph == null || !paragraph.attached) return null;
    // The point in the *paragraph's own* coordinates, from its own transform:
    // the insets, the gutter and a live-mode indent are all in that transform,
    // so none of them has to be subtracted by hand. (Doing it by hand
    // subtracted the gutter twice, and the caret landed a gutter's width left
    // of the finger.)
    final position = paragraph.getPositionForOffset(
      paragraph.globalToLocal(global),
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
    _publishSelection(next);
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
    _publishSelection(next);
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
    _syncLines();
    setState(() => _ownSelection = next);
    widget.onSelection?.call(next);
    _input.sendSelection();
    _scheduleCaret();
    _ensureCaretVisible();
    // The shell saves what it is told about: a cut, a paste or a backspace is
    // as much an edit as a keystroke.
    _notifyChanged();
  }

  /// Deletes the selection, or what is before the caret: one character, or a
  /// word with [word].
  ///
  /// The surface's own key, not the platform's: the Linux embedder leaves
  /// Backspace and Delete to the framework (`fl_text_input_handler.cc`:
  /// "already handled inside the framework"), which is `EditableText`'s job and
  /// therefore this surface's. An IME's own delete key still arrives as a
  /// deletion delta.
  void deleteBackward({bool word = false}) =>
      _delete(word ? CaretMotion.wordLeft : CaretMotion.characterLeft);

  /// Deletes the selection, or what is after the caret.
  void deleteForward({bool word = false}) =>
      _delete(word ? CaretMotion.wordRight : CaretMotion.characterRight);

  void _delete(CaretMotion motion) {
    final selection = _selection.clampTo(widget.buffer.length);
    if (!selection.isCollapsed) {
      _replaceRange(
        selection.start,
        selection.end,
        '',
        SelectionModel.at(selection.start),
      );
      return;
    }
    final other = moveCaret(selection, motion, buffer: widget.buffer).extent;
    if (other == selection.extent) return;
    final start = math.min(other, selection.extent);
    final end = math.max(other, selection.extent);
    _replaceRange(start, end, '', SelectionModel.at(start));
  }

  /// A line break typed over `[start, end)`, when it means more than a line
  /// break: inside a list item it carries the list on, and on an empty item it
  /// ends the list (#142, the legacy editor's `applyNewLine`). Answers whether
  /// it did either; otherwise the platform's line break is applied as typed.
  ///
  /// It hangs off the *line break arriving*, not off the Enter key, because
  /// that is the one place every embedder meets: an IME commits the break as
  /// text and the desktop embedders insert it themselves, so there is no key
  /// to bind that all of them send.
  bool _newline(int start, int end) {
    if (start != end) return false;
    final buffer = widget.buffer;
    final line = buffer.lineOf(start);
    if (!_isPlainLine(line)) return false;
    final text = buffer.lineAt(line);
    final head = listItemHead(text);
    if (head == null) return false;
    final lineStart = buffer.offsetOfLine(line);
    if (head.isEmpty) {
      // Enter on an item with nothing in it takes the marker away instead of
      // adding another empty item — the second Enter everybody presses to get
      // out of a list.
      _replaceRange(
        lineStart,
        lineStart + text.length,
        '',
        SelectionModel.at(lineStart),
      );
      return true;
    }
    // A caret inside the marker is not "in the item": leave it to the platform.
    if (start - lineStart < text.length - head.content.length) return false;
    final inserted = '\n${head.continuation}';
    // One edit, not a line break and then a marker: one undo step, and no
    // frame where the marker is missing.
    _replaceRange(
      start,
      end,
      inserted,
      SelectionModel.at(start + inserted.length),
    );
    return true;
  }

  /// Whether line [index] is ordinary Markdown — not fenced code, display
  /// maths or frontmatter, where a dash starts nothing. Answered by the
  /// tokenizer the view already keeps, as the legacy editor's `_isPlainLine`
  /// is, so the two cannot disagree about what a list is.
  bool _isPlainLine(int index) {
    if (index < 0 || index >= _tokens.lineCount) return true;
    for (final token in _tokens.lineAt(index).tokens) {
      if (token.kind == TokenKind.codeFence ||
          token.kind == TokenKind.mathBlock ||
          token.kind == TokenKind.frontmatter) {
        return false;
      }
    }
    return true;
  }

  /// Tab: moves the lines the selection touches in by `indentWidth` spaces —
  /// or, on a plain line with a collapsed caret, inserts them at the caret.
  ///
  /// The surface's own key: left to the app, Tab moves the focus to the next
  /// widget and takes the keyboard away from the note.
  void indent() {
    final selection = _selection.clampTo(widget.buffer.length);
    final line = widget.buffer.lineOf(selection.start);
    final pad = ' ' * widget.indentWidth;
    if (selection.isCollapsed &&
        listItemHead(widget.buffer.lineAt(line)) == null) {
      _replaceRange(
        selection.start,
        selection.end,
        pad,
        SelectionModel.at(selection.start + pad.length),
      );
      return;
    }
    _shiftLines(selection, (text) => '$pad$text');
  }

  /// Shift+Tab: moves the lines the selection touches out by up to
  /// `indentWidth` spaces, never taking anything but spaces.
  void outdent() {
    final selection = _selection.clampTo(widget.buffer.length);
    _shiftLines(selection, (text) {
      var spaces = 0;
      while (spaces < widget.indentWidth &&
          spaces < text.length &&
          text.codeUnitAt(spaces) == 0x20) {
        spaces++;
      }
      return text.substring(spaces);
    });
  }

  /// Rewrites every line [selection] touches with [shift], as one edit, and
  /// keeps each end of the selection on its own line and character.
  void _shiftLines(SelectionModel selection, String Function(String) shift) {
    final buffer = widget.buffer;
    final first = buffer.lineOf(selection.start);
    final last = buffer.lineOf(selection.end);
    final start = buffer.offsetOfLine(first);
    final end = buffer.offsetOfLine(last) + buffer.lineAt(last).length;
    final lines = <String>[];
    final deltas = <int>[];
    for (var at = first; at <= last; at++) {
      final before = buffer.lineAt(at);
      final after = shift(before);
      lines.add(after);
      deltas.add(after.length - before.length);
    }
    final eol = buffer.substring(start, end).contains('\r\n') ? '\r\n' : '\n';
    final replaced = lines.join(eol);
    if (replaced == buffer.substring(start, end)) return;
    int moved(int offset) {
      final line = buffer.lineOf(offset);
      final column = offset - buffer.offsetOfLine(line);
      var shiftBefore = 0;
      for (var at = first; at < line; at++) {
        shiftBefore += deltas[at - first];
      }
      final delta = deltas[line - first];
      // A column the shift removed collapses onto the line's new start.
      final newColumn = math.max(0, column + delta);
      return buffer.offsetOfLine(line) + shiftBefore + newColumn;
    }

    final next = SelectionModel(
      anchor: moved(selection.anchor),
      extent: moved(selection.extent),
    );
    _replaceRange(start, end, replaced, next);
  }

  /// PageUp and PageDown: the note moves a viewport, and the caret moves with
  /// it by as many rows, the way every editor pages.
  void _page(int direction, {bool extend = false}) {
    if (!_scroll.hasClients) return;
    final viewport = _scroll.position.viewportDimension;
    final rows = (viewport / widget.theme.lineHeight).floor() - 1;
    if (rows <= 0) return;
    final from = _scroll.offset;
    final to = (from + direction * rows * widget.theme.lineHeight).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    if (to == from) {
      // Nothing left to page through: the caret goes to that end of the note.
      moveCaretBy(
        direction < 0 ? CaretMotion.documentStart : CaretMotion.documentEnd,
        extend: extend,
      );
      return;
    }
    // The caret keeps its place *on the screen* while the note moves under
    // it, and that place is asked of whatever line is there after the jump —
    // the caret's own line may no longer be built at all.
    final box = _noteBox;
    final point =
        caretRect?.center ??
        box?.localToGlobal(Offset(0, viewport / 2)) ??
        Offset.zero;
    _scroll.jumpTo(to);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final offset = offsetAt(point);
      if (offset == null) return;
      final next = extend
          ? SelectionModel(anchor: _selection.anchor, extent: offset)
          : SelectionModel.at(offset);
      _publishSelection(next);
      widget.onSelection?.call(next);
      _input.sendSelection();
      _scheduleCaret();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Keeps the tokenizer and the height map at the buffer's line count.
  ///
  /// The view draws the buffer's lines and places them with the map, so the
  /// three have to agree about how many there are. The map is rebuilt only
  /// when the count changed: a keystroke inside a line is corrected by the
  /// sliver's own measurement.
  void _syncLines() {
    if (_tokens.lineCount != widget.buffer.lineCount) {
      _tokens = HighlightDocument.fromText(widget.buffer.text);
      _heights = _map();
    } else if (_heights.length != _tokens.lineCount) {
      _heights = _map();
    }
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

  /// How many taps have landed inside [_clickWindow], and when and where the
  /// last did.
  int _clicks = 0;
  DateTime? _lastClick;
  Offset? _lastClickAt;

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
    final lastAt = _lastClickAt;
    // Near in time *and* in place: two quick taps on different words are two
    // carets, not a double click — counting time alone selected a word under
    // the second tap and the next keystroke replaced it.
    _clicks =
        last != null &&
            lastAt != null &&
            now.difference(last) <= _clickWindow &&
            (position - lastAt).distance <= kDoubleTapSlop
        ? _clicks + 1
        : 1;
    _lastClick = now;
    _lastClickAt = position;
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
      // A mouse asks for the keyboard as it goes down, which is where a click
      // starts a drag; a finger asks on the tap (`onTapUp`), so a finger that
      // only scrolls the note does not bring the keyboard up.
      if (event.kind != PointerDeviceKind.mouse) return;
      _requestKeyboard();
      if (event.buttons != kPrimaryMouseButton) return;
      final offset = offsetAt(event.position);
      if (offset == null) return;
      _dragAnchor = offset;
      placeCaret(offset);
      // The platform needs the selection the drag ends with, not every one on
      // the way: a whole note per mouse move is what a drag must not cost.
      _input.holdSync = true;
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
    onPointerUp: (_) => _endDrag(),
    onPointerCancel: (_) => _endDrag(),
    child: child,
  );

  void _endDrag() {
    _dragAnchor = null;
    _input.holdSync = false;
  }

  /// Takes the focus, or — when the surface has it — opens the connection
  /// again if the platform closed it, and asks for the keyboard either way.
  void _requestKeyboard() {
    if (!_focus.hasFocus) {
      // The focus change attaches (see `onFocusChange`).
      _focus.requestFocus();
      return;
    }
    _input.attach(viewId: View.of(context).viewId);
  }

  /// Publishes [next] as the caret, repainting only what changed.
  ///
  /// A caret that stays collapsed moves no text: the two lines involved — the
  /// one
  /// that lost it and the one that gained it — repaint through the notifier,
  /// and
  /// nothing else does. A move that creates or clears a *range* repaints the
  /// note,
  /// because a range is a background on the runs it covers.
  void _publishSelection(SelectionModel next) {
    final wasRange = !_selection.isCollapsed;
    _ownSelection = next;
    if (!next.isCollapsed || wasRange) {
      setState(() {});
    }
    _caretLine.value = widget.buffer.lineOf(next.extent);
  }

  /// Puts the caret at [offset], tells the platform, and keeps it on screen.
  void placeCaret(int offset) {
    final next = _selection.collapsedTo(offset).clampTo(widget.buffer.length);
    _publishSelection(next);
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

  /// Line [index] as the view draws it: the **buffer's** text, with the
  /// tokenizer's runs when the two agree about that line.
  ///
  /// The buffer is the note; the tokenizer is a decoration of it. Drawing the
  /// buffer's lines and numbering them by index means a tokenizer that has
  /// fallen
  /// behind can make a line *plain*, and cannot make the numbers count
  /// something
  /// the note does not have — which is what a device showed when the two
  /// drifted.
  StyledLine _lineAt(int index) {
    final text = widget.buffer.lineAt(index);
    if (index < _tokens.lineCount && _tokens.lineAt(index).text == text) {
      return _tokens.lineAt(index);
    }
    return StyledLine(text, const <Token>[]);
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
    return _rangeIn(index, selection.start, selection.end);
  }

  /// The part of the IME's composing range inside line [index], underlined
  /// the way every text field shows the word being composed.
  (int, int)? _composingIn(int index) {
    final composing = _input.composing;
    if (!composing.isValid || composing.isCollapsed) return null;
    return _rangeIn(index, composing.start, composing.end);
  }

  /// `[from, to)` of the note, as offsets local to line [index], or null.
  (int, int)? _rangeIn(int index, int from, int to) {
    final start = widget.buffer.offsetOfLine(index);
    final end = start + widget.buffer.lineAt(index).length;
    final a = from < start ? start : from;
    final b = to > end ? end : to;
    if (a >= b) return null;
    return (a - start, b - start);
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
    return (width - _gutter) / advance;
  }

  /// The width the text has, from the last frame that laid it out.
  double? _paneWidth;

  /// The space the note column puts on each side of the text.
  double _sideSpace = 0;

  /// The gutter's width this frame: the numbers, and with a note column the
  /// legacy `side + 16 - 5`, so the text starts exactly on the column's edge.
  double _gutter = 0;

  /// The field's inset on the left: the legacy editor's own number.
  static const double _fieldInset = 5;

  /// The field's inset on the right: the field inset, or the column's edge.
  double get _rightInset =>
      _sideSpace == 0 ? _fieldInset : _sideSpace + NoteColumn.textInset;

  /// The field's inset on the left.
  double get _leftInset => _fieldInset;

  /// How wide the numbers are in the note's own face, plus the gap.
  ///
  /// **Measured**, not estimated: the numbers are set in the note's face at
  /// the ambient text scale, and "0.6 em per digit" is only nearly true of a
  /// monospace face — DejaVu Sans Mono, Linux's usual one, is 0.602 em, so two
  /// digits did not fit the room for two and every number from 10 on wrapped
  /// onto a second row, making each of its lines two rows tall.
  double _numbersWidth(TextScaler scaler) {
    if (!widget.showLineNumbers) return 0;
    final digits = widget.buffer.lineCount.toString().length;
    final style = widget.theme.body;
    final cached = _digits;
    if (cached != null &&
        cached.digits == digits &&
        cached.style == style &&
        cached.scaler == scaler) {
      return cached.width + _gutterGap;
    }
    final painter = TextPainter(
      text: TextSpan(text: '0' * digits, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    // A pixel of slack: a width that is exactly the text's can still wrap on
    // rounding.
    final width = painter.width.ceilToDouble() + 1;
    painter.dispose();
    _digits = (digits: digits, style: style, scaler: scaler, width: width);
    return width + _gutterGap;
  }

  ({int digits, TextStyle style, TextScaler scaler, double width})? _digits;

  /// Measures the caret after the frame that laid its line out.
  void _scheduleCaret() {
    _restartBlink();
    // Measured *now*, from the layout the last frame left, and again after the
    // next frame: a caret that moved because of a tap or a key is on screen
    // immediately, and the frame that may have re-laid its line corrects it.
    // Waiting only for the post-frame callback makes the caret a frame late,
    // which
    // is how a cursor feels slow when it is doing nothing slow.
    _measureCaret();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureCaret();
    });
  }

  /// Shows the caret and starts its blink over.
  ///
  /// Every move does this, the way every text field does: a caret that moved
  /// during the half of the blink it spends hidden stays invisible for up to
  /// 550 ms, which reads as a tap that took that long to land.
  void _restartBlink() {
    _caretOn.value = true;
    _blink?.cancel();
    _blink = Timer.periodic(const Duration(milliseconds: 550), (_) {
      _caretOn.value = !_caretOn.value;
    });
  }

  /// Where the caret is, from the caret line's own layout.
  void _measureCaret() {
    final line = _caretLineIndex;
    // Every selection change comes through here, so this is the one place the
    // lines hear which of them holds the caret.
    _caretLine.value = line;
    final paragraph = _paragraphAt(line);
    if (paragraph == null || line < 0) {
      _caretRect.value = null;
      return;
    }
    final local = _selection.extent - widget.buffer.offsetOfLine(line);
    final length = paragraph.text.toPlainText().length;
    final position = TextPosition(offset: local.clamp(0, length));
    // The caret is the *surface's* answer, not a metric computed beside it: the
    // painter reports the offset the way it paints it, over the run it is
    // really
    // over. The prototype's width matters only on the RTL side and its height
    // not
    // at all (the phase-1 spike), so the height comes from the line.
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
    _sendGeometry();
  }

  /// Tells the IME where the note is and where the caret is in it, so its
  /// candidate window (and a phone's handles) sit by the text rather than at
  /// the window's corner.
  void _sendGeometry() {
    if (!_input.isAttached) return;
    final box = _noteBox;
    final caret = caretRect;
    if (box == null || caret == null) return;
    _input.setGeometry(
      box.size,
      box.getTransformTo(null),
      box.globalToLocal(caret.topLeft) & caret.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final syntax = widget.syntax ?? SyntaxColors.of(context);
    // The shortcuts wrap the focus, not the other way round: a
    // `CallbackShortcuts`
    // only sees a key that travels through it on the way to the focused node,
    // so
    // one *below* the `Focus` it belongs to never fires.
    final note = _shortcuts(
      Focus(
        focusNode: _focus,
        onFocusChange: (hasFocus) => hasFocus
            ? _input.attach(viewId: View.of(context).viewId)
            : _input.detach(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _paneWidth = constraints.maxWidth;
            // The legacy editor's box, to the pixel (`note_editor.dart`):
            // `side` is the note column's side space, the gutter is
            // `side + 16 - 5` when there is a column (and never narrower than
            // the numbers), the field is inset by 5 on the left and by
            // `side + 16` on the right. The text therefore measures exactly
            // `column.width` and sits centred — which is what the column means,
            // and what a gutter eating into it made narrower.
            _sideSpace = widget.column.sideSpaceIn(constraints.maxWidth);
            // The gutter is the numbers *or* the column's own indentation: the
            // legacy editor reserved `side + 16 - 5` even with the numbers
            // turned
            // off, which is what keeps a column centred when the gutter is
            // empty.
            _gutter = math.max(
              _numbersWidth(MediaQuery.textScalerOf(context)),
              _sideSpace == 0 ? 0 : _sideSpace + 11,
            );
            final available =
                constraints.maxWidth - _leftInset - _rightInset - _gutter;
            return _mouseSelection(
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                // The keyboard is asked for on the *tap*: a drag the scroll
                // view wins is someone reading, not someone about to type.
                onTapUp: (details) {
                  _requestKeyboard();
                  _tapUp(details.globalPosition);
                },
                child: CustomScrollView(
                  key: _scrollKey,
                  controller: _scroll,
                  slivers: <Widget>[
                    SliverPadding(
                      padding: EdgeInsets.only(
                        left: _leftInset,
                        right: _rightInset,
                        top: widget.padding.top,
                        bottom: widget.padding.bottom,
                      ),
                      sliver: SliverMarkdownBlocks(
                        heights: _heights,
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _Line(
                            key: ValueKey<int>(index),
                            paragraphKey: _keyFor(index),
                            styled: _lineAt(index),
                            number: widget.showLineNumbers ? index + 1 : null,
                            gutterWidth: _gutter,
                            theme: widget.theme,
                            syntax: syntax,
                            dark: widget.dark,
                            hideMarkers: widget.hideMarkers,
                            selected: _selectionIn(index),
                            composing: _composingIn(index),
                            width: available,
                            index: index,
                            caretLine: _caretLine,
                            caret: _caretRect,
                            caretOn: _caretOn,
                          );
                        }, childCount: widget.buffer.lineCount),
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
      const SingleActivator(LogicalKeyboardKey.home, shift: true): () =>
          moveCaretBy(CaretMotion.lineTextStart, extend: true),
      const SingleActivator(LogicalKeyboardKey.end, shift: true): () =>
          moveCaretBy(CaretMotion.lineEnd, extend: true),
      const SingleActivator(LogicalKeyboardKey.home, control: true): () =>
          moveCaretBy(CaretMotion.documentStart),
      const SingleActivator(LogicalKeyboardKey.end, control: true): () =>
          moveCaretBy(CaretMotion.documentEnd),
      const SingleActivator(
        LogicalKeyboardKey.home,
        control: true,
        shift: true,
      ): () =>
          moveCaretBy(CaretMotion.documentStart, extend: true),
      const SingleActivator(
        LogicalKeyboardKey.end,
        control: true,
        shift: true,
      ): () =>
          moveCaretBy(CaretMotion.documentEnd, extend: true),
      const SingleActivator(LogicalKeyboardKey.pageUp): () => _page(-1),
      const SingleActivator(LogicalKeyboardKey.pageDown): () => _page(1),
      const SingleActivator(LogicalKeyboardKey.pageUp, shift: true): () =>
          _page(-1, extend: true),
      const SingleActivator(LogicalKeyboardKey.pageDown, shift: true): () =>
          _page(1, extend: true),
      // Tab is the note's: left to the app it moves the focus away, and the
      // keyboard with it.
      const SingleActivator(LogicalKeyboardKey.tab): indent,
      const SingleActivator(LogicalKeyboardKey.tab, shift: true): outdent,
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
      // Backspace and Delete *are* bound: no embedder edits the text for them
      // (Linux says so in its source, and Android's hardware key reaches the
      // framework first), so a surface that leaves them to the platform is one
      // that cannot delete. Handling the key stops it here, so it is never
      // applied twice.
      const SingleActivator(LogicalKeyboardKey.backspace): deleteBackward,
      const SingleActivator(LogicalKeyboardKey.backspace, shift: true):
          deleteBackward,
      const SingleActivator(LogicalKeyboardKey.backspace, control: true): () =>
          deleteBackward(word: true),
      const SingleActivator(LogicalKeyboardKey.backspace, alt: true): () =>
          deleteBackward(word: true),
      const SingleActivator(LogicalKeyboardKey.delete): deleteForward,
      const SingleActivator(LogicalKeyboardKey.delete, control: true): () =>
          deleteForward(word: true),
      const SingleActivator(LogicalKeyboardKey.delete, alt: true): () =>
          deleteForward(word: true),
      // Enter is deliberately *not* bound here. The platform already sends the
      // line break as text — an IME commits it, and the Linux embedder inserts
      // it and then calls the newline action, which inserts nothing (see
      // `SourceInput.performAction`) — so the delta is the only source.
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
    required this.composing,
    required this.width,
    required this.index,
    required this.caretLine,
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

  /// The range the IME is composing, as offsets local to this line, or null.
  final (int, int)? composing;

  /// The width the line's text wraps at (the pane minus the gutter).
  final double width;

  /// This line's index, to compare with [caretLine].
  final int index;

  /// The line the caret is on.
  final ValueListenable<int> caretLine;

  /// The caret rectangle, in the caret line's coordinates.
  final ValueListenable<Rect?> caret;
  final ValueListenable<bool> caretOn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // The gutter is there whenever it has a width, numbers or not: with
          // them off it is the note column's own indentation, and leaving it
          // out put the text at the pane's edge while the right side still
          // kept the column's room.
          if (gutterWidth > 0)
            SizedBox(
              width: gutterWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: _gutterGap),
                child: number == null
                    ? null
                    : Text(
                        '$number',
                        textAlign: TextAlign.right,
                        // One row, whatever the measurement said: a number
                        // that wraps makes its line two rows tall and every
                        // number below it sits beside the wrong text.
                        softWrap: false,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        // The text's own face and size, dimmed: what the
                        // legacy editor's `DefaultCodeLineNumber` does, so the
                        // numbers line up with the characters they count
                        // instead of drifting from them.
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
  ///
  /// Every line listens to *which* line holds the caret, so a tap that moves
  /// it to another line repaints the two lines involved at once — without
  /// that, the caret stayed drawn on its old line until something else rebuilt
  /// the note. The rectangle and the blink repaint the painter only, never the
  /// line, and the tree keeps its shape either way so the paragraph is never
  /// re-mounted.
  Widget _caretBox(Widget child) => ValueListenableBuilder<int>(
    valueListenable: caretLine,
    builder: (context, line, child) => CustomPaint(
      foregroundPainter: line == index
          ? _CaretPainter(rect: caret, on: caretOn)
          : null,
      child: child,
    ),
    child: child,
  );

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

  /// Adds `[start, end)` to [spans], cut at the selection's and the composing
  /// range's edges: the selected part carries the highlight, the composed part
  /// the underline, and the rest keeps the run's own style.
  void _add(List<InlineSpan> spans, int start, int end, TextStyle? style) {
    final cuts = <int>{start, end};
    for (final range in <(int, int)?>[selected, composing]) {
      if (range == null) continue;
      if (range.$1 > start && range.$1 < end) cuts.add(range.$1);
      if (range.$2 > start && range.$2 < end) cuts.add(range.$2);
    }
    final points = cuts.toList()..sort();
    for (var at = 0; at < points.length - 1; at++) {
      final from = points[at];
      final to = points[at + 1];
      bool inside((int, int)? range) =>
          range != null && from >= range.$1 && to <= range.$2;
      var piece = style;
      if (inside(selected)) {
        piece = (piece ?? const TextStyle()).copyWith(
          background: Paint()..color = _selectionColor,
        );
      }
      if (inside(composing)) {
        piece = (piece ?? const TextStyle()).copyWith(
          decoration: TextDecoration.underline,
        );
      }
      spans.add(TextSpan(text: styled.text.substring(from, to), style: piece));
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
///
/// It reads the rectangle and the blink at *paint* time and repaints when
/// either changes, so neither rebuilds the line it is drawn over.
final class _CaretPainter extends CustomPainter {
  new({required this.rect, required this.on})
    : super(repaint: Listenable.merge(<Listenable>[rect, on]));

  final ValueListenable<Rect?> rect;
  final ValueListenable<bool> on;

  @override
  void paint(Canvas canvas, Size size) {
    final value = rect.value;
    if (!on.value || value == null) return;
    canvas.drawRect(value, Paint()..color = const Color(0xFF7AA2F7));
  }

  @override
  bool shouldRepaint(_CaretPainter oldDelegate) =>
      oldDelegate.rect != rect || oldDelegate.on != on;
}
