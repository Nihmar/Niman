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
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/editor/highlight_style.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/editor/typewriter_scroll.dart';
import 'package:niman/src/markdown/active_formats.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/edit_history.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/edit/source_find.dart';
import 'package:niman/src/markdown/edit/source_input.dart';
import 'package:niman/src/markdown/edit/touch_selection.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/content_clamp_physics.dart';
import 'package:niman/src/markdown/render/footnote_list.dart';
import 'package:niman/src/markdown/render/live_blocks.dart';
import 'package:niman/src/markdown/render/live_code_colors.dart';
import 'package:niman/src/markdown/render/live_decorations.dart';
import 'package:niman/src/markdown/render/live_inline_math.dart';
import 'package:niman/src/markdown/render/live_quote_content.dart';
import 'package:niman/src/markdown/render/live_table_grid.dart';
import 'package:niman/src/markdown/render/live_tables.dart';
import 'package:niman/src/markdown/render/markdown_blocks_sliver.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/math_text.dart';
import 'package:niman/src/markdown/render/note_margins.dart';
import 'package:niman/src/markdown/render/source_folds.dart';
import 'package:niman/src/markdown/render/squiggle_painter.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';
import 'package:niman/src/markdown/source_styler.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/preview/code_highlight.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/ui/theme/tokens.dart';

/// The colour a selected run is painted with.
const Color _selectionColor = Color(0x553B82F6);

/// The colours the find bar's matches are painted with: every match, and the
/// one the bar is on.
const Color _matchColor = Color(0x55FFB300);
const Color _currentMatchColor = Color(0xAAFF8F00);

/// The gap between the line numbers and the text ([lineNumbersGap]).
const double _gutterGap = lineNumbersGap;

/// A link the writer Ctrl+clicked: its token's kind (a wikilink or a Markdown
/// link) and its text as written, brackets and all.
typedef SourceLinkTap = void Function(TokenKind kind, String raw);

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
    this.surface,
    this.column = NoteColumn.off,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.showLineNumbers = true,
    this.indentWidth = 2,
    this.hideMarkers = false,
    this.syntax,
    this.dark = false,
    this.formatMenu,
    this.spellCheck,
    this.findMatches,
    this.onOpenLink,
    this.activeItems,
    this.mathCache,
    this.embedResolver,
    this.caretWidth,
    this.typewriter = false,
    this.autofocus = false,
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

  /// Called after every edit, so the shell can save the note — and with
  /// nothing else: the debounce, the memento, the statistics and the preview
  /// all belong to whoever owns the note.
  ///
  /// It does not carry the text: joining the note is O(n), and the shell
  /// needs the text only when its debounce fires, not at every keystroke. The
  /// buffer is the shell's own object; it reads the text from it then.
  final ValueChanged<SourceEdit>? onChanged;

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

  /// The shell's hold on the note: its history, the selection to start with,
  /// and the door its commands come in through. Its buffer is [buffer].
  final MarkdownSurfaceController? surface;

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

  /// The toolbar's formatting actions, for the context menu (#174); null
  /// offers the clipboard alone.
  final FormatMenuBuilder? formatMenu;

  /// The note's spelling: the words it underlines, and the context menu's
  /// suggestions and Add to dictionary. Null checks nothing.
  final EditorSpellCheck? spellCheck;

  /// What the find bar found, painted over the lines; null finds nothing.
  final SourceMatches? findMatches;

  /// Called when a link is Ctrl+clicked (Cmd+clicked on a Mac); null leaves
  /// the click a click.
  final SourceLinkTap? onOpenLink;

  /// Which formats are on at the caret, for the toolbar's pressed state
  /// (#246). The surface owns the answer — it has the tokens — and writes it
  /// here, so the shell reads one notifier whichever engine draws the pane.
  final ValueNotifier<Set<ToolbarItem>>? activeItems;

  /// The typeset formulas, for `live` mode's display maths; without it a
  /// formula stays its source.
  final MathCache? mathCache;

  /// Where an embed's target is on disk, for `live` mode's pictures; without
  /// it a picture stays its source.
  final Future<String?> Function(String target)? embedResolver;

  /// The caret's width; null keeps the surface's own (Zen mode, #69,
  /// thickens it).
  final double? caretWidth;

  /// Typewriter mode (#70): the row being written keeps to the middle of the
  /// pane, lit faintly, and the note leaves room below its last line so that
  /// row can reach the middle there too.
  final bool typewriter;

  /// Whether the note takes the focus — and the keyboard — as it opens (the
  /// keyboard-on-open setting, and a template's `{{cursor}}`).
  final bool autofocus;

  @override
  State<MarkdownSourceView> createState() => MarkdownSourceViewState();
}

/// The source view's state, so a caller can ask where the caret is.
final class MarkdownSourceViewState extends State<MarkdownSourceView> {
  /// The colours: the read view's engine put on the source lines, kept
  /// across rebuilds and moved along by every edit — O(change).
  ///
  /// Null while a long note is read in the background ([_restyle]): the
  /// lines are drawn plain until it lands.
  SourceStyler? _styler;

  /// Counts the readings started, so one a later one overtook is dropped.
  int _stylings = 0;

  /// The heights the sliver places the rows with: one per line nobody has
  /// folded away.
  late BlockHeightMap _heights;

  /// The colours of the code blocks `live` draws, highlighted a block at a
  /// time as the read view highlights them.
  final LiveCodeColors _codeColors = LiveCodeColors();

  /// A quote's content read again as blocks, so `live` draws a quote's lines
  /// as the blocks they are inside it, as the read view does.
  final LiveQuoteContent _quotes = LiveQuoteContent();

  /// The note's tables, laid out as the read view lays them out.
  final LiveTables _tables = LiveTables();

  /// What the footnotes `live` ends the note with are parsed with.
  final BlockParser _footnoteParser = BlockParser();

  /// The formulas of those footnotes, for a surface given no math cache.
  final MathCache _footnoteMath = MathCache();

  /// Puts the caret at the start of [footnote]'s definition, which shows
  /// it: a tap on the footnote, at the end of the note, is the way to a
  /// definition `live` hides where it stands.
  void _toDefinition(Footnote footnote) {
    final line = _styler?.definitionLineOf(footnote.label);
    if (line == null) return;
    final offset = widget.buffer.offsetOfLine(line);
    _focus.requestFocus();
    _select(offset, offset);
    _ensureCaretVisible();
  }

  /// The folded heading sections; the rows are the lines they leave.
  final SourceFolds _folds = SourceFolds();

  /// Where each heading's section ends, as far as it has been asked, for the
  /// buffer revision [_sectionEndsRevision].
  final Map<int, int?> _sectionEnds = <int, int?>{};
  int _sectionEndsRevision = -1;

  /// A press on a fold arrow, so the pointer going down under it places no
  /// caret.
  bool _foldPress = false;

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

  /// The note's headings, as the scan behind the colours has them, or null
  /// while there is no scan yet (a long note reads in the background, see
  /// [_restyle]).
  ///
  /// The outline the note view publishes, from an answer it already holds.
  List<OutlineEntry>? get headings => _styler?.headings;

  /// Whether the note's blocks are all current: false while an edit that
  /// changed the rest of the note is still being scanned on, a slice at a
  /// time, and [headings] waits for it — and while a long note is still
  /// being read in the background, when there are no blocks at all.
  bool get scanSettled => _styler?.settled ?? false;

  /// The note's blocks, as the scan behind the colours has them, or null
  /// while there is no scan yet.
  ///
  /// What the shell asks when it needs to know whether the note holds
  /// something the scan already found — a list to count, so far. O(blocks):
  /// [SourceStyler.blocks] copies the list.
  List<Block>? get blocks => _styler?.blocks;

  /// The note's blocks and definitions as of [MarkdownSourceView.buffer]'s
  /// revision, with what changed since the last hand-over, or null while
  /// there is no whole, current scan of it ([SourceStyler.handOver]): what
  /// the read pane takes instead of scanning the note again.
  DocumentScan? handOver() => _styler?.handOver();

  /// The paragraph of each line a frame has built, so a tap can ask the line it
  /// landed on where an offset is, and the caret can ask its own line for the
  /// rectangle. Only mounted lines keep a key: a long scroll forgets the lines
  /// it left, which is what keeps this from growing with the note.
  final Map<int, GlobalKey> _lineKeys = <int, GlobalKey>{};

  /// The caret rectangle in the caret line's coordinates, recomputed after the
  /// frame that laid that line out. A notifier rather than `setState`: neither
  /// the blink nor the measurement may rebuild the note.
  final ValueNotifier<Rect?> _caretRect = ValueNotifier<Rect?>(null);

  /// Where the caret is, as the lines that draw it care: which line holds it,
  /// and the run of non-whitespace it sits in on that line.
  ///
  /// One value rather than two notifiers, so a caret move that crosses a word
  /// boundary repaints the two lines involved at once and a move *inside* a
  /// run repaints nothing: a `ValueNotifier` whose new value compares equal
  /// does not notify, and a run's own coordinates do not change while the
  /// caret stays in it. That is what keeps the per-word reveal off the frame
  /// budget — a keystroke inside a word tells no line anything.
  final ValueNotifier<CaretSpot> _caretSpot = ValueNotifier<CaretSpot>(
    const CaretSpot(0, 0, 0),
  );

  /// Whether the caret is drawn (it blinks).
  final ValueNotifier<bool> _caretOn = ValueNotifier<bool>(true);
  Timer? _blink;

  /// The overlay the touch selection's handles and toolbar are drawn in.
  final OverlayPortalController _touchOverlay = OverlayPortalController();

  /// Whether the selection was made by touch and shows its handles.
  bool _touchHandles = false;

  /// Whether the touch toolbar (copy, cut, paste, select all) is up.
  bool _touchToolbar = false;

  /// The kind of the pointer that last went down: a long press or a tap by a
  /// finger is a touch gesture, by a mouse it is not.
  PointerDeviceKind? _lastPointerKind;

  /// Ticks on every caret move, so the note's semantics — its text around the
  /// caret, and the selection in it — follow without rebuilding the note.
  final ValueNotifier<int> _semanticsTick = ValueNotifier<int>(0);

  /// Typewriter mode's glide to the caret, one per burst of moves.
  late final TypewriterFollow _typewriter = TypewriterFollow(_centerCaret);

  /// The overlay the desktop context menu is drawn in.
  final OverlayPortalController _menuOverlay = OverlayPortalController();

  /// Where the context menu opens, in global coordinates, while it is up.
  Offset? _menuAt;

  @override
  void initState() {
    super.initState();
    _restyle();
    _scroll = widget.controller ?? ScrollController();
    _ownsScroll = widget.controller == null;
    _focus = widget.focusNode ?? FocusNode();
    _ownsFocus = widget.focusNode == null;
    _heights = _map();
    _history = widget.history ?? widget.surface?.history ?? EditHistory();
    _ownSelection = widget.surface?.initialSelection ?? _ownSelection;
    _seenRevision = widget.buffer.revision;
    _input = _makeInput();
    widget.surface?.attachView(this);
    widget.spellCheck?.addListener(_onSpellingChanged);
    widget.findMatches?.addListener(_onSpellingChanged);
    _scheduleCaret();
    final scroll = widget.surface?.takePendingScroll();
    if (scroll != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) jumpToOffset(scroll);
      });
    }
  }

  /// The keyboard for the buffer this view shows.
  SourceInput _makeInput() => SourceInput(
    buffer: widget.buffer,
    onRecord: _history.record,
    onNewline: _newline,
    onTokenizer: (edit, buffer) => _styleEdited(edit),
    selection: () => _selection,
    onSelection: (next) {
      setState(() => _ownSelection = next);
      widget.onSelection?.call(next);
      _scheduleCaret();
    },
    onEdited: (edit) {
      _hideTouch();
      _syncLines(edit);
      setState(() {
        _ownSelection = _ownSelection.clampTo(widget.buffer.length);
      });
      _scheduleCaret();
      _ensureCaretVisible();
      _notifyChanged(edit);
    },
  );

  /// The buffer revision this view last drew or edited, so an edit made
  /// behind its back is seen. (Comparing the old widget's buffer with the new
  /// one's could not see it: it is the same object.)
  int _seenRevision = 0;

  @override
  void didUpdateWidget(MarkdownSourceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.surface, widget.surface)) {
      oldWidget.surface?.detachView(this);
      widget.surface?.attachView(this);
    }
    if (!identical(oldWidget.spellCheck, widget.spellCheck)) {
      oldWidget.spellCheck?.removeListener(_onSpellingChanged);
      widget.spellCheck?.addListener(_onSpellingChanged);
    }
    if (!identical(oldWidget.findMatches, widget.findMatches)) {
      oldWidget.findMatches?.removeListener(_onSpellingChanged);
      widget.findMatches?.addListener(_onSpellingChanged);
    }
    if (!identical(oldWidget.buffer, widget.buffer)) {
      // Another note: the keyboard, the history and the caret were this one's.
      final attached = _input.isAttached;
      _input.detach();
      _history = widget.history ?? widget.surface?.history ?? EditHistory();
      _ownSelection =
          widget.surface?.initialSelection ?? const SelectionModel.at(0);
      _input = _makeInput();
      _restyle();
      _folds.clear();
      _heights = _map();
      _seenRevision = widget.buffer.revision;
      if (attached) _input.attach(viewId: View.of(context).viewId);
    } else if (widget.buffer.revision != _seenRevision) {
      // An edit this view did not make (a command, a revert): the colours are
      // read again rather than adjusted, because there is no `SourceEdit` to
      // follow.
      _restyle();
      _folds.clear();
      _heights = _map();
      _seenRevision = widget.buffer.revision;
      _ownSelection = _ownSelection.clampTo(widget.buffer.length);
      // And the platform's copy is now of a note that is not there any more.
      _input.sendSelection();
    }
    if (oldWidget.selection != widget.selection ||
        oldWidget.caretWidth != widget.caretWidth) {
      _scheduleCaret();
    }
    // Switched on while writing: the caret goes to the middle at once.
    if (widget.typewriter && !oldWidget.typewriter) _followCaret();
    if (oldWidget.controller != widget.controller) {
      if (_ownsScroll) _scroll.dispose();
      _scroll = widget.controller ?? ScrollController();
      _ownsScroll = widget.controller == null;
    }
  }

  @override
  void dispose() {
    widget.surface?.detachView(this);
    widget.spellCheck?.removeListener(_onSpellingChanged);
    widget.findMatches?.removeListener(_onSpellingChanged);
    _input.detach();
    if (_ownsFocus) _focus.dispose();
    _blink?.cancel();
    _scanSlice?.cancel();
    _typewriter.dispose();
    _semanticsTick.dispose();
    _caretRect.dispose();
    _footnoteMath.dispose();
    _caretSpot.dispose();
    _caretOn.dispose();
    if (_ownsScroll) _scroll.dispose();
    super.dispose();
  }

  /// How many source lines the note has.
  int get lineCount => widget.buffer.lineCount;

  /// The spelling changed its mind (a dictionary loaded, a word added, the
  /// underline switched off), or the find bar found something else: the
  /// lines on screen are drawn again.
  void _onSpellingChanged() {
    if (mounted) setState(() {});
  }

  /// The runs on line [index], or none while a long note's colours are
  /// still being read — for the spelling's pass, which skips what is not
  /// prose.
  List<Token> tokensOf(int index) {
    if (index < 0 || index >= widget.buffer.lineCount) return const <Token>[];
    return _lineAt(index).tokens;
  }

  /// The keyboard focus, for a shell that wants to raise the keyboard.
  FocusNode get focusNode => _focus;

  /// Whether the platform is attached to this surface (the keyboard is up).
  bool get isKeyboardAttached => _input.isAttached;

  /// How many updates arrived as deltas, and how many of those arrived with an
  /// `oldText` that disagreed with the buffer.
  int get deltaCount => _input.deltaCount;

  /// How many times the platform's copy had to be told the note again.
  int get resyncs => _input.resyncs;

  /// Where the platform's window of the note starts: it holds the note from
  /// here, as long as its own text is.
  int get platformWindowStart => _input.windowStart;

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
  int? offsetAt(Offset global) =>
      _paintedOffsetAt(global) ?? _mappedOffsetAt(global);

  /// The offset under [global] on a line a frame has drawn, asked of the lines
  /// themselves — their paragraphs know where they were painted, so no map
  /// has to agree with them — or null when no drawn line is under it.
  int? _paintedOffsetAt(Offset global) {
    for (final entry in _lineKeys.entries) {
      final object = entry.value.currentContext?.findRenderObject();
      if (object is! RenderParagraph || !object.attached || !object.hasSize) {
        continue;
      }
      if (entry.key >= widget.buffer.lineCount) continue;
      final local = object.globalToLocal(global);
      if (local.dy < 0 || local.dy >= object.size.height) continue;
      return widget.buffer.offsetOfLine(entry.key) +
          object.getPositionForOffset(local).offset;
    }
    return null;
  }

  /// The offset under [global] as the height map places the lines: for a
  /// point no drawn line is under — above the first, below the last.
  int? _mappedOffsetAt(Offset global) {
    final box = _noteBox;
    if (box == null || _heights.length == 0) return null;
    // The map says which line a y falls in — above the first line is the
    // first, below the last is the last, so a tap under a short note puts the
    // caret at its end rather than nowhere.
    final y =
        box.globalToLocal(global).dy - widget.padding.top + _scroll.offset;
    final row = y < 0 ? 0 : _heights.indexAt(y) ?? _heights.length - 1;
    final line = _folds.lineOf(row);
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
    if (line < 0 || line >= lineCount || !_scroll.hasClients) return;
    _reshapeRows(() => _folds.reveal(line));
    _scroll.jumpTo(
      _heights
          .offsetOf(_folds.rowOf(line))
          .clamp(0.0, _scroll.position.maxScrollExtent),
    );
    _scheduleCaret();
  }

  /// How far the note is scrolled, for a memento.
  double get scrollOffset => _scroll.hasClients ? _scroll.offset : 0;

  /// Scrolls to [offset], as far as the note reaches.
  void jumpToOffset(double offset) {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(offset.clamp(0.0, _scroll.position.maxScrollExtent));
    _scheduleCaret();
  }

  /// Replaces `[start, end)` with [text] for the shell — a command, an image,
  /// a spelling fixed — as one undoable edit, caret at [caret] or after it.
  void replaceText(int start, int end, String text, {SelectionModel? caret}) =>
      _replaceRange(start, end, text, caret: caret);

  /// Makes the note say [text] because it changed elsewhere (the disk, the
  /// WYSIWYG): the history goes, since undoing past it would write the old
  /// text back over the other change, and nothing is reported as an edit.
  void replaceAll(String text) {
    final buffer = widget.buffer;
    buffer.replaceRange(0, buffer.length, text);
    _history.clear();
    _restyle();
    _folds.clear();
    _heights = _map();
    _seenRevision = buffer.revision;
    setState(() => _ownSelection = _ownSelection.clampTo(buffer.length));
    _input.sendSelection();
    _scheduleCaret();
  }

  /// Selects [next], and tells whoever needs to know.
  void select(SelectionModel next) {
    final clamped = next.clampTo(widget.buffer.length);
    _history.seal();
    setState(() => _ownSelection = clamped);
    widget.onSelection?.call(clamped);
    _input.sendSelection();
    _scheduleCaret();
    _ensureCaretVisible();
  }

  /// Undoes the last edit, and says whether there was one.
  bool undo() => _applyHistory(_history.undo(widget.buffer), forwards: false);

  /// Redoes the last undone edit, and says whether there was one.
  bool redo() => _applyHistory(_history.redo(widget.buffer), forwards: true);

  /// Rebuilds what an undo or a redo changed, the same way a platform edit
  /// does.
  bool _applyHistory(EditRecord? record, {required bool forwards}) {
    if (record == null) return false;
    // An undo is an edit like any other: the buffer says which lines it
    // touched, and the tokenizer and the map follow those lines.
    final edit = _history.lastEdit;
    if (edit != null) {
      _styleEdited(edit);
    } else {
      _restyle();
    }
    _syncLines(edit);
    // The word count follows the same edit; the undo record is the one it
    // has, or a rebuild when there is none (a restyle after a reload).
    // Undo puts the caret after what it restored (where it was before a
    // deletion, at the start of typing it took back); redo after what it did.
    final caret = forwards ? record.end : record.start + record.removed.length;
    setState(() {
      _ownSelection = _selection
          .collapsedTo(caret)
          .clampTo(widget.buffer.length);
    });
    widget.onSelection?.call(_ownSelection);
    _input.sendSelection();
    _scheduleCaret();
    _ensureCaretVisible();
    if (edit != null) _notifyChanged(edit);
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
    final caret = caretRect;
    if (caret == null || rows == 0) return;
    // The caret's own row is the row height — its line's, at the scale it is
    // drawn at — and the point is the middle of the row [rows] away, so a
    // boundary never decides which row it is.
    final point = Offset(
      caret.center.dx,
      caret.center.dy + rows * caret.height,
    );
    final offset = _paintedOffsetAt(point);
    if (offset != null) {
      _moveCaretTo(offset, extend: extend);
      return;
    }
    // The row is not drawn: move the note under the caret by as much, and ask
    // the line that is there once the frame has built it.
    if (!_scroll.hasClients) return;
    final from = _scroll.offset;
    final to = (from + rows * caret.height).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    if (to == from) {
      // Nothing further in that direction: the caret goes to the note's end.
      moveCaretBy(
        rows < 0 ? CaretMotion.documentStart : CaretMotion.documentEnd,
        extend: extend,
      );
      return;
    }
    _scroll.jumpTo(to);
    final shifted = point - Offset(0, to - from);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final landed = _paintedOffsetAt(shifted) ?? _mappedOffsetAt(shifted);
      if (landed != null) _moveCaretTo(landed, extend: extend);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Puts the caret at [offset] — extending the selection with [extend] — and
  /// tells everyone who needs to know.
  void _moveCaretTo(int offset, {bool extend = false}) {
    final next = extend
        ? SelectionModel(anchor: _selection.anchor, extent: offset)
        : SelectionModel.at(offset);
    _publishSelection(next.clampTo(widget.buffer.length));
    widget.onSelection?.call(_selection);
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
    _replaceRange(selection.start, selection.end, '');
  }

  /// Inserts the clipboard's text at the caret, replacing the selection.
  Future<void> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    final selection = _selection;
    // The caret goes after what the note *stored*: a Windows clipboard's
    // `\r\n` pasted into an LF note is shorter than the text that was copied.
    _replaceRange(selection.start, selection.end, text);
  }

  /// Replaces `[start, end)` with [text] because the *app* asked, not the
  /// platform: the history records it, the tokenizer follows it, and the
  /// platform is told where the caret went — [caret], or after what the note
  /// stored when none is given.
  ///
  /// With [verbatim] the text's own line endings are kept (see
  /// `SourceBuffer.replaceRange`). Without [follow] the note stays where it
  /// is on screen rather than going to the caret: an edit made somewhere the
  /// writer is looking, not where they are typing — a checkbox ticked.
  void _replaceRange(
    int start,
    int end,
    String text, {
    SelectionModel? caret,
    bool verbatim = false,
    bool follow = true,
  }) {
    if (start < 0 || end < start || end > widget.buffer.length) return;
    _hideTouch();
    final buffer = widget.buffer;
    final before = buffer.length;
    final removed = buffer.substring(start, end);
    final edit = buffer.replaceRange(start, end, text, verbatim: verbatim);
    final stored = buffer.length - before + (end - start);
    _history.record(
      EditRecord(
        start: start,
        removed: removed,
        inserted: buffer.substring(start, start + stored),
      ),
    );
    _styleEdited(edit);
    final next = (caret ?? SelectionModel.at(start + stored)).clampTo(
      buffer.length,
    );
    _syncLines(edit);
    setState(() => _ownSelection = next);
    widget.onSelection?.call(next);
    _input.sendSelection();
    _scheduleCaret();
    if (follow) _ensureCaretVisible();
    // The shell saves and counts what it is told about: a cut, a paste or a
    // backspace is as much an edit as a keystroke, and the edit says which
    // lines moved so the word count pays for those and not for the note.
    _notifyChanged(edit);
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
      _replaceRange(selection.start, selection.end, '');
      return;
    }
    final other = moveCaret(selection, motion, buffer: widget.buffer).extent;
    if (other == selection.extent) return;
    final start = math.min(other, selection.extent);
    final end = math.max(other, selection.extent);
    _replaceRange(start, end, '');
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
      _replaceRange(lineStart, lineStart + text.length, '');
      return true;
    }
    // A caret inside the marker is not "in the item": leave it to the platform.
    if (start - lineStart < text.length - head.content.length) return false;
    // One edit, not a line break and then a marker: one undo step, and no
    // frame where the marker is missing.
    _replaceRange(start, end, '\n${head.continuation}');
    return true;
  }

  /// Whether line [index] is ordinary Markdown — not fenced code, display
  /// maths or frontmatter, where a dash starts nothing. Answered by the
  /// colours the view already keeps, so the two cannot disagree about what a
  /// list is.
  bool _isPlainLine(int index) {
    if (index < 0 || index >= lineCount) return true;
    for (final token in _lineAt(index).tokens) {
      if (token.kind == TokenKind.codeFence ||
          token.kind == TokenKind.codeBlock ||
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
      _replaceRange(selection.start, selection.end, pad);
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
    final end = buffer.offsetOfLine(last) + buffer.lineLengthAt(last);
    final block = StringBuffer();
    final deltas = <int>[];
    var changed = false;
    for (var at = first; at <= last; at++) {
      final before = buffer.lineAt(at);
      final after = shift(before);
      // Each line keeps its own terminator: the block goes back verbatim.
      block.write(after);
      if (at < last) block.write(buffer.terminatorAt(at));
      deltas.add(after.length - before.length);
      changed = changed || after != before;
    }
    if (!changed) return;
    final replaced = block.toString();
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
    _replaceRange(start, end, replaced, caret: next, verbatim: true);
  }

  /// PageUp and PageDown: the note moves a viewport, and the caret moves with
  /// it by as many rows, the way every editor pages.
  void _page(int direction, {bool extend = false}) {
    if (!_scroll.hasClients) return;
    final viewport = _scroll.position.viewportDimension;
    final rows = (viewport / _rowHeight).floor() - 1;
    if (rows <= 0) return;
    final from = _scroll.offset;
    final to = (from + direction * rows * _rowHeight).clamp(
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

  /// Keeps the tokenizer and the height map at the buffer's line count, after
  /// [edit].
  ///
  /// The view draws the buffer's lines and places them with the map, so the
  /// three have to agree about how many there are. When the count changed the
  /// map is **spliced** — the lines the edit replaced go, the ones it added
  /// come in estimated, and every other line keeps the height a frame measured
  /// — because rebuilding it moved everything on screen on every Enter. A
  /// keystroke inside a line is corrected by the sliver's own measurement.
  void _syncLines([SourceEdit? edit]) {
    _seenRevision = widget.buffer.revision;
    final lines = widget.buffer.lineCount;
    if (!_folds.isEmpty) {
      // The folds follow the edit; when what they hide changed shape, the
      // rows are measured again rather than spliced.
      final reshaped = edit == null || _folds.edited(edit, lines, _sectionEnd);
      if (edit == null) _folds.clear();
      if (reshaped) {
        _heights = _map();
        return;
      }
    }
    final rows = _folds.rowCount(lines);
    if (_heights.length == rows) return;
    if (edit != null &&
        _heights.length - edit.removedLines + edit.insertedLines == rows) {
      _heights.splice(
        _folds.rowOf(edit.firstLine),
        edit.removedLines,
        edit.insertedLines,
        _estimateRow,
      );
    } else {
      _heights = _map();
    }
  }

  // --------------------------------------------------------------- folding

  /// Notes longer than this fold nothing: finding where a section ends walks
  /// the lines after its heading, and the legacy editor drew no fold arrows
  /// past the same size either.
  static const int _foldLineLimit = 20000;

  /// Whether the gutter offers fold arrows.
  bool get _foldingEnabled =>
      widget.showLineNumbers && widget.buffer.lineCount <= _foldLineLimit;

  /// Whether the heading on [line] is folded.
  bool isFolded(int line) => _folds.isFolded(line);

  /// Folds the section under the heading on [line], or unfolds it.
  ///
  /// A caret inside the section goes to the heading's end: the caret is never
  /// on a line nobody can see.
  void toggleFold(int line) {
    if (line < 0 || line >= widget.buffer.lineCount) return;
    if (_folds.isFolded(line)) {
      _reshapeRows(() {
        _folds.unfold(line);
        return true;
      });
    } else {
      final end = _foldableEnd(line);
      if (end == null) return;
      _reshapeRows(() {
        _folds.fold(line, end);
        return true;
      });
      final caret = widget.buffer.lineOf(_selection.extent);
      if (_folds.isHidden(caret)) {
        placeCaret(
          widget.buffer.offsetOfLine(line) + widget.buffer.lineLengthAt(line),
        );
      }
    }
    setState(() {});
  }

  /// Runs [change] on the folds and, when it says it changed them, gives the
  /// rows new heights — each line that was drawn before keeps the height it
  /// was drawn at, so unfolding a section does not move the rest.
  void _reshapeRows(bool Function() change) {
    final before = _folds.copy();
    final old = _heights;
    if (!change()) return;
    _heights = BlockHeightMap(
      count: _folds.rowCount(lineCount),
      estimate: (row) {
        final line = _folds.lineOf(row);
        if (!before.isHidden(line)) {
          final was = before.rowOf(line);
          if (was < old.length) return old.extentFor(was);
        }
        return _estimate(line);
      },
    );
  }

  /// Unfolds what hides the caret, when an edit, a find or a motion took it
  /// there.
  void _revealCaret() {
    if (_folds.isEmpty) return;
    final line = widget.buffer.lineOf(
      _selection.extent.clamp(0, widget.buffer.length),
    );
    var revealed = false;
    _reshapeRows(() => revealed = _folds.reveal(line));
    if (revealed && mounted) setState(() {});
  }

  /// The heading level of line [line], or null when it is not a heading.
  int? _headingLevel(int line) {
    if (!widget.buffer.lineAt(line).startsWith('#')) return null;
    final tokens = _lineAt(line).tokens;
    if (tokens.isEmpty ||
        tokens.first.kind != TokenKind.headingMarker ||
        tokens.first.start != 0) {
      return null;
    }
    // The outline's own rule (`outline.dart`): the marker's length.
    return tokens.first.end - tokens.first.start;
  }

  /// Where the section under the heading on [line] ends — the next heading
  /// of its level or above, or the note's end — or null when [line] is not a
  /// heading.
  int? _sectionEnd(int line) {
    final revision = widget.buffer.revision;
    if (revision != _sectionEndsRevision) {
      _sectionEnds.clear();
      _sectionEndsRevision = revision;
    }
    if (_sectionEnds.containsKey(line)) return _sectionEnds[line];
    final level = _headingLevel(line);
    int? end;
    if (level != null) {
      final count = widget.buffer.lineCount;
      end = count;
      for (var at = line + 1; at < count; at++) {
        final other = _headingLevel(at);
        if (other != null && other <= level) {
          end = at;
          break;
        }
      }
    }
    return _sectionEnds[line] = end;
  }

  /// Where the heading on [line] would fold to, when it has a section worth
  /// folding: two lines or more under it, the legacy editor's rule.
  int? _foldableEnd(int line) {
    final end = _sectionEnd(line);
    if (end == null || end - line - 1 < 2) return null;
    return end;
  }

  /// What the gutter shows beside line [line].
  _FoldMark _foldMarkOf(int line) {
    if (!_foldingEnabled) return _FoldMark.none;
    if (_folds.isFolded(line)) return _FoldMark.closed;
    return _foldableEnd(line) == null ? _FoldMark.none : _FoldMark.open;
  }

  /// The note changed, so the shell can save it.
  void _notifyChanged(SourceEdit edit) => widget.onChanged?.call(edit);

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
        // A word never crosses a line: the line's text, not the note's.
        final line = widget.buffer.lineOf(offset);
        final lineStart = widget.buffer.offsetOfLine(line);
        final text = widget.buffer.lineAt(line);
        final (start, end) = wordRangeAt(text, offset - lineStart);
        _select(
          lineStart + math.min(start, text.length),
          lineStart + math.min(end, text.length),
        );
      default:
        final line = widget.buffer.lineOf(offset);
        _select(
          widget.buffer.offsetOfLine(line),
          widget.buffer.offsetOfLine(line) + widget.buffer.lineLengthAt(line),
        );
        _clicks = 0;
    }
  }

  /// The `[ ]` or `[x]` of the task box `live` draws under [global] — its
  /// source range, and whether it is ticked — or null when no box is there.
  ///
  /// Only a box that is drawn: on the caret's line the markers are the
  /// source, written out, and a click there is a click in the text. The box
  /// is where the painter puts it ([liveItemSlot]), asked of the same
  /// paragraph, so the two agree by construction.
  ({int start, int end, bool ticked})? _taskBoxAt(Offset global) {
    if (!widget.hideMarkers) return null;
    final caretLine = _caretSpot.value.line;
    for (final entry in _lineKeys.entries) {
      final index = entry.key;
      if (index == caretLine || index >= widget.buffer.lineCount) continue;
      final paragraph = entry.value.currentContext?.findRenderObject();
      if (paragraph is! RenderParagraph ||
          !paragraph.attached ||
          !paragraph.hasSize) {
        continue;
      }
      final styled = _lineAt(index);
      final block = _styler?.blockOf(index);
      final shape = LineShape.of(
        styled,
        block,
        index,
        quoted: _quotes.of(index, block, widget.buffer),
      );
      final ticked = shape.task;
      if (shape.marker == null || ticked == null) continue;
      final slot = liveItemSlot(paragraph, shape, widget.theme);
      if (!slot.contains(paragraph.globalToLocal(global))) continue;
      for (final token in styled.tokens) {
        if (token.kind != TokenKind.taskBox) continue;
        final start = widget.buffer.offsetOfLine(index) + token.start;
        return (
          start: start,
          end: start + token.end - token.start,
          ticked: ticked,
        );
      }
    }
    return null;
  }

  /// Ticks or unticks the task box under [global], and answers whether
  /// there was one: one edit and one undo step, the `x` written or taken out
  /// inside the brackets, the caret and the view left where they were.
  bool _toggleTaskAt(Offset global) {
    final box = _taskBoxAt(global);
    if (box == null) return false;
    _history.seal();
    _replaceRange(
      box.start + 1,
      box.start + 2,
      box.ticked ? ' ' : 'x',
      caret: _selection,
      follow: false,
    );
    _history.seal();
    return true;
  }

  void _select(int start, int end) {
    final next = SelectionModel(anchor: start, extent: end);
    _history.seal();
    setState(() => _ownSelection = next);
    widget.onSelection?.call(next);
    _input.sendSelection();
    _scheduleCaret();
  }

  /// Selects everything.
  void selectAll() {
    final next = SelectionModel(anchor: 0, extent: widget.buffer.length);
    _history.seal();
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
      _lastPointerKind = event.kind;
      // A mouse asks for the keyboard as it goes down, which is where a click
      // starts a drag; a finger asks on the tap (`onTapUp`), so a finger that
      // only scrolls the note does not bring the keyboard up.
      if (event.kind != PointerDeviceKind.mouse) return;
      _hideTouch();
      _requestKeyboard();
      if (_foldPress) {
        _foldPress = false;
        return;
      }
      if (event.buttons == kSecondaryMouseButton) {
        _secondaryClick(event.position);
        return;
      }
      if (event.buttons != kPrimaryMouseButton) return;
      // A press on a task box ticks it when it is let go (`_tapUp`): it
      // neither places a caret nor starts a selection.
      if (_taskBoxAt(event.position) != null) return;
      final offset = offsetAt(event.position);
      if (offset == null) return;
      if (_openLinkAt(offset)) return;
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
      _history.seal();
      setState(() => _ownSelection = next);
      widget.onSelection?.call(next);
      _input.sendSelection();
      _scheduleCaret();
    },
    onPointerUp: (_) => _endDrag(),
    onPointerCancel: (_) => _endDrag(),
    child: child,
  );

  /// A Ctrl+click (Cmd on a Mac) on a link at [offset]: the caret goes there
  /// and the link opens, the legacy editor's T-M3-07. True when it did.
  bool _openLinkAt(int offset) {
    final open = widget.onOpenLink;
    if (open == null) return false;
    final keyboard = HardwareKeyboard.instance;
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    if (!(mac ? keyboard.isMetaPressed : keyboard.isControlPressed)) {
      return false;
    }
    final link = linkAt(offset);
    if (link == null) return false;
    placeCaret(offset);
    open(link.$1, link.$2);
    return true;
  }

  /// The wikilink or Markdown link under [offset] — its kind and its text as
  /// written — or null. An offset on either edge of the link is on it: a
  /// click lands between characters, and a click on the first or the last
  /// one lands on the edge.
  (TokenKind, String)? linkAt(int offset) {
    final buffer = widget.buffer;
    final line = buffer.lineOf(offset.clamp(0, buffer.length));
    final local = offset - buffer.offsetOfLine(line);
    final styled = _lineAt(line);
    final tokens = styled.tokens;
    for (var at = 0; at < tokens.length; at++) {
      final token = tokens[at];
      if (token.kind != TokenKind.wikilink && token.kind != TokenKind.link) {
        continue;
      }
      // A link comes as its markers and its text, one token each: the link
      // is the run of them.
      var end = at;
      while (end + 1 < tokens.length &&
          tokens[end + 1].kind == token.kind &&
          tokens[end + 1].start == tokens[end].end) {
        end++;
      }
      if (local >= token.start && local <= tokens[end].end) {
        return (
          token.kind,
          styled.text.substring(token.start, tokens[end].end),
        );
      }
      at = end;
    }
    return null;
  }

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
    // A caret the writer moved ends the typing step: what is typed next is
    // undone on its own.
    _history.seal();
    final wasRange = !_selection.isCollapsed;
    _ownSelection = next;
    if (!next.isCollapsed || wasRange) {
      setState(() {});
    }
    _caretSpot.value = _spotOf(next.extent);
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
  ///
  /// The jump is planned on the height map, and far from the viewport that
  /// is estimates: the frame that lands measures the rows it draws, and the
  /// line — and the note's extent — can end up elsewhere than planned.
  /// Ctrl+End left the last line half under the pane's edge until the
  /// wheel, scrolling against the measured extent, went the rest of the
  /// way. So a jump is checked again after the frames that follow it, for
  /// as long as each one still has to move — [settle] of them at most.
  void _ensureCaretVisible({int settle = 3}) {
    if (!_scroll.hasClients) return;
    final line = _caretLineIndex;
    if (line < 0) return;
    // In the scroll view's coordinates: the map starts below the top padding,
    // and the last line takes the bottom padding with it. Without them every
    // jump down stopped the padding short, the caret's row cut by it.
    final row = _folds.rowOf(line);
    final top = widget.padding.top + _heights.offsetOf(row);
    final last = row == _heights.length - 1;
    final bottom =
        top + _heights.extentFor(row) + (last ? widget.padding.bottom : 0);
    final viewport = _scroll.position.viewportDimension;
    final double target;
    if (top < _scroll.offset) {
      target = line == 0 ? 0 : top;
    } else if (bottom > _scroll.offset + viewport) {
      target = (bottom - viewport).clamp(0.0, _scroll.position.maxScrollExtent);
    } else {
      return;
    }
    if (target == _scroll.offset) return;
    _scroll.jumpTo(target);
    if (settle <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureCaretVisible(settle: settle - 1);
    });
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
    final styler = _styler;
    if (styler == null || index < 0 || index >= lineCount) {
      return StyledLine(text, const <Token>[]);
    }
    return StyledLine(text, styler.tokensOf(index));
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

  /// The words the checker flags on line [index], as offsets local to it.
  List<TextRange> _misspelledIn(int index) {
    if (widget.spellCheck == null) return const <TextRange>[];
    return _spellRanges(index, widget.buffer.lineAt(index));
  }

  /// The find bar's matches on line [index], as offsets local to it.
  List<(int, int, bool)> _foundIn(int index) {
    final matches = widget.findMatches;
    if (matches == null) return const <(int, int, bool)>[];
    final start = widget.buffer.offsetOfLine(index);
    return matches
        .within(start, start + widget.buffer.lineLengthAt(index))
        .toList();
  }

  /// `[from, to)` of the note, as offsets local to line [index], or null.
  (int, int)? _rangeIn(int index, int from, int to) {
    final start = widget.buffer.offsetOfLine(index);
    final end = start + widget.buffer.lineLengthAt(index);
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
    return line < 0 || line >= lineCount ? -1 : line;
  }

  /// The caret's line and the run of non-whitespace it is in on that line, as
  /// the lines are told it ([CaretSpot]).
  ///
  /// [offset] is the caret asked about, defaulting to the selection's own end.
  /// It is passed explicitly where the caller already knows where the caret is
  /// going — a move publishes the *destination*, and the widget's own
  /// selection may still be the old one until the shell that owns it rebuilds.
  ///
  /// The run is read from the line's own text rather than off the styled
  /// tokens: the reveal compares a *marker* against it, and the markers belong
  /// to the run (`runAround`), so the two agree by construction.
  CaretSpot _spotOf([int? offset]) {
    final at = offset ?? _selection.extent;
    final line = widget.buffer.lineOf(at);
    if (line < 0 || line >= lineCount) return const CaretSpot(-1, 0, 0);
    final text = widget.buffer.lineAt(line);
    final column = (at - widget.buffer.offsetOfLine(line)).clamp(
      0,
      text.length,
    );
    final (from, to) = runAround(text, column);
    return CaretSpot(line, from, to);
  }

  /// The caret's spot, exposed so a test can hold that a move inside a run
  /// tells no line anything. Exposed as a listenable rather than as a value
  /// because *not* notifying is the property.
  @visibleForTesting
  ValueListenable<CaretSpot> get caretSpot => _caretSpot;

  /// Publishes the formats on at [spot] to the shell's toolbar (#246).
  ///
  /// The answer is read off the caret's line — the same tokens the colours are
  /// drawn from — and written into the shell's notifier, which is the shape the
  /// legacy WYSIWYG published through, so the toolbar reads one thing whichever
  /// engine draws the pane (`active_formats.dart`).
  ///
  /// Deferred out of a build: the toolbar is not a descendant of this surface,
  /// so notifying it while the framework is building is a `markNeedsBuild` it
  /// refuses. The answer is the same one frame later, and the caret's own value
  /// is read again then rather than carried.
  void _publishActive(CaretSpot spot) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _publishActiveNow(_caretSpot.value);
      });
      return;
    }
    _publishActiveNow(spot);
  }

  void _publishActiveNow(CaretSpot spot) {
    final notifier = widget.activeItems;
    if (notifier == null) return;
    final active = spot.line < 0 || spot.line >= lineCount
        ? const <ToolbarItem>{}
        : activeFormatsOf(
            text: widget.buffer.lineAt(spot.line),
            tokens: tokensOf(spot.line),
            run: (spot.runStart, spot.runEnd),
          );
    // Equal sets are not a change: the toolbar is not told to rebuild when the
    // caret moves inside a run whose formats are the same.
    if (setEquals(active, notifier.value)) return;
    notifier.value = active;
  }

  /// From how many lines on a note's colours are read in the background.
  ///
  /// Below it the reading costs a frame or less and is done in place, so
  /// the first frame is already coloured.
  @visibleForTesting
  static int backgroundLines = 50000;

  /// Reads the note's colours again, from the top.
  ///
  /// A long note is read in an isolate ([SourceStyler.inBackground]): the
  /// block scan of a 246 MB note is 2 s of a frozen window. Its lines are
  /// drawn plain until the reading lands, and one that lands on a note that
  /// moved on meanwhile is started again.
  void _restyle() {
    final buffer = widget.buffer;
    final reading = ++_stylings;
    if (buffer.lineCount < backgroundLines) {
      _styler = SourceStyler(buffer);
      return;
    }
    _styler = null;
    unawaited(
      SourceStyler.inBackground(buffer).then((styler) {
        if (!mounted || reading != _stylings) return;
        if (!identical(widget.buffer, buffer)) return;
        if (styler.revision != buffer.revision) {
          _restyle();
          return;
        }
        setState(() => _styler = styler);
        // The colours landing is also the formats landing: until they are
        // read, the caret's line has no tokens and the toolbar would show
        // every button dark on a note whose syntax the writer is inside.
        _publishActive(_caretSpot.value);
      }),
    );
  }

  /// The display formula line [index] is part of, for `live` mode to draw
  /// in its lines' place: its lines and its TeX. Null for any other line.
  LiveFormula? _formulaOf(int index) {
    final block = _styler?.blockOf(index);
    if (block == null || block.kind != BlockKind.math) return null;
    final tex = displayTexOf(BlockParser.blockText(block, widget.buffer));
    if (tex.isEmpty) return null;
    return (start: block.startLine, end: block.endLine, tex: tex);
  }

  /// Moves the colours along [edit], already made to the buffer.
  void _styleEdited(SourceEdit edit) {
    _styler?.edited(edit);
    _carryScanOn();
  }

  /// The next slice of a scan an edit left owed, when one is waiting.
  Timer? _scanSlice;

  /// Carries on, a slice at a time, the scan an edit left owed
  /// (`docs/dev/huge-notes.md` item 3).
  ///
  /// An edit that changes what the rest of the note is — a `$$` opened at 50 %
  /// of a 246 MB note — scans its budget of lines and stops, and the lines on
  /// screen catch it up as far as they need. Nothing drawn waits for the rest,
  /// so nothing here repaints; what finishing it gives back is the whole
  /// note's answers — the outline, the blocks — to the readers that ask for
  /// all of it.
  ///
  /// Each slice is a timer of its own, so a frame or a key between two slices
  /// waits for one slice at most. Not an idle-priority scheduler task: those
  /// are refused while any animation runs, and a refused task asks the event
  /// loop again at once — a core spinning for as long as a spinner turns.
  void _carryScanOn() {
    final styler = _styler;
    if (_scanSlice != null || styler == null || styler.settled) return;
    _scanSlice = Timer(Duration.zero, () {
      _scanSlice = null;
      if (!mounted || !identical(_styler, styler)) return;
      styler.advance();
      _carryScanOn();
    });
  }

  BlockHeightMap _map() {
    // Read once for the whole map, not once a row: a map is built over every
    // row of the note, 2.76 M on the 246 MB one.
    final columns = _columnsPerLine;
    final row = _rowHeight;
    final buffer = widget.buffer;
    if (_folds.isEmpty) {
      return BlockHeightMap(
        count: lineCount,
        estimate: (line) =>
            _estimateOf(buffer.lineLengthAt(line), columns, row),
      );
    }
    return BlockHeightMap(
      count: _folds.rowCount(lineCount),
      estimate: _estimateRow,
    );
  }

  /// Row [row]'s height before a frame has drawn it: its line's.
  double _estimateRow(int row) => _estimate(_folds.lineOf(row));

  /// A line's height before a frame has drawn it: its character count over the
  /// width a line holds, which is the same shape the read view's estimator has
  /// and is corrected by the sliver's own measurement.
  double _estimate(int index) => _estimateOf(
    // The *buffer*, never the tokenizer: `HighlightDocument.lineAt`
    // materializes the line, so asking it for every line of a 10 000-line
    // note to fill the height map is a whole-note tokenize on every
    // keystroke. And the line's length, not the line: a line is cut out of
    // the text it was read from when it is asked for (`LineChunk`).
    widget.buffer.lineLengthAt(index),
    _columnsPerLine,
    _rowHeight,
  );

  /// The height of a line [length] long, [columns] to a row of [row].
  static double _estimateOf(int length, double columns, double row) =>
      (length == 0 ? 1 : (length / columns).ceil()) * row;

  /// Roughly how many monospace characters fit a line at this width and size.
  ///
  /// The pane's real width is not known here (the estimator is asked before a
  /// frame), so this is deliberately a *shape* and not a measurement: the
  /// sliver
  /// replaces every estimate with the line's own height as soon as it draws it,
  /// and only a jump made before that first frame can see the difference.
  double get _columnsPerLine {
    final size = _textScaler.scale(widget.theme.body.fontSize ?? 14);
    final advance = size * 0.6;
    if (advance <= 0) return 1;
    // The pane's real width once a frame has measured it; before that a guess,
    // which the sliver replaces with measured heights as it draws each line.
    final width = _paneWidth ?? 360;
    return (width - _gutter) / advance;
  }

  /// The width the text has, from the last frame that laid it out.
  double? _paneWidth;

  /// The text scale the lines are drawn at, from the last frame.
  TextScaler _textScaler = TextScaler.noScaling;

  /// One row's height as the lines are drawn: the theme's, at the note's
  /// text scale. The theme's own number is the unscaled one, and paging or
  /// estimating with it put the caret short of where a page ends at any size
  /// but 100 %.
  double get _rowHeight => _textScaler.scale(widget.theme.lineHeight);

  /// The space the note column puts on each side of the text.
  double _sideSpace = 0;

  /// The gutter's width this frame: the numbers, and with a note column the
  /// legacy `side + 16 - 5`, so the text starts exactly on the column's edge.
  double _gutter = 0;

  /// The field's inset on the left ([noteFieldInset]).
  static const double _fieldInset = noteFieldInset;

  /// The field's inset on the right: the column's edge, as the read view's
  /// ([noteTextInsets]).
  double get _rightInset => _sideSpace + NoteColumn.textInset;

  /// The field's inset on the left.
  double get _leftInset => _fieldInset;

  /// How wide the numbers are in the note's own face, plus the gap
  /// ([lineNumbersWidth]); kept while the digits, the face and the scale are.
  double _numbersWidth(TextScaler scaler) {
    if (!widget.showLineNumbers) return 0;
    final digits = widget.buffer.lineCount.toString().length;
    final style = widget.theme.body;
    final cached = _digits;
    if (cached != null &&
        cached.digits == digits &&
        cached.style == style &&
        cached.scaler == scaler) {
      return cached.width;
    }
    final width = lineNumbersWidth(widget.buffer.lineCount, style, scaler);
    _digits = (digits: digits, style: style, scaler: scaler, width: width);
    return width;
  }

  ({int digits, TextStyle style, TextScaler scaler, double width})? _digits;

  /// Measures the caret after the frame that laid its line out.
  void _scheduleCaret() {
    _semanticsTick.value++;
    _revealCaret();
    _restartBlink();
    _followCaret();
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

  /// The caret moved, or the text under it did: typewriter mode brings its
  /// row to the middle. Only while someone is writing here — the note or its
  /// find bar has the focus — so a note loading, or its place being put back,
  /// stays where it was put.
  void _followCaret() {
    if (!widget.typewriter) return;
    if (!_focus.hasFocus && !(widget.findMatches?.visible ?? false)) return;
    _typewriter.caretMoved();
  }

  /// Glides the note so the caret's row is in the middle of the pane; false
  /// while that row is not laid out yet, so the follow asks again next frame.
  bool _centerCaret() {
    final caret = caretRect;
    final box = _noteBox;
    if (caret == null || box == null || !_scroll.hasClients) return false;
    centerCaret(_scroll, box.globalToLocal(caret.center).dy);
    return true;
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
    // lines hear which of them holds the caret and which of its words, and the
    // toolbar hears which formats are on at it.
    final spot = _spotOf();
    _caretSpot.value = spot;
    _publishActive(spot);
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
      Rect.fromLTWH(0, 0, _caretWidth, 0),
    );
    _caretRect.value = Rect.fromLTWH(
      rect.dx,
      rect.dy,
      _caretWidth,
      paragraph.getFullHeightForCaret(position),
    );
    _sendGeometry();
  }

  /// How wide the caret is drawn.
  double get _caretWidth => widget.caretWidth ?? 1.5;

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
    var note = _shortcuts(
      Focus(
        focusNode: _focus,
        autofocus: widget.autofocus,
        onKeyEvent: _menuKey,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            _input.attach(viewId: View.of(context).viewId);
          } else {
            _input.detach();
            _hideTouch();
            hideContextMenu();
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            _paneWidth = constraints.maxWidth;
            _textScaler = MediaQuery.textScalerOf(context);
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
            // The text's left edge is the read view's ([noteTextInsets]): the
            // column's edge, or past the numbers — with no column too, where
            // it stood 5 px in and moved at every flip to the read pane.
            _gutter =
                noteTextInsets(
                  side: _sideSpace,
                  numbers: _numbersWidth(MediaQuery.textScalerOf(context)),
                ).left -
                _leftInset;
            final available =
                constraints.maxWidth - _leftInset - _rightInset - _gutter;
            // Typewriter mode: room for the last row to reach the middle,
            // under whatever the note ends with.
            final slack = widget.typewriter
                ? typewriterSlack(constraints.maxHeight)
                : 0.0;
            // The footnotes the read view ends the note with, which `live`
            // ends it with too: its definitions take no room where they
            // stand.
            final footnotes = widget.hideMarkers
                ? _styler?.footnotes ?? const <Footnote>[]
                : const <Footnote>[];
            return _mouseSelection(
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                // The keyboard is asked for on the *tap*: a drag the scroll
                // view wins is someone reading, not someone about to type.
                onTapUp: (details) {
                  // A task box is ticked where it is drawn, and a tick is
                  // neither a caret nor a reason to raise the keyboard; nor
                  // the first of a double click.
                  if (_toggleTaskAt(details.globalPosition)) {
                    _lastClick = null;
                    return;
                  }
                  _requestKeyboard();
                  if (details.kind != PointerDeviceKind.mouse &&
                      _touchTap(details.globalPosition)) {
                    return;
                  }
                  _tapUp(details.globalPosition);
                },
                // Selecting by touch: a long press takes the word under the
                // finger, moving it extends by words, and letting go brings
                // the toolbar up. A mouse has its drag instead.
                onLongPressStart: (details) {
                  if (_lastPointerKind == PointerDeviceKind.mouse) return;
                  _longPressAt(details.globalPosition, start: true);
                },
                onLongPressMoveUpdate: (details) {
                  if (_lastPointerKind == PointerDeviceKind.mouse) return;
                  _longPressAt(details.globalPosition, start: false);
                },
                onLongPressEnd: (details) {
                  if (_lastPointerKind == PointerDeviceKind.mouse) return;
                  _showTouch(toolbar: true);
                },
                // The text's own pointer over the note; the gutter keeps the
                // arrow (`_Line`).
                child: MouseRegion(
                  cursor: SystemMouseCursors.text,
                  child: CustomScrollView(
                    key: _scrollKey,
                    controller: _scroll,
                    physics: const ContentClampPhysics(),
                    slivers: <Widget>[
                      SliverPadding(
                        padding: EdgeInsets.only(
                          left: _leftInset,
                          right: _rightInset,
                          top: widget.padding.top,
                          // Typewriter mode: room for the last row to reach the
                          // middle.
                          bottom:
                              widget.padding.bottom +
                              (footnotes.isEmpty ? slack : 0),
                        ),
                        sliver: SliverMarkdownBlocks(
                          heights: _heights,
                          delegate: SliverChildBuilderDelegate(
                            (context, row) {
                              // A row is a line nobody folded away.
                              final index = _folds.lineOf(row);
                              final styled = _lineAt(index);
                              final block = _styler?.blockOf(index);
                              final quoted = widget.hideMarkers
                                  ? _quotes.of(index, block, widget.buffer)
                                  : null;
                              return _Line(
                                key: ValueKey<int>(index),
                                fold: _foldMarkOf(index),
                                onFold: () => toggleFold(index),
                                onFoldDown: () => _foldPress = true,
                                paragraphKey: _keyFor(index),
                                styled: styled,
                                shape: widget.hideMarkers
                                    ? LineShape.of(
                                        styled,
                                        block,
                                        index,
                                        quoted: quoted,
                                      )
                                    : LineShape.none,
                                pictures:
                                    widget.hideMarkers &&
                                        widget.embedResolver != null
                                    ? _styler?.picturesOf(index) ??
                                          const <LinePicture>[]
                                    : const <LinePicture>[],
                                embedResolver: widget.embedResolver,
                                formula:
                                    widget.hideMarkers &&
                                        widget.mathCache != null
                                    ? _formulaOf(index)
                                    : null,
                                mathCache: widget.mathCache,
                                tableRow: widget.hideMarkers
                                    ? _tables.rowOf(
                                        index,
                                        block,
                                        widget.buffer,
                                        tokensOf: (line) =>
                                            _lineAt(line).tokens,
                                        hiddenAtRest: (token) =>
                                            token.marker ||
                                            _isMarker(token.kind),
                                        styleOf: (token) => nestedTokenStyle(
                                          token,
                                          syntax,
                                          dark: widget.dark,
                                        ),
                                        theme: widget.theme,
                                        scaler: MediaQuery.textScalerOf(
                                          context,
                                        ),
                                      )
                                    : null,
                                definition:
                                    widget.hideMarkers &&
                                        block != null &&
                                        (_styler?.definesOnly(block) ?? false)
                                    ? (block.startLine, block.endLine)
                                    : null,
                                codeRuns: !widget.hideMarkers
                                    ? null
                                    : quoted != null
                                    ? _codeColors.ofQuoted(
                                        quoted,
                                        block!.startLine,
                                        widget.buffer,
                                        widget.theme.codeHighlight,
                                      )
                                    : _codeColors.of(
                                        index,
                                        block,
                                        widget.buffer,
                                        widget.theme.codeHighlight,
                                      ),
                                number: widget.showLineNumbers
                                    ? index + 1
                                    : null,
                                gutterWidth: _gutter,
                                // Past the numbers, only the gap the fold
                                // arrows live in is empty, and a list line
                                // has none.
                                margin:
                                    _leftInset +
                                    (widget.showLineNumbers
                                        ? _gutterGap
                                        : _gutter),
                                theme: widget.theme,
                                syntax: syntax,
                                dark: widget.dark,
                                hideMarkers: widget.hideMarkers,
                                selected: _selectionIn(index),
                                composing: _composingIn(index),
                                misspelled: _misspelledIn(index),
                                found: _foundIn(index),
                                misspelledColor: Theme.of(context)
                                    .colorScheme
                                    .error,
                                width: available,
                                index: index,
                                spot: _caretSpot,
                                caret: _caretRect,
                                caretOn: _caretOn,
                                rowColor: widget.typewriter
                                    ? typewriterLineColor(context)
                                    : null,
                              );
                            },
                            childCount: _folds.rowCount(
                              widget.buffer.lineCount,
                            ),
                          ),
                        ),
                      ),
                      if (footnotes.isNotEmpty)
                        SliverPadding(
                          // Where the read view puts its section: past the
                          // note's own padding, the text's edges its edges.
                          padding: EdgeInsets.only(
                            left: _leftInset + _gutter,
                            right: _rightInset,
                            top: widget.padding.top,
                            bottom: widget.padding.bottom + slack,
                          ),
                          sliver: footnoteSliver(
                            footnotes: footnotes,
                            theme: widget.theme,
                            parser: _footnoteParser,
                            mathCache: widget.mathCache ?? _footnoteMath,
                            scope: _styler?.scope,
                            onTap: _toDefinition,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    // The touch selection draws above everything, handles and toolbar alike,
    // and follows the note as it scrolls; the desktop's menu stays where the
    // click was.
    note = _semantics(note);
    return OverlayPortal(
      controller: _menuOverlay,
      overlayChildBuilder: _desktopMenu,
      child: OverlayPortal(
        controller: _touchOverlay,
        overlayChildBuilder: (context) => ListenableBuilder(
          listenable: _scroll,
          builder: (context, _) => _touchSelectionOverlay(),
        ),
        child: note,
      ),
    );
  }

  // ------------------------------------------------------------- semantics

  /// How much of the note, around the caret, a screen reader is given: the
  /// note itself can be megabytes, and the semantics tree is sent whole to
  /// the platform on every change.
  static const int _semanticsReach = 4000;

  /// [child] as the platform's accessibility sees it: one multiline text
  /// field, whose value is the note around the caret and whose selection is
  /// the note's, with the moves and the clipboard a screen reader asks for.
  ///
  /// The lines under it are excluded: each is a `Text`, and a reader would
  /// otherwise read the note twice — as a field, and as the lines inside it.
  Widget _semantics(Widget child) => ValueListenableBuilder<int>(
    valueListenable: _semanticsTick,
    child: ExcludeSemantics(child: child),
    builder: (context, _, child) {
      if (!SemanticsBinding.instance.semanticsEnabled) return child!;
      final buffer = widget.buffer;
      final selection = _selection.clampTo(buffer.length);
      final start = math.max(0, selection.start - _semanticsReach);
      final end = math.min(buffer.length, selection.end + _semanticsReach);
      int local(int offset) => (offset - start).clamp(0, end - start);
      return _NoteSemantics(
        value: buffer.substring(start, end),
        selection: TextSelection(
          baseOffset: local(selection.anchor),
          extentOffset: local(selection.extent),
        ),
        focused: _focus.hasFocus,
        onTap: _requestKeyboard,
        onSetSelection: (next) => select(
          SelectionModel(
            anchor: start + next.baseOffset,
            extent: start + next.extentOffset,
          ),
        ),
        onMove: moveCaretBy,
        onCopy: selection.isCollapsed ? null : () => unawaited(copySelection()),
        onCut: selection.isCollapsed ? null : () => unawaited(cutSelection()),
        onPaste: () => unawaited(paste()),
        child: child,
      );
    },
  );

  // ---------------------------------------------------------- context menu

  /// A right click at [global]: the caret goes there unless the click is on
  /// the selection — which is what the menu is about to act on — and the
  /// menu opens at the click.
  void _secondaryClick(Offset global) {
    final offset = offsetAt(global);
    final selection = _selection;
    final onSelection =
        offset != null &&
        !selection.isCollapsed &&
        offset >= selection.start &&
        offset <= selection.end;
    if (offset != null && !onSelection) placeCaret(offset);
    showContextMenu(global);
  }

  /// Opens the context menu at [global], or at the caret without one (the
  /// menu key, Shift+F10).
  void showContextMenu([Offset? global]) {
    final at = global ?? caretRect?.bottomLeft;
    if (at == null) return;
    _hideTouch();
    setState(() => _menuAt = at);
    _menuOverlay.show();
  }

  /// Whether the context menu is up.
  bool get isContextMenuShown => _menuAt != null;

  /// Closes the context menu.
  void hideContextMenu() {
    if (_menuAt == null) return;
    if (mounted) setState(() => _menuAt = null);
    _menuOverlay.hide();
  }

  /// The keys the menu answers while the note has the focus: Escape closes
  /// it (or the touch selection, or collapses a selection), and the menu key
  /// or Shift+F10 opens it at the caret. Everything else
  /// goes on to the note's shortcuts.
  KeyEventResult _menuKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (_menuAt != null) {
        hideContextMenu();
        return KeyEventResult.handled;
      }
      if (_touchHandles || _touchToolbar) {
        _hideTouch();
        return KeyEventResult.handled;
      }
      // A selection takes the first press, as it did in the legacy editor;
      // with nothing left to cancel the key goes on to the app (Zen mode).
      if (!_selection.isCollapsed) {
        placeCaret(_selection.extent);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final shift = HardwareKeyboard.instance.isShiftPressed;
    if (key == LogicalKeyboardKey.contextMenu ||
        (key == LogicalKeyboardKey.f10 && shift)) {
      showContextMenu();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// The desktop menu at the click, over a barrier that closes it.
  ///
  /// The barrier is the menu's own: one click anywhere else takes it down and
  /// does nothing else, which is how a context menu behaves everywhere — and
  /// what the legacy editor's menu learnt the hard way (a menu left up
  /// through every click after it, 2026-09-10).
  Widget _desktopMenu(BuildContext context) {
    final at = _menuAt;
    if (at == null) return const SizedBox.shrink();
    final overlay = Overlay.of(context).context.findRenderObject();
    final local = overlay is RenderBox && overlay.hasSize
        ? overlay.globalToLocal(at)
        : at;
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            key: const Key('editor-menu-barrier'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => hideContextMenu(),
            onSecondaryTapDown: (_) => hideContextMenu(),
          ),
        ),
        // Full-screen constraints on purpose: the toolbar places itself from
        // the anchors inside the box it is given.
        Positioned.fill(
          child: EditorContextMenu(
            anchors: TextSelectionToolbarAnchors(primaryAnchor: local),
            clipboard: _clipboardItems(hideContextMenu),
            formats: widget.formatMenu?.call() ?? const <FormatMenuEntry>[],
            extras: _spellingItems(hideContextMenu),
            onDismiss: hideContextMenu,
          ),
        ),
      ],
    );
  }

  /// Cut, copy, paste and select all, as they apply to the selection; each
  /// closes its menu through [dismiss] before it acts.
  ///
  /// Cut and copy of a caret are not offered: there is nothing to take.
  List<ContextMenuButtonItem> _clipboardItems(
    VoidCallback dismiss, {
    bool touch = false,
  }) {
    final selection = _selection.clampTo(widget.buffer.length);
    final collapsed = selection.isCollapsed;
    return <ContextMenuButtonItem>[
      if (!collapsed)
        ContextMenuButtonItem(
          type: ContextMenuButtonType.cut,
          onPressed: () {
            dismiss();
            unawaited(cutSelection());
          },
        ),
      if (!collapsed)
        ContextMenuButtonItem(
          type: ContextMenuButtonType.copy,
          onPressed: () {
            unawaited(copySelection());
            // By touch the handles stay, so the selection can be pasted over
            // or extended; the toolbar goes.
            if (touch) {
              _showTouch(toolbar: false);
            } else {
              dismiss();
            }
          },
        ),
      ContextMenuButtonItem(
        type: ContextMenuButtonType.paste,
        onPressed: () {
          dismiss();
          unawaited(paste());
        },
      ),
      if (selection.start > 0 || selection.end < widget.buffer.length)
        ContextMenuButtonItem(
          type: ContextMenuButtonType.selectAll,
          onPressed: () {
            selectAll();
            if (touch) {
              _showTouch(toolbar: true);
            } else {
              dismiss();
            }
          },
        ),
    ];
  }

  /// The spelling's entries for the word under the caret or the selection:
  /// what the checker suggests for it, then Add to dictionary.
  ///
  /// Only for a word the note underlines — the ranges come from the same
  /// call that draws the underline — and only within one line.
  List<ContextMenuButtonItem> _spellingItems(VoidCallback dismiss) {
    final spell = widget.spellCheck;
    if (spell == null) return const <ContextMenuButtonItem>[];
    final buffer = widget.buffer;
    final selection = _selection.clampTo(buffer.length);
    final line = buffer.lineOf(selection.start);
    if (line != buffer.lineOf(selection.end)) {
      return const <ContextMenuButtonItem>[];
    }
    final lineStart = buffer.offsetOfLine(line);
    final text = buffer.lineAt(line);
    final start = selection.start - lineStart;
    final end = selection.end - lineStart;
    final items = <ContextMenuButtonItem>[];
    for (final range in _spellRanges(line, text)) {
      if (start < range.start || end > range.end) continue;
      final word = text.substring(range.start, range.end);
      for (final suggestion in spell.suggestionsFor(word).take(_suggestions)) {
        items.add(
          ContextMenuButtonItem(
            label: suggestion,
            onPressed: () {
              dismiss();
              _replaceRange(
                lineStart + range.start,
                lineStart + range.end,
                suggestion,
              );
            },
          ),
        );
      }
      break;
    }
    final add = addToDictionaryItem(
      spell: spell,
      text: text,
      start: start,
      end: end,
      onDismiss: dismiss,
    );
    if (add != null) items.add(add);
    return items;
  }

  /// How many of the checker's suggestions the menu offers.
  static const int _suggestions = 4;

  /// The misspelled ranges of line [index], whose text is [text]: the ranges
  /// the checker finds outside what the tokenizer says is not prose (code,
  /// maths, links, markers).
  List<TextRange> _spellRanges(int index, String text) {
    final spell = widget.spellCheck;
    if (spell == null) return const <TextRange>[];
    return spell.rangesFor(
      index,
      text,
      skip: spellSkipRanges(_lineAt(index).tokens),
    );
  }

  // ------------------------------------------------------- touch selection

  /// The handles and toolbar for the selection as it stands.
  Widget _touchSelectionOverlay() {
    final selection = _selection.clampTo(widget.buffer.length);
    final collapsed = selection.isCollapsed;
    // The toolbar is the context menu's phone face: the same clipboard, the
    // toolbar's formats in its overflow, the spelling after them.
    return TouchSelectionOverlay(
      start: _caretRectAt(selection.start),
      end: _caretRectAt(selection.end),
      showHandles: _touchHandles && !collapsed,
      showToolbar: _touchToolbar,
      buttons: _clipboardItems(_hideTouch, touch: true),
      formats: _touchToolbar
          ? widget.formatMenu?.call() ?? const <FormatMenuEntry>[]
          : const <FormatMenuEntry>[],
      extras: _touchToolbar
          ? _spellingItems(_hideTouch)
          : const <ContextMenuButtonItem>[],
      onDismiss: _hideTouch,
      onHandleDrag: _dragHandle,
      onHandleDragEnd: () => _showTouch(toolbar: true),
    );
  }

  /// The caret rectangle at [offset] in global coordinates, from the line's
  /// own paragraph — or null when that line is not built.
  Rect? _caretRectAt(int offset) {
    final buffer = widget.buffer;
    final line = buffer.lineOf(offset.clamp(0, buffer.length));
    final paragraph = _paragraphAt(line);
    if (paragraph == null || !paragraph.attached || !paragraph.hasSize) {
      return null;
    }
    final local = (offset - buffer.offsetOfLine(line)).clamp(
      0,
      paragraph.text.toPlainText().length,
    );
    final position = TextPosition(offset: local);
    final at = paragraph.getOffsetForCaret(
      position,
      const Rect.fromLTWH(0, 0, 1.5, 0),
    );
    return Rect.fromLTWH(
      at.dx,
      at.dy,
      1.5,
      paragraph.getFullHeightForCaret(position),
    ).shift(paragraph.localToGlobal(Offset.zero));
  }

  /// Shows the touch selection: the handles for a range, and the toolbar when
  /// [toolbar] asks for it.
  void _showTouch({required bool toolbar}) {
    setState(() {
      _touchHandles = !_selection.isCollapsed;
      _touchToolbar = toolbar;
    });
    _touchOverlay.show();
  }

  /// Takes the touch selection's handles and toolbar away.
  void _hideTouch() {
    if (!_touchHandles && !_touchToolbar) return;
    if (mounted) {
      setState(() {
        _touchHandles = false;
        _touchToolbar = false;
      });
    }
    _touchOverlay.hide();
  }

  /// A finger's tap, when it means something to the touch selection: a tap
  /// on the caret brings the toolbar up (to paste), a tap anywhere else puts
  /// it and the handles away. True when the tap was taken.
  bool _touchTap(Offset global) {
    final last = _lastClick;
    final lastAt = _lastClickAt;
    if (last != null &&
        lastAt != null &&
        DateTime.now().difference(last) <= _clickWindow &&
        (global - lastAt).distance <= kDoubleTapSlop) {
      // The second tap of a double tap: the word, not the toolbar.
      _hideTouch();
      return false;
    }
    final offset = offsetAt(global);
    final selection = _selection;
    if (offset != null &&
        selection.isCollapsed &&
        offset == selection.extent &&
        !_touchToolbar) {
      _showTouch(toolbar: true);
      return true;
    }
    _hideTouch();
    return false;
  }

  /// The word the long press started on, held while the finger moves.
  (int, int)? _longPressWord;

  /// A long press at [global]: the word under it, or — while the finger moves
  /// — the selection from the first word to the word under it now.
  void _longPressAt(Offset global, {required bool start}) {
    final offset = offsetAt(global);
    if (offset == null) return;
    final buffer = widget.buffer;
    final line = buffer.lineOf(offset);
    final lineStart = buffer.offsetOfLine(line);
    final text = buffer.lineAt(line);
    final (from, to) = wordRangeAt(text, offset - lineStart);
    final wordStart = lineStart + math.min<int>(from, text.length);
    final wordEnd = lineStart + math.min<int>(to, text.length);
    final word = (wordStart, wordEnd);
    if (start) {
      _longPressWord = word;
      _requestKeyboard();
      select(SelectionModel(anchor: word.$1, extent: word.$2));
      _showTouch(toolbar: false);
      return;
    }
    final first = _longPressWord ?? word;
    final next = word.$2 >= first.$2
        ? SelectionModel(anchor: first.$1, extent: word.$2)
        : SelectionModel(anchor: first.$2, extent: word.$1);
    select(next);
    _showTouch(toolbar: false);
  }

  /// A handle dragged to [point]: that end of the selection follows the
  /// finger, through the same hit test a tap uses.
  void _dragHandle(SelectionHandle handle, Offset point) {
    final offset = offsetAt(point);
    if (offset == null) return;
    final selection = _selection;
    final next = handle == SelectionHandle.start
        ? SelectionModel(anchor: selection.end, extent: offset)
        : SelectionModel(anchor: selection.start, extent: offset);
    // An empty selection has no handles to hold: the dragged end stops one
    // character short of the other.
    if (next.isCollapsed) return;
    select(next);
    setState(() {
      _touchHandles = true;
      _touchToolbar = false;
    });
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
    required this.shape,
    required this.pictures,
    required this.embedResolver,
    required this.formula,
    required this.mathCache,
    required this.codeRuns,
    required this.definition,
    required this.tableRow,
    required this.styled,
    required this.number,
    required this.gutterWidth,
    required this.margin,
    required this.theme,
    required this.syntax,
    required this.dark,
    required this.hideMarkers,
    required this.selected,
    required this.composing,
    required this.width,
    required this.misspelled,
    required this.misspelledColor,
    required this.found,
    required this.rowColor,
    required this.fold,
    required this.onFold,
    required this.onFoldDown,
    required this.index,
    required this.spot,
    required this.caret,
    required this.caretOn,
    super.key,
  });

  /// The key of the line's own paragraph, so the surface can ask it for a caret
  /// offset or a caret rectangle.
  final GlobalKey paragraphKey;

  /// What `live` draws beside the line's text: a bullet, a number, a
  /// checkbox, a quote's bar, a rule.
  final LineShape shape;

  /// The pictures on the line, which `live` draws under it.
  final List<LinePicture> pictures;
  final Future<String?> Function(String target)? embedResolver;

  /// The display formula the line belongs to, which `live` draws in place of
  /// its lines while the caret is out of it.
  final LiveFormula? formula;
  final MathCache? mathCache;

  /// The colours of the line's code, as the read view colours its block;
  /// null for a line that is not code the read view colours.
  final List<CodeRun>? codeRuns;

  /// The lines `[start, end)` of the definitions this line is one of — link
  /// references or footnotes, which the read view does not draw where they
  /// stand — or null. Out of the caret's reach they take no room, as a
  /// typeset formula's lines do; the caret anywhere in them shows them all.
  final (int, int)? definition;

  /// How the line is laid out in its table, for a table's line in `live`:
  /// its cells on their columns, as the read view draws them.
  final LiveTableRow? tableRow;

  final StyledLine styled;
  final int? number;

  /// How wide the gutter is, computed from the numbers the note has.
  final double gutterWidth;

  /// How far left of the text's edge the line may draw: the field's inset
  /// and the gutter's empty room — where marks revealed wider than their
  /// column hang, rather than push the text right.
  final double margin;

  final MarkdownTheme theme;
  final SyntaxColors syntax;
  final bool dark;

  /// Whether the structural markers are drawn invisibly.
  final bool hideMarkers;

  /// The selected range, as offsets local to this line, or null.
  final (int, int)? selected;

  /// The range the IME is composing, as offsets local to this line, or null.
  final (int, int)? composing;

  /// The words the spelling flags, as offsets local to this line.
  final List<TextRange> misspelled;

  /// The colour their wavy underline is drawn in.
  final Color misspelledColor;

  /// The find bar's matches on this line, local, and whether each is the
  /// current one.
  final List<(int, int, bool)> found;

  /// The light behind the caret's row (typewriter mode), or null.
  final Color? rowColor;

  /// The fold arrow beside the line, if it has one.
  final _FoldMark fold;

  /// Folds or unfolds the line's section.
  final VoidCallback onFold;

  /// A pointer went down on the arrow (before the note hears it).
  final VoidCallback onFoldDown;

  /// The width the line's text wraps at (the pane minus the gutter).
  final double width;

  /// This line's index, to compare with [spot].
  final int index;

  /// Where the caret is: its line, and the run it sits in on that line.
  final ValueListenable<CaretSpot> spot;

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
          // The gutter is no text: the arrow, not the text's pointer.
          if (gutterWidth > 0)
            SizedBox(
              width: gutterWidth,
              child: MouseRegion(
                cursor: SystemMouseCursors.basic,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: _number() ?? const SizedBox.shrink()),
                    // The gap between the numbers and the text is where the
                    // fold arrows live, as in the legacy gutter.
                    SizedBox(width: _gutterGap, child: _foldArrow(context)),
                  ],
                ),
              ),
            ),
          Expanded(child: _caretBox(_listeningToFormulas())),
        ],
      ),
    );
  }

  /// The line as [spot] says to draw it, rebuilt when a formula the line
  /// waits for is typeset.
  Widget _listeningToFormulas() {
    Widget line() => ValueListenableBuilder<CaretSpot>(
      valueListenable: spot,
      builder: (context, at, _) => _content(context, at),
    );
    final cache = mathCache;
    if (!hideMarkers ||
        cache == null ||
        !styled.tokens.any((token) => token.kind == TokenKind.mathInline)) {
      return line();
    }
    // A new widget each time: the same instance handed back is one the
    // framework does not build again, and the typeset formula never landed.
    return ListenableBuilder(listenable: cache, builder: (_, _) => line());
  }

  /// The line with the caret at [at]: its text, and in `live` what stands in
  /// for the source it hides.
  Widget _content(BuildContext context, CaretSpot at) {
    final mine = at.line == index;
    final math = formula;
    // A formula is edited as a block: the caret anywhere in it shows all of
    // its source, and out of it none.
    final typeset =
        math != null &&
        mathCache != null &&
        (at.line < math.start || at.line >= math.end);
    final defined = definition;
    final table = tableRow;
    // The delimiter row takes no room, as the read view leaves it out,
    // unless the caret is on it.
    final folded =
        (defined != null && (at.line < defined.$1 || at.line >= defined.$2)) ||
        (table != null && table.delimiter && !mine);
    final inline = typeset || folded
        ? const <InlineFormula>[]
        : _inlineFormulas(run: mine ? (at.runStart, at.runEnd) : null);
    final concealed = <_Concealed>[
      if (typeset || folded)
        (0, styled.text.length, _hiddenMarker, whole: false),
      if (hideMarkers && !mine)
        for (final picture in pictures)
          (picture.start, picture.end, _hiddenMarker, whole: false),
      for (final formula in inline)
        (
          formula.start,
          formula.end,
          spacerStyleFor(formula, theme.lineHeight),
          whole: true,
        ),
      // A table's pipes, and the spaces round its cells' text, as wide as
      // it takes to put each cell's text on its column.
      if (table != null && !mine)
        for (final gap in table.gaps)
          (
            gap.start,
            gap.end,
            LiveTables.gapStyle(gap.width / (gap.end - gap.start)),
            whole: true,
          ),
    ];
    final indent = _indent(context, revealed: mine);
    Widget paragraph = Text.rich(
      _span(
        revealed: mine,
        run: mine ? (at.runStart, at.runEnd) : null,
        concealed: concealed,
      ),
      key: paragraphKey,
      // A typeset formula's lines take no room: the formula is drawn under
      // its first one instead. Nor do definitions out of the caret's reach:
      // the read view does not draw them there, and ends the note with the
      // footnotes, as `live` does.
      style: typeset || folded
          ? _lineStyle(revealed: mine).copyWith(fontSize: 0.01, height: 1)
          : _lineStyle(revealed: mine),
    );
    if (folded) return paragraph;
    if (inline.isNotEmpty) {
      paragraph = CustomPaint(
        foregroundPainter: InlineMathPainter(
          paragraph: paragraphKey,
          formulas: inline,
        ),
        child: paragraph,
      );
    }
    Widget line = Padding(
      padding: EdgeInsets.only(left: indent < 0 ? 0 : indent),
      // The spelling is painted over the paragraph rather than written into
      // its runs: a style has one decoration, and a wavy underline there took
      // a struck word's strike.
      child: CustomPaint(
        foregroundPainter: misspelled.isEmpty
            ? null
            : SquigglePainter(
                paragraph: paragraphKey,
                ranges: _unjudged(),
                color: misspelledColor,
              ),
        child: paragraph,
      ),
    );
    // Marks revealed wider than their column hang out to the left, into the
    // margin ([_indent]); the transform moves what hit tests see with it.
    if (indent < 0) {
      line = Transform.translate(offset: Offset(indent, 0), child: line);
    }
    if (table != null) {
      // A cell's padding above and below its text, and the grid behind.
      return CustomPaint(
        painter: LiveTableGridPainter(
          row: table,
          left: indent < 0 ? 0 : indent,
          color: theme.tableBorder,
          revealed: mine,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: theme.tableCellPadding.top),
          child: line,
        ),
      );
    }
    if (typeset) {
      if (index != math.start) return line;
      return liveFormulaUnder(
        line,
        cache: mathCache!,
        tex: math.tex,
        theme: theme,
        maxWidth: width,
      );
    }
    final resolver = embedResolver;
    final pictured = resolver == null || pictures.isEmpty
        ? line
        : livePicturesUnder(line, pictures, resolver);
    if (!hideMarkers || shape == LineShape.none) return pictured;
    // A row whose text is all hidden — a fence, a rule, a quote's empty
    // line — is laid out as nothing, while the list still gives it a row:
    // its part of the box, the rule across its middle and the quote's bar
    // were drawn on no height at all.
    final row = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.textScalerOf(context).scale(theme.lineHeight),
      ),
      child: pictured,
    );
    return CustomPaint(
      painter: LiveDecorationPainter(
        shape: shape,
        theme: theme,
        paragraph: paragraphKey,
        textLeft: indent,
        restingLeft: mine ? _indent(context) : indent,
        revealed: mine,
        color: theme.markerDim,
      ),
      child: row,
    );
  }

  /// The inline formulas `live` typesets on this line: all of them but the
  /// one in the caret's word, [run], whose source is shown as written.
  List<InlineFormula> _inlineFormulas({(int, int)? run}) {
    final cache = mathCache;
    if (!hideMarkers || cache == null) return const <InlineFormula>[];
    final sources = inlineFormulasOf(styled.text, styled.tokens);
    if (sources.isEmpty) return const <InlineFormula>[];
    return typesetInline(
      <InlineFormulaSource>[
        for (final source in sources)
          if (run == null || source.start < run.$1 || source.end > run.$2)
            source,
      ],
      cache,
      _lineStyle(revealed: false),
    );
  }

  /// The line's number, dimmed, or nothing.
  Widget? _number() => number == null
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
        );

  /// The fold arrow: pointing down over a section that can fold, right over
  /// one that is folded, nothing elsewhere.
  Widget? _foldArrow(BuildContext context) {
    if (fold == _FoldMark.none) return null;
    final row = MediaQuery.textScalerOf(context).scale(theme.lineHeight);
    return Listener(
      onPointerDown: (_) => onFoldDown(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: ValueKey<String>('fold-$index'),
          behavior: HitTestBehavior.opaque,
          onTap: onFold,
          child: SizedBox(
            height: row,
            child: Icon(
              fold == _FoldMark.closed
                  ? Icons.chevron_right
                  : Icons.expand_more,
              size: _gutterGap,
              color: theme.markerDim,
            ),
          ),
        ),
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
  Widget _caretBox(Widget child) => ValueListenableBuilder<CaretSpot>(
    valueListenable: spot,
    builder: (context, at, child) => CustomPaint(
      painter: at.line == index && rowColor != null
          ? _RowPainter(rect: caret, color: rowColor!)
          : null,
      foregroundPainter: at.line == index
          ? _CaretPainter(
              rect: caret,
              on: caretOn,
              shift: Offset(_indent(context, revealed: true), 0),
            )
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
  TextStyle _lineStyle({required bool revealed}) {
    // The line's own size is the *hiding*'s, not the reveal's: a heading is
    // drawn as a heading whether its hashes are shown or not, because what the
    // mode is about is reading the note with the syntax out of the way — and
    // revealing a marker is not a reason to restyle the line under the caret
    // (`docs/dev/unified-surface.md` §8.6.2, and the test that holds it).
    if (!hideMarkers) return theme.body;
    // A table's cells are set as the read view sets them.
    final table = tableRow;
    if (table != null) {
      return table.header ? theme.tableHeader : theme.tableCell;
    }
    // Code reads as the read view draws it: in monospace, fences and all.
    if (shape.code != null) return theme.code;
    // A heading inside a quote is set at its size, as the read view sets it.
    if (shape.heading > 0) return theme.heading(shape.heading);
    // Quoted prose reads as the read view draws it: in the quote's own style.
    if (shape.quoteDepth > 0) return theme.body.merge(theme.quote);
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
  /// A list item's text is set one column in per level, as the read view
  /// sets it, and a quote's a step in past each bar. The line's prefix —
  /// the written indent, the quote marks, the marker, the box and the
  /// spaces between them — is hidden whole ([_span]), so the text lands on
  /// the column and a wrapped item's next row starts under it, where it
  /// hung out to the left by the prefix's width. Live nested by the spaces
  /// the note was written with before: a sublist sat a few pixels in. A
  /// code block's rows are set a padding into its box, as the read view
  /// sets its code.
  ///
  /// It is pure layout: no offset moves, because the text underneath is
  /// still the note's own text, character for character.
  ///
  /// On the caret's line ([revealed]) the prefix is drawn as written, and
  /// it is set *into* the indent rather than before it: otherwise the text
  /// jumped right by the marks' width each time the caret came onto the
  /// line, and back when it left (device screenshot 2026-09-23, a list
  /// being typed). Marks wider than the column — a task's `- [ ] `, a
  /// `10. ` — hang out to the left of it, into the [margin]: negative.
  double _indent(BuildContext context, {bool revealed = false}) {
    if (!hideMarkers) return 0;
    final listed = shape.listed
        ? (shape.listDepth + 1) * theme.listIndentPerLevel
        : 0.0;
    final base =
        listed +
        shape.quoteDepth * theme.quoteIndentPerLevel +
        (shape.code == null ? 0 : theme.codePadding);
    if (base == 0 && _prefixEnd == 0) return 0;
    // Marks wider than their column hang into the margin, as far as there
    // is one: the text moves only by what is left over.
    return math.max<double>(
      -margin,
      base -
          (_textStart(context, revealed: revealed) -
              _glyphLeft(context, const <InlineSpan>[])),
    );
  }

  /// Whether the line is a heading's: its hashes and the spaces after them
  /// are its prefix, hidden whole, where the space was left behind and set
  /// the title a space's width in.
  bool get _heading =>
      styled.tokens.any((token) => token.kind == TokenKind.headingMarker);

  /// Where the line's prefix ends: past its leading spaces, its quote
  /// marks, its list marker, its task box, a heading's hashes and the spaces
  /// between them. Zero for a line that is none of these, whose leading
  /// spaces are its own.
  int get _prefixEnd {
    if (shape.code != null) {
      // A code line's prefix is its quote's marks and, in an indented
      // block, the block's indent: the spaces past them are the code's.
      final text = styled.text;
      final marks = shape.quoteDepth > 0
          ? BlockParser.quotePrefixLength(text, shape.quoteDepth)
          : 0;
      return shape.codeIndented
          ? marks + _codeIndentEnd(text.substring(marks))
          : marks;
    }
    if (!shape.listed && shape.quoteDepth == 0 && !_heading) return 0;
    final text = styled.text;
    var at = 0;
    var tokens = 0;
    while (true) {
      while (at < text.length &&
          (text.codeUnitAt(at) == 0x20 || text.codeUnitAt(at) == 0x09)) {
        at++;
      }
      while (tokens < styled.tokens.length &&
          styled.tokens[tokens].start < at) {
        tokens++;
      }
      if (tokens == styled.tokens.length) return at;
      final token = styled.tokens[tokens];
      if (token.start != at ||
          (token.kind != TokenKind.blockquote &&
              token.kind != TokenKind.listMarker &&
              token.kind != TokenKind.taskBox &&
              token.kind != TokenKind.headingMarker)) {
        return at;
      }
      at = token.end;
    }
  }

  /// Where an indented code line's indent ends: four columns in, a tab
  /// being all four, and no further — the spaces past them are the code's.
  static int _codeIndentEnd(String text) {
    var at = 0;
    var columns = 0;
    while (at < text.length && columns < 4) {
      final unit = text.codeUnitAt(at);
      if (unit == 0x09) {
        columns = 4;
      } else if (unit == 0x20) {
        columns++;
      } else {
        break;
      }
      at++;
    }
    return at;
  }

  /// Where the line's text is drawn from, past its prefix — hidden whole,
  /// or on the caret's line as written — in the paragraph's own shaping.
  ///
  /// Measured to the first glyph of the text, not to the end of the
  /// prefix: under an ambient letter spacing a paragraph's first glyph is
  /// drawn half a spacing in, and one after a hidden mark (which has none)
  /// is not, so a lazy line's text stood an eighth of a pixel right of its
  /// item's.
  double _textStart(BuildContext context, {required bool revealed}) {
    final end = _prefixEnd;
    final text = styled.text;
    final spans = <InlineSpan>[];
    if (!revealed) {
      if (end > 0) {
        spans.add(TextSpan(text: text.substring(0, end), style: _hiddenMarker));
      }
      return _glyphLeft(context, spans);
    }
    var at = 0;
    for (final token in styled.tokens) {
      if (token.start >= end) break;
      if (token.start > at) {
        spans.add(TextSpan(text: text.substring(at, token.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(token.start, token.end),
          style: nestedTokenStyle(token, syntax, dark: dark),
        ),
      );
      at = token.end;
    }
    if (at < end) spans.add(TextSpan(text: text.substring(at, end)));
    return _glyphLeft(context, spans);
  }

  /// Where a glyph set after [spans] is drawn, as the line's paragraph sets
  /// them: the paragraph's style is the line's over the ambient one, whose
  /// letter spacing moves a glyph as the paragraph moves it. The glyph is a
  /// probe — where it starts is the spacing's, not its own shape's.
  double _glyphLeft(BuildContext context, List<InlineSpan> spans) {
    final style = DefaultTextStyle.of(context).style
        .merge(_lineStyle(revealed: false));
    var length = 0;
    for (final span in spans) {
      length += (span as TextSpan).text?.length ?? 0;
    }
    final painter = TextPainter(
      text: TextSpan(
        children: <InlineSpan>[
          ...spans,
          const TextSpan(text: 'x'),
        ],
        style: style,
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: length, extentOffset: length + 1),
    );
    painter.dispose();
    return boxes.isEmpty ? 0 : boxes.first.left;
  }

  /// The line's tokens as styled runs. A token's override never changes the
  /// size
  /// or the height, so a line keeps the surface's metrics whatever it contains
  /// (`highlight_style.dart`).
  TextSpan _span({
    required bool revealed,
    (int, int)? run,
    List<_Concealed> concealed = const <_Concealed>[],
  }) {
    if (hideMarkers && shape.code != null && shape.quoteDepth > 0) {
      return _quotedCode(revealed: revealed, concealed: concealed);
    }
    final spans = <InlineSpan>[];
    // A hidden line's prefix is hidden whole, its spaces with its marks: the
    // text then starts at the indent, where its wrapped rows start too.
    final prefix = hideMarkers && !revealed ? _prefixEnd : 0;
    if (prefix > 0) _add(spans, 0, prefix, _hiddenMarker, concealed);
    var at = prefix;
    // The runs are the tokenizer's; the selection cuts them where it starts and
    // ends, so a highlighted range is the same text with a background.
    for (final token in styled.tokens) {
      if (token.end <= prefix) continue;
      if (token.start > at) {
        _add(spans, at, token.start, null, concealed);
      }
      // A token the prefix cuts into — an indented code line's, which is
      // the whole line — is drawn from where the prefix ends.
      final from = token.start < at ? at : token.start;
      // Code, in `live`, is coloured as the read view colours it: by its
      // block's language, or not at all.
      if (hideMarkers && token.kind == TokenKind.codeBlock) {
        final runs = codeRuns;
        if (runs == null) {
          _add(spans, from, token.end, null, concealed);
        } else {
          var cursor = from;
          for (final run in runs) {
            final start = run.start < cursor ? cursor : run.start;
            final end = run.end > token.end ? token.end : run.end;
            if (end <= start) continue;
            if (start > cursor) _add(spans, cursor, start, null, concealed);
            _add(spans, start, end, run.style, concealed);
            cursor = end;
          }
          if (cursor < token.end) {
            _add(spans, cursor, token.end, null, concealed);
          }
        }
        at = token.end;
        continue;
      }
      _add(
        spans,
        from,
        token.end,
        hidden(token, revealed: revealed, run: run)
            ? _hiddenMarker
            : nestedTokenStyle(token, syntax, dark: dark),
        concealed,
      );
      at = token.end;
    }
    if (at < styled.text.length) {
      _add(spans, at, styled.text.length, null, concealed);
    }
    return TextSpan(children: spans);
  }

  /// A line of a code block inside a quote.
  ///
  /// The styler reads a quote's lines as the quote's prose, so their tokens
  /// say nothing of the code in it: the quote's marks are drawn as its
  /// marks, and the rest as code — a fence hidden as a fence is, the code
  /// in its block's colours ([codeRuns], whose offsets start past the
  /// marks).
  TextSpan _quotedCode({
    required bool revealed,
    required List<_Concealed> concealed,
  }) {
    final text = styled.text;
    final spans = <InlineSpan>[];
    final marks = BlockParser.quotePrefixLength(text, shape.quoteDepth);
    var at = 0;
    if (!revealed) {
      final hidden = shape.codeFence ? text.length : _prefixEnd;
      _add(spans, 0, hidden, _hiddenMarker, concealed);
      at = hidden;
    } else {
      for (final token in styled.tokens) {
        if (token.start >= marks) break;
        if (token.start > at) _add(spans, at, token.start, null, concealed);
        final end = token.end > marks ? marks : token.end;
        _add(
          spans,
          token.start,
          end,
          nestedTokenStyle(token, syntax, dark: dark),
          concealed,
        );
        at = end;
      }
      if (at < marks) _add(spans, at, marks, null, concealed);
      at = marks;
    }
    for (final run in codeRuns ?? const <CodeRun>[]) {
      final start = marks + run.start < at ? at : marks + run.start;
      final end = marks + run.end > text.length ? text.length : marks + run.end;
      if (end <= start) continue;
      if (start > at) _add(spans, at, start, null, concealed);
      _add(spans, start, end, run.style, concealed);
      at = end;
    }
    if (at < text.length) _add(spans, at, text.length, null, concealed);
    return TextSpan(children: spans);
  }

  /// Whether [token]'s marker is hidden rather than drawn.
  ///
  /// Policy A of `docs/dev/unified-surface.md` §8.6.2 — the markers are hidden
  /// everywhere except where the writer is — with the per-word refinement D9
  /// asks for. The two granularities are the two things a marker can be the
  /// shape of:
  ///
  /// * **a structural mark** — a quote's `>`, a list's `-`, a heading's hashes,
  ///   a fence — is the shape of the *line*, so it is drawn when the caret is
  ///   anywhere on that line ([revealed]). A writer in a heading's title has to
  ///   see the hashes, or a heading is indistinguishable from a bold line.
  /// * **an inline mark** — a `**`, a backtick, a link's brackets — is the
  ///   shape of one *word*, so it is drawn only when it is inside the run the
  ///   caret is in ([run]). The run is the caret's non-whitespace run, markers
  ///   and all (`runAround`), so `**bold**` reveals *both* of its pairs and not
  ///   just the one the caret stands next to, and a plain word in a paragraph
  ///   full of links reveals none of them.
  ///
  /// The reveal is a **style**, never the text: the marker keeps its offset and
  /// its string, so the caret, the hit test and the selection know nothing
  /// about it, and the paragraph's cache key does not move when the caret does.
  bool hidden(Token token, {required bool revealed, (int, int)? run}) {
    if (!hideMarkers) return false;
    if (!token.marker && !_isMarker(token.kind)) return false;
    if (_isMarker(token.kind)) return !revealed;
    if (run == null) return true;
    return token.start < run.$1 || token.end > run.$2;
  }

  /// The misspelled words to underline: all of them but the one being
  /// composed, which is not judged yet — its underline is the IME's.
  List<TextRange> _unjudged() {
    final typing = composing;
    if (typing == null) return misspelled;
    return <TextRange>[
      for (final word in misspelled)
        if (word.end <= typing.$1 || word.start >= typing.$2) word,
    ];
  }

  /// Adds `[start, end)` to [spans], cut at the selection's and the composing
  /// range's edges: the selected part carries the highlight, the composed part
  /// the underline, and the rest keeps the run's own style.
  void _add(
    List<InlineSpan> spans,
    int start,
    int end,
    TextStyle? style, [
    List<_Concealed> concealed = const <_Concealed>[],
  ]) {
    final cuts = <int>{start, end};
    for (final range in <(int, int)?>[
      selected,
      composing,
      for (final match in found) (match.$1, match.$2),
      for (final hidden in concealed) (hidden.$1, hidden.$2),
    ]) {
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
      // What `live` draws instead of its source — a picture, a formula — is
      // hidden as a marker is: there, taking no room.
      var piece = style;
      var whole = false;
      for (final hidden in concealed) {
        if (inside((hidden.$1, hidden.$2))) {
          piece = hidden.$3;
          whole = hidden.whole;
        }
      }
      if (inside(selected)) {
        piece = (piece ?? const TextStyle()).copyWith(
          background: Paint()..color = _selectionColor,
        );
      }
      // A match is drawn over the selection: the current one *is* the
      // selection, and it has to read as the one the bar is on.
      for (final match in found) {
        if (from >= match.$1 && to <= match.$2) {
          piece = (piece ?? const TextStyle()).copyWith(
            background: Paint()
              ..color = match.$3 ? _currentMatchColor : _matchColor,
          );
        }
      }
      if (inside(composing)) {
        piece = (piece ?? const TextStyle()).copyWith(
          decoration: TextDecoration.underline,
        );
      }
      spans.add(
        TextSpan(
          text: whole
              ? unbrokenSource(to - from)
              : styled.text.substring(from, to),
          style: piece,
        ),
      );
    }
  }
}

/// A stretch of a line `live` draws something else in place of: its range,
/// the style that hides it, and whether it has to stay on one row — the room
/// a formula is painted over does.
typedef _Concealed = (int, int, TextStyle, {bool whole});

/// The note as a text field to the platform's accessibility: what
/// `RenderEditable` tells it about a `TextField`, which the `Semantics`
/// widget has no way to say — the selection inside the value above all.
final class _NoteSemantics extends SingleChildRenderObjectWidget {
  const new({
    required this.value,
    required this.selection,
    required this.focused,
    required this.onTap,
    required this.onSetSelection,
    required this.onMove,
    required this.onCopy,
    required this.onCut,
    required this.onPaste,
    super.child,
  });

  final String value;
  final TextSelection selection;
  final bool focused;
  final VoidCallback onTap;
  final ValueChanged<TextSelection> onSetSelection;
  final void Function(CaretMotion motion, {required bool extend}) onMove;
  final VoidCallback? onCopy;
  final VoidCallback? onCut;
  final VoidCallback onPaste;

  @override
  _RenderNoteSemantics createRenderObject(BuildContext context) =>
      _RenderNoteSemantics(this);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderNoteSemantics renderObject,
  ) {
    renderObject.semantics = this;
  }
}

final class _RenderNoteSemantics extends RenderProxyBox {
  new(this._semantics);

  _NoteSemantics _semantics;

  // A setter the widget pairs with, as every render object's are.
  // ignore: avoid_setters_without_getters
  set semantics(_NoteSemantics value) {
    _semantics = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    final note = _semantics;
    MoveCursorHandler move(CaretMotion motion) =>
        (extend) => note.onMove(motion, extend: extend);
    // Named first: a closure written in the cascade would swallow the rest of
    // it into its body.
    final characterRight = move(CaretMotion.characterRight);
    final characterLeft = move(CaretMotion.characterLeft);
    final wordRight = move(CaretMotion.wordRight);
    final wordLeft = move(CaretMotion.wordLeft);
    config
      ..isSemanticBoundary = true
      ..isTextField = true
      ..isMultiline = true
      ..isFocused = note.focused
      ..isEnabled = true
      ..value = note.value
      // The note is written left to right, as every line of it is laid out.
      ..textDirection = TextDirection.ltr
      ..textSelection = note.selection
      ..onTap = note.onTap
      ..onSetSelection = note.onSetSelection
      ..onPaste = note.onPaste
      ..onMoveCursorForwardByCharacter = characterRight
      ..onMoveCursorBackwardByCharacter = characterLeft
      ..onMoveCursorForwardByWord = wordRight
      ..onMoveCursorBackwardByWord = wordLeft;
    if (note.onCopy != null) config.onCopy = note.onCopy;
    if (note.onCut != null) config.onCut = note.onCut;
  }
}

/// What a line's gutter shows for folding.
enum _FoldMark {
  /// Nothing: not a heading, or nothing under it to fold.
  none,

  /// A section that can fold.
  open,

  /// A folded section.
  closed,
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
  // Spacing is set in pixels, not in the size: an ambient letter spacing
  // gave each hidden mark a quarter of a pixel back.
  letterSpacing: 0,
  wordSpacing: 0,
);

/// Where the caret is, for the lines that draw it and the reveal that follows
/// it: its line, and the run of non-whitespace it sits in on that line.
///
/// One value rather than a line and a word kept apart, because the property
/// that matters is *equality*: a caret that moves inside a run produces an
/// equal [CaretSpot], so no line rebuilds, and one that crosses a run boundary
/// produces a different one, so exactly the two lines involved do
/// (`docs/dev/unified-surface.md` §8.6.2's budget).
@immutable
final class CaretSpot {
  /// The caret's line and its run on it.
  const new(this.line, this.runStart, this.runEnd);

  /// The line the caret is on, or -1 for a caret the note cannot hold.
  final int line;

  /// Where the run of non-whitespace the caret is in starts.
  final int runStart;

  /// Where that run ends, exclusive.
  final int runEnd;

  @override
  bool operator ==(Object other) =>
      other is CaretSpot &&
      other.line == line &&
      other.runStart == runStart &&
      other.runEnd == runEnd;

  @override
  int get hashCode => Object.hash(line, runStart, runEnd);

  @override
  String toString() => 'CaretSpot($line, $runStart..$runEnd)';
}

/// Whether [kind] is a *structural* marker: a mark that is the shape of the
/// line rather than of a word.
///
/// A quote's `>`, a list's `-`, a heading's hashes, a fence and its language,
/// a task's box — the marks `SourceStyler._structure` lays down at the start of
/// a line. They are revealed with the line. Everything else the surface hides
/// is an *inline* mark, carried by `Token.marker` and revealed with the
/// caret's own run (`hidden`).
bool _isMarker(TokenKind kind) => switch (kind) {
  TokenKind.headingMarker ||
  TokenKind.listMarker ||
  TokenKind.blockquote ||
  TokenKind.codeFence ||
  TokenKind.codeLanguage ||
  // A thematic break is all marker: `live` draws its rule instead.
  TokenKind.horizontalRule ||
  TokenKind.taskBox => true,
  _ => false,
};

/// Lights the caret's row across the line, behind the text: typewriter mode's
/// row being written. The row is the caret's own — its top and its height —
/// so a wrapped paragraph lights the row the caret is on, not the paragraph.
final class _RowPainter extends CustomPainter {
  new({required this.rect, required this.color}) : super(repaint: rect);

  final ValueListenable<Rect?> rect;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final value = rect.value;
    if (value == null) return;
    canvas.drawRect(
      Rect.fromLTRB(0, value.top, size.width, value.bottom),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_RowPainter oldDelegate) =>
      oldDelegate.rect != rect || oldDelegate.color != color;
}

/// Draws the caret: a thin vertical bar at the rectangle the line's own layout
/// answered with.
///
/// It reads the rectangle and the blink at *paint* time and repaints when
/// either changes, so neither rebuilds the line it is drawn over.
final class _CaretPainter extends CustomPainter {
  new({required this.rect, required this.on, this.shift = Offset.zero})
    : super(repaint: Listenable.merge(<Listenable>[rect, on]));

  /// The caret, in its line's *paragraph's* coordinates.
  final ValueListenable<Rect?> rect;
  final ValueListenable<bool> on;

  /// Where the paragraph sits in the box this paints over: `live` indents a
  /// list item or a quote, and the caret drawn without it stood that far to
  /// the left of the character it was at.
  final Offset shift;

  @override
  void paint(Canvas canvas, Size size) {
    final value = rect.value;
    if (!on.value || value == null) return;
    canvas.drawRect(
      value.shift(shift),
      Paint()..color = const Color(0xFF7AA2F7),
    );
  }

  @override
  bool shouldRepaint(_CaretPainter oldDelegate) =>
      oldDelegate.rect != rect ||
      oldDelegate.on != on ||
      oldDelegate.shift != shift;
}
