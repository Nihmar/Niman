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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/frame_cost.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/editor/context_menu_items.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/editor/typewriter_scroll.dart';
import 'package:niman/src/links/dead_links.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/buffer_block_anchors.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/caret_spot.dart';
import 'package:niman/src/markdown/edit/edit_history.dart';
import 'package:niman/src/markdown/edit/line_prefix.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/edit/source_find.dart';
import 'package:niman/src/markdown/edit/source_input.dart';
import 'package:niman/src/markdown/edit/source_shortcuts.dart';
import 'package:niman/src/markdown/live_inlines.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/content_clamp_physics.dart';
import 'package:niman/src/markdown/render/fence_band_painter.dart';
import 'package:niman/src/markdown/render/focus_return.dart';
import 'package:niman/src/markdown/render/footnote_list.dart';
import 'package:niman/src/markdown/render/link_run.dart';
import 'package:niman/src/markdown/render/live_blocks.dart';
import 'package:niman/src/markdown/render/live_code_colors.dart';
import 'package:niman/src/markdown/render/live_decorations.dart';
import 'package:niman/src/markdown/render/live_hosts.dart';
import 'package:niman/src/markdown/render/live_quote_content.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/scroll_anchor.dart';
import 'package:niman/src/markdown/render/scrollbar_strip.dart';
import 'package:niman/src/markdown/render/source_caret.dart';
import 'package:niman/src/markdown/render/source_caret_blink.dart';
import 'package:niman/src/markdown/render/source_caret_motion.dart';
import 'package:niman/src/markdown/render/source_caret_rect.dart';
import 'package:niman/src/markdown/render/source_caret_reveal.dart';
import 'package:niman/src/markdown/render/source_code_copies.dart';
import 'package:niman/src/markdown/render/source_context_menu.dart';
import 'package:niman/src/markdown/render/source_folds.dart';
import 'package:niman/src/markdown/render/source_geometry.dart';
import 'package:niman/src/markdown/render/source_hit_test.dart';
import 'package:niman/src/markdown/render/source_line.dart';
import 'package:niman/src/markdown/render/source_line_marks.dart';
import 'package:niman/src/markdown/render/source_live_lines.dart';
import 'package:niman/src/markdown/render/source_menu_keys.dart';
import 'package:niman/src/markdown/render/source_metrics.dart';
import 'package:niman/src/markdown/render/source_overlays.dart';
import 'package:niman/src/markdown/render/source_paragraphs.dart';
import 'package:niman/src/markdown/render/source_pieces.dart';
import 'package:niman/src/markdown/render/source_pointer.dart';
import 'package:niman/src/markdown/render/source_row_slivers.dart';
import 'package:niman/src/markdown/render/source_rows.dart';
import 'package:niman/src/markdown/render/source_sections.dart';
import 'package:niman/src/markdown/render/source_semantics.dart';
import 'package:niman/src/markdown/render/source_styling.dart';
import 'package:niman/src/markdown/render/source_table_hover.dart';
import 'package:niman/src/markdown/render/source_table_keys.dart';
import 'package:niman/src/markdown/render/source_task_boxes.dart';
import 'package:niman/src/markdown/render/source_template_hint.dart';
import 'package:niman/src/markdown/render/source_touch.dart';
import 'package:niman/src/markdown/render/source_typing.dart';
import 'package:niman/src/markdown/render/todo_block_scope.dart';
import 'package:niman/src/markdown/render/wikilink_suggest.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';
import 'package:niman/src/markdown/source_styler.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/templates/check_state.dart';
import 'package:niman/src/templates/template_commands.dart';
import 'package:niman/src/ui/window_visibility.dart';

export 'package:niman/src/markdown/render/source_pointer.dart'
    show SourceLinkHover;

/// A link the writer Ctrl+clicked: its token's kind (a wikilink or a Markdown
/// link), its text as written, brackets and all, and — for a Markdown link —
/// the target its parse resolved (a reference link's, too), or null for a
/// wikilink.
typedef SourceLinkTap = void Function(TokenKind kind, String raw, String? href);

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
    this.onStage = true,
    this.syntax,
    this.dark = false,
    this.formatMenu,
    this.editorMenu,
    this.spellCheck,
    this.templateCheck,
    this.findMatches,
    this.onOpenLink,
    this.activeItems,
    this.mathCache,
    this.embedResolver,
    this.caretWidth,
    this.typewriter = false,
    this.cascadeChecklist = true,
    this.lineTokens,
    this.templateCommands = false,
    this.autofocus = false,
    this.wikilinkSuggester,
    this.notePath,
    this.blockAnchors,
    this.deadLinks,
    this.onLinkHover,
    this.onPaste,
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

  /// Whether this pane is the one on stage.
  ///
  /// Off stage the view keeps everything it has — the parent keeps it
  /// mounted for that — but its overlay children must not paint: an
  /// `Offstage` ancestor hides the pane's own painting, not an
  /// `OverlayPortal`'s child, which lives in the app's overlay and would
  /// draw the code blocks' copy buttons over the pane that is on stage.
  final bool onStage;

  /// The token palette; null takes it from the ambient theme.
  final SyntaxColors? syntax;

  /// Whether bold is drawn a step lighter (the palette's own rule).
  final bool dark;

  /// The toolbar's formatting actions, for the context menu (#174); null
  /// offers the clipboard alone.
  final FormatMenuBuilder? formatMenu;

  /// The context menu grouped by what the writer is doing (#260): the
  /// links, then Format, Paragraph and Insert. With it the menu shows this
  /// rather than [formatMenu], and the clipboard last.
  final ContextMenuPart Function()? editorMenu;

  /// The note's spelling: the words it underlines, and the context menu's
  /// suggestions and Add to dictionary. Null checks nothing.
  final EditorSpellCheck? spellCheck;

  /// The note's template syntax check (T-TPL-09): the problems it marks with
  /// a wavy underline and offers to fix. Only read when [templateCommands] is
  /// set — a note that is not a template is checked by nothing.
  final TemplateCheck? templateCheck;

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

  /// Whether ticking a checklist item ticks the tasks nested under it
  /// (#326).
  final bool cascadeChecklist;

  /// The colours of a line of a file that is not Markdown, by its text —
  /// a todo.txt's (`todoTxtTokens`) — or null for the Markdown engine's.
  final List<Token> Function(String line)? lineTokens;

  /// Whether the note is a template, whose commands (`{{date}}`) are
  /// coloured apart from the Markdown they stand in: a note of the
  /// library's template folder. Elsewhere a `{{…}}` is text like any.
  final bool templateCommands;

  /// Whether the note takes the focus — and the keyboard — as it opens (the
  /// keyboard-on-open setting, and a template's `{{cursor}}`).
  final bool autofocus;

  /// The library the wikilink suggester panel reads (#475): the notes, aliases
  /// and headings, and the books' place forms. Null (a surface with no
  /// library) draws no panel.
  final WikilinkSuggester? wikilinkSuggester;

  /// The note's library-relative path, or null for a note outside a library:
  /// what the wikilink panel tells the note's own headings and blocks from
  /// the rest of the library's when it completes a link (#845).
  final String? notePath;

  /// The note's block anchors (#869), when its owner already reads them for
  /// the same buffer: the panel then shares that walk instead of making its
  /// own. Null reads them here.
  final BufferBlockAnchors? blockAnchors;

  /// The links of the note that name nothing (#847), resolved apart from the
  /// drawing and handed in as they arrive: drawn in the muted colour of a
  /// link that is not there yet. Null draws every link as a live one.
  final ValueListenable<DeadLinks>? deadLinks;

  /// Told when the pointer comes onto a link with the opening modifier held
  /// (Ctrl, ⌘ on a Mac), and with null when it leaves it or the modifier goes
  /// up: what the link preview opens its card from (#846). Null (the
  /// default, and every touch screen) reports nothing.
  final void Function(SourceLinkHover? hover)? onLinkHover;

  /// Asked first by every paste — Ctrl/⌘+V, the context menu's Paste, the
  /// accessibility action: true when it took the clipboard itself (files to
  /// attach, cells that become a table, #1248, #1249), false to let the view
  /// paste the clipboard's text as it is. Null pastes text.
  final Future<bool> Function()? onPaste;

  @override
  State<MarkdownSourceView> createState() => MarkdownSourceViewState();
}

/// The source view's state, so a caller can ask where the caret is.
final class MarkdownSourceViewState extends State<MarkdownSourceView> {
  /// The colours: read in place or in the background, moved along by
  /// every edit, and their scan carried on when an edit left it owed.
  late final SourceStyling _styling = SourceStyling(
    buffer: () => widget.buffer,
    mounted: () => mounted,
    readsInBackground: readsInBackground,
    progressiveLines: () => progressiveLines,
    landed: () {
      setState(() {});
      // The colours landing is also the formats landing: until they are
      // read, the caret's line has no tokens and the toolbar would show
      // every button dark on a note whose syntax the writer is inside.
      _caret.publishActive(_caret.spot.value);
      // And it is the caret's line landing: a heading, or a formula, is
      // drawn at another height than the plain line the caret was measured
      // over. The reading came in outside any edit, so nothing else asks
      // for the caret to be measured again.
      _measureCaretAfterFrame();
    },
    settled: () {
      // A layout that found the scan owed drew the `columns` blocks
      // stacked (#729): settled, it lays them out side by side.
      if (_rows.runsOwed) setState(() {});
    },
  );

  /// The colours ([SourceStyling.styler]): null while a long note is read
  /// in the background, its lines drawn plain until it lands.
  SourceStyler? get _styler => _styling.styler;

  /// The rows the note is drawn in and the heights they are placed with:
  /// the lines nobody folded away, a side-by-side block's in its opener's
  /// row (#729).
  late final SourceRows _rows = SourceRows(
    buffer: () => widget.buffer,
    live: () => widget.hideMarkers,
    styler: () => _styler,
    folds: _folds,
    hosts: _hosts,
    sectionEnd: _sections.endOf,
    em: () => _metrics.em,
    rowHeight: () => _metrics.rowHeight,
    gap: () => _metrics.gap,
    band: () => _metrics.band,
    columnsPerLine: () => _metrics.columnsPerLine,
    itemsIndent: _metrics.itemsIndent,
  );

  /// The heights the sliver places the rows with ([SourceRows.heights]).
  BlockHeightMap get _heights => _rows.heights;

  /// How many lines the rows' estimates asked about, for the test that holds
  /// a note with a side-by-side block (#729) to the chunks a frame reaches.
  @visibleForTesting
  int get lineEstimates => _rows.lineEstimates;

  /// Keeps the height map at the buffer's line count, after [edit]
  /// ([SourceRows.sync]), and the revision this view has seen with it.
  void _syncLines([SourceEdit? edit]) {
    _seenRevision = widget.buffer.revision;
    _rows.sync(edit);
  }

  /// The colours of the code blocks `live` draws, highlighted a block at a
  /// time as the read view highlights them.
  final LiveCodeColors _codeColors = LiveCodeColors();

  /// A quote's content read again as blocks, so `live` draws a quote's lines
  /// as the blocks they are inside it, as the read view does.
  final LiveQuoteContent _quotes = LiveQuoteContent();

  /// The task boxes `live` draws: the one under a point, and its tick.
  late final SourceTaskBoxes _taskBoxes = SourceTaskBoxes(
    buffer: () => widget.buffer,
    live: () => widget.hideMarkers,
    caretLine: () => _caret.spot.value.line,
    paragraphs: _paragraphs,
    lineAt: _lineAt,
    blockOf: (line) => _styler?.blockOf(line),
    blocks: () => _styler?.blocks,
    quotes: _quotes,
    theme: () => widget.theme,
    cascade: () => widget.cascadeChecklist,
    selection: () => _selection,
    seal: () => _history.seal(),
    replace: (start, end, text, caret) =>
        _replaceRange(start, end, text, caret: caret, follow: false),
  );

  /// What the footnotes `live` ends the note with are parsed with.
  final ReadParser _footnoteParser = ReadParser();

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
    _applySelection(
      SelectionModel.at(offset),
      rebuild: true,
      reveal: true,
      suggest: false,
    );
  }

  /// The folded heading sections; the rows are the lines they leave.
  final SourceFolds _folds = SourceFolds();

  /// Where the sections those folds hide end, kept for the buffer's
  /// revision: the tokenizer's question, as far as it has been asked.
  late final SourceSections _sections = SourceSections(
    buffer: () => widget.buffer,
    blockOf: (line) => blockAt?.call(line),
    tokensOf: (line) => _lineAt(line).tokens,
  );

  /// The keyboard, wired to the buffer this view draws.
  late SourceInput _input;

  late ScrollController _scroll;
  bool _ownsScroll = false;
  late FocusNode _focus;
  bool _ownsFocus = false;

  /// The caret kept in view: after an edit or a jump, and when the
  /// keyboard comes up over it (#728).
  late final SourceCaretReveal _reveal = SourceCaretReveal(
    scroll: () => _scroll,
    mounted: () => mounted,
    caretLine: () => _caretLineIndex,
    anchorLine: () => widget.buffer.lineOf(_selection.anchor),
    rowOf: _folds.rowOf,
    lineBounds: _geometry.lineBounds,
    bottomInsetNow: () => View.of(context).viewInsets.bottom,
    typing: () => _focus.hasFocus && _input.isAttached,
  );

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

  /// The footnote labels the note cites or defines, as the scan behind the
  /// colours has them: what a new footnote's number must pass.
  Iterable<String> get footnoteLabels {
    final styler = _styler;
    if (styler == null) return const <String>[];
    return {
      ...styler.scope.footnoteCounts.keys,
      for (final footnote in styler.footnotes) footnote.label,
    };
  }

  /// The note's headings, as the scan behind the colours has them, or null
  /// while there is no scan yet (a long note reads in the background, see
  /// [SourceStyling.restyle]).
  ///
  /// The outline the note view publishes, from an answer it already holds.
  List<OutlineEntry>? get headings => _styler?.headings;

  /// Whether the note's blocks are all current: false while an edit that
  /// changed the rest of the note is still being scanned on, a slice at a
  /// time, and [headings] waits for it — and while a long note is still
  /// being read in the background, when there are no blocks at all.
  bool get scanSettled => _styler?.settled ?? false;

  /// How many lines the scan behind the colours has read, for the test that
  /// holds a tap on a task box to the work the tap may do: a tap on a note
  /// whose scan is owed must not finish it ([SourceStyler.scannedLines]).
  @visibleForTesting
  int get scanProgress => _styler?.scannedLines ?? 0;

  /// The note's tags and links as of the buffer's revision, when the scan
  /// behind the colours keeps them ([SourceStyler.references]): a long note's
  /// save hands them to the index, which then does not read the note for
  /// them. Null otherwise.
  NoteReferences? references() => _styler?.references();

  /// The note's blocks, as the scan behind the colours has them, or null
  /// while there is no scan yet.
  ///
  /// What the shell asks when it needs to know whether the note holds
  /// something the scan already found — a list to count, so far. O(blocks):
  /// [SourceStyler.blocks] copies the list.
  List<Block>? get blocks => _styler?.blocks;

  /// The block holding a line, as the scan behind the colours has it —
  /// scanned up to the line when the scan still owes it — or null while
  /// there is no scan. O(log blocks) a line, never the note read.
  Block? Function(int line)? get blockAt => _styler?.blockOf;

  /// The note's blocks and definitions as of [MarkdownSourceView.buffer]'s
  /// revision, with what changed since the last hand-over, or null while
  /// there is no whole, current scan of it ([SourceStyler.handOver]): what
  /// the read pane takes instead of scanning the note again.
  DocumentScan? handOver() => _styler?.handOver();

  /// The paragraph of each line a frame has built, and of each fragment of
  /// a wrapped table row: what a tap asks where an offset is, and the caret
  /// asks for its rectangle.
  final SourceParagraphs _paragraphs = SourceParagraphs();

  /// Where a point over the note lands in it: asked of the drawn lines,
  /// and of the height map for a point no drawn line is under.
  late final SourceHitTest _hits = SourceHitTest(
    buffer: () => widget.buffer,
    hosts: _hosts,
    noteBox: () => _noteBox,
    scroll: () => _scroll,
    heights: () => _heights,
    paragraphs: _paragraphs,
    pieces: _pieces,
    geometry: _geometry,
  );

  /// What the last frame laid the note out with — the pane's width, the
  /// text's scale, the gutter, the text's width — and the lengths counted
  /// from them.
  late final SourceMetrics _metrics = SourceMetrics(
    theme: () => widget.theme,
    column: () => widget.column,
    numberedLines: () =>
        widget.showLineNumbers ? widget.buffer.lineCount : null,
  );

  /// The pieces a line is drawn in, and a table's rows as `live` lays them
  /// out: what the caret, a tap and the table's grid ask.
  late final SourcePieces _pieces = SourcePieces(
    buffer: () => widget.buffer,
    live: () => widget.hideMarkers,
    styler: () => _styler,
    caretSpot: () => _caret.spot.value,
    paragraphs: _paragraphs,
    tokensOf: (line) => _lineAt(line).tokens,
    syntax: () => _metrics.syntax,
    dark: () => widget.dark,
    theme: () => widget.theme,
    scaler: () => _metrics.scaler,
    widthOf: _widthOf,
  );

  /// What a line is marked with beyond its colours: the selection, the
  /// composing range, the spelling, the dead links, the find bar's matches.
  late final SourceLineMarks _marks = SourceLineMarks(
    buffer: () => widget.buffer,
    selection: () => _selection,
    composing: () => _input.composing,
    spellCheck: () => widget.spellCheck,
    tokensAt: _tokensAt,
    deadLinks: () => widget.deadLinks,
    linkHrefAt: (index, start) => _styler?.linkHrefAt(index, start),
    findMatches: () => widget.findMatches,
  );

  /// The caret as the lines and the toolbar are told it: its spot, its
  /// rectangle and its piece's shift, measured off its line's layout.
  late final SourceCaret _caret = SourceCaret(
    buffer: () => widget.buffer,
    selection: () => _selection,
    mounted: () => mounted,
    fragmentAt: (line, local) => _pieces.fragmentAt(line, local),
    width: () => _caretWidth,
    caretOnLine: (line) => _typing.brackets.caretOnLine(line),
    activeItems: () => widget.activeItems,
    tokensOf: tokensOf,
    measured: _sendGeometry,
  );

  /// The line the caret sits on, or -1.
  int get _caretLineIndex => _caret.line;

  /// Whether the caret is drawn, and the blink that turns it on and off:
  /// only the focused note's, in a window someone can see (#512).
  late final SourceCaretBlink _blink = SourceCaretBlink(
    focused: () => _focus.hasFocus,
  );

  /// The selection by touch (#291): its handles, its toolbar, and the
  /// gestures that bring them. Listened to from [initState]: the note
  /// rebuilds when they come or go.
  late final SourceTouchSelection _touch = SourceTouchSelection(
    buffer: () => widget.buffer,
    selection: () => _selection,
    select: select,
    offsetAt: offsetAt,
    requestKeyboard: _requestKeyboard,
    caretRectAt: _caretRectAt,
    followsLastClick: (global) =>
        _pointer.followsLastClick(global, DateTime.now()),
    clipboardItems: (dismiss) => _menu.clipboardItems(dismiss, touch: true),
    spellingItems: (dismiss) => _menu.spellingItems(dismiss),
    formats: _menuFormats,
    structure: () => widget.editorMenu?.call(),
    table: () => _tableKeys.commands()?.menu(),
  );

  /// The touch selection's handles or toolbar came or went.
  void _onTouchChanged() => setState(() {});

  /// The mouse's press, drag and hover over the note, the taps a click
  /// counts, and the cursor it shows.
  late final SourcePointer _pointer = SourcePointer(
    buffer: () => widget.buffer,
    selection: () => _selection,
    live: () => widget.hideMarkers,
    mounted: () => mounted,
    touch: _touch,
    offsetAt: offsetAt,
    onScrollbar: _onScrollbar,
    hoverTable: _handles.hoverAt,
    leaveTable: _handles.leave,
    taskBoxAt: (global) => _taskBoxes.at(global) != null,
    overTaskBox: _taskBoxes.over,
    toggleTaskAt: _taskBoxes.toggleAt,
    linkAt: linkAt,
    openLink: () => widget.onOpenLink,
    linkHover: () => widget.onLinkHover,
    requestKeyboard: _requestKeyboard,
    secondaryClick: _secondaryClick,
    placeCaret: placeCaret,
    extendTo: (offset) => _motion.moveTo(offset, extend: true),
    select: _select,
    inCell: (offset) => _motion.inCell(offset, 0),
    holdSync: ({required hold}) => _input.holdSync = hold,
  );

  /// Ticks on every caret move, so the note's semantics — its text around the
  /// caret, and the selection in it — follow without rebuilding the note.
  final ValueNotifier<int> _semanticsTick = ValueNotifier<int>(0);

  /// Typewriter mode's glide to the caret, one per burst of moves.
  late final TypewriterFollow _typewriter = TypewriterFollow(_centerCaret);

  /// The desktop context menu, and the clipboard's and the spelling's
  /// entries it shares with the touch toolbar. Listened to from [initState]:
  /// the note rebuilds when it opens or closes.
  late final SourceContextMenu _menu = SourceContextMenu(
    buffer: () => widget.buffer,
    selection: () => _selection,
    grouped: () => widget.editorMenu != null,
    caretRect: () => caretRect,
    offsetAt: offsetAt,
    linkAt: linkAt,
    openLink: (kind, raw, href) => widget.onOpenLink?.call(kind, raw, href),
    hideTouch: () => _touch.hide(),
    showTouch: ({required toolbar}) => _touch.show(toolbar: toolbar),
    cut: cutSelection,
    copy: copySelection,
    paste: paste,
    selectAll: selectAll,
    replace: _replaceRange,
    spellCheck: () => widget.spellCheck,
    spellRanges: _marks.spellRanges,
    formats: _menuFormats,
    table: () => _tableKeys.commands()?.menu(),
    structure: () => widget.editorMenu?.call(),
  );

  /// The context menu opened or closed.
  void _onMenuChanged() => setState(() {});

  /// The toolbar's formats a menu offers: none when the editor gives it a
  /// grouped menu of its own, which holds them.
  List<FormatMenuEntry> _menuFormats() => widget.editorMenu != null
      ? const <FormatMenuEntry>[]
      : widget.formatMenu?.call() ?? const <FormatMenuEntry>[];

  /// The `+` handles of the table in play (#261): the one under the mouse
  /// on the desktop, the caret's on a phone.
  late final SourceTableHover _handles = SourceTableHover(
    buffer: () => widget.buffer,
    live: () => widget.hideMarkers,
    mounted: () => mounted,
    blockOf: (line) => _styler?.blockOf(line),
    caretSpot: _caret.spot,
    noteBox: () => _noteBox,
    scroll: () => _scroll,
    tableRowAt: (line, block, at) => _pieces.tableRowAt(line, block, at),
    piecesOf: _pieces.of,
    lineBox: _geometry.lineBox,
    drawnHeightOf: _pieces.drawnHeightOf,
    theme: () => widget.theme,
    replace: (start, end, text, caret) =>
        replaceText(start, end, text, caret: SelectionModel.at(caret)),
  );

  /// The copy buttons of the code blocks on screen in `live` (#541).
  late final SourceCodeCopies _codeCopies = SourceCodeCopies(
    buffer: () => widget.buffer,
    live: () => widget.hideMarkers,
    drawsTodo: () => TodoBlockScope.of(context) != null,
    styler: () => _styler,
    noteBox: () => _noteBox,
    scroll: () => _scroll,
    heights: () => _heights,
    folds: _folds,
    padding: () => widget.padding,
    lineBox: _geometry.lineBox,
    columnOfLine: _geometry.columnOfLine,
    rightInset: () => _metrics.rightInset,
    columnsLeft: _metrics.columnsLeft,
    gap: () => _metrics.gap,
  );

  /// The template checker (T-TPL-09): the check run and armed on the note,
  /// the problems on a line, and the hint under the span the caret is on.
  late final TemplateHintController _hints = TemplateHintController(
    buffer: () => widget.buffer,
    selection: () => _selection,
    check: () => widget.templateCheck,
    isTemplate: () => widget.templateCommands,
    replace: _replaceRange,
    spanRect: _templateSpanRect,
  );

  /// The wikilink suggester (#475): the panel a `[[link]]` being typed opens,
  /// its keys, and the edit that completes the link. Listened to from
  /// [initState]: the note rebuilds when the panel changes.
  late final WikilinkSuggestController _suggest = WikilinkSuggestController(
    buffer: () => widget.buffer,
    selection: () => _selection,
    suggester: () => widget.wikilinkSuggester,
    lineRead: (line) => _tokensAt(line) != null,
    inCodeAt: _typing.inCodeAt,
    headings: () => headings,
    blocks: () => _blockAnchors.read(),
    notePath: () => widget.notePath,
    replace: (start, end, text, caret) =>
        _replaceRange(start, end, text, caret: caret),
    ensureCaretVisible: _reveal.ensureCaretVisible,
    caretRect: () => _caretRectAt(_selection.extent) ?? caretRect,
    noteBox: () => _noteBox,
    caretMoves: () => Listenable.merge([_scroll, _caret.rect]),
  );

  /// The note's block anchors, for a `[[#^` link to the note being edited
  /// (#844): walked when the panel asks, kept for the revision — or the
  /// owner's, when it handed in the one it reads (#869).
  late final BufferBlockAnchors _blockAnchors =
      widget.blockAnchors ?? BufferBlockAnchors(() => widget.buffer);

  /// The suggester's panel opened, closed or changed: the note is built
  /// again, as it always was when the panel moved.
  void _onSuggestChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    // Always up: they draw nothing while nothing is in play (#261).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handles.overlay.show();
      _hints.overlay.show();
      // The copy buttons ride the note's paint: off stage the pane hides,
      // and they go with it rather than drawing over the pane that is on.
      _codeCopies.sync(onStage: widget.onStage);
      // The first check, off the build: the problem marks are on the note the
      // frame after it opens, and nothing waited for them (#316).
      _hints
        ..refresh()
        ..run();
    });
    _styling.restyle();
    _suggest.addListener(_onSuggestChanged);
    _touch.addListener(_onTouchChanged);
    _menu.addListener(_onMenuChanged);
    _scroll = widget.controller ?? ScrollController();
    _ownsScroll = widget.controller == null;
    _focus = widget.focusNode ?? FocusNode();
    _ownsFocus = widget.focusNode == null;
    _rows.rebuild();
    _history = widget.history ?? widget.surface?.history ?? EditHistory();
    _ownSelection = widget.surface?.initialSelection ?? _ownSelection;
    _seenRevision = widget.buffer.revision;
    _input = _makeInput();
    widget.surface?.attachView(this);
    widget.spellCheck?.addListener(_onSpellingChanged);
    widget.templateCheck?.addListener(_onSpellingChanged);
    widget.findMatches?.addListener(_onSpellingChanged);
    widget.deadLinks?.addListener(_onDeadLinksChanged);
    widget.mathCache?.addListener(_onMathTypeset);
    // The hand over a Ctrl-clickable link appears when the modifier goes
    // down, and goes when it comes up, without waiting for a move (#725).
    HardwareKeyboard.instance.addHandler(_pointer.modifierChanged);
    // A window hidden to the tray draws nothing (#512): the caret blink is
    // its own frame source and stops while it is off screen.
    WindowVisibility.shown.addListener(_onWindowShown);
    _focusReturn.start();
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
    reach: _inputReach,
    onRecord: _history.record,
    onNewline: _typing.newline,
    onTyped: _typing.typed,
    onTokenizer: (edit, buffer) {
      // The edit path's clock: opened here and closed by `onEdited`, the
      // two ends of the same `_replace` (#316) — and only when a profiling
      // round asked for the frame's parts (#362): a release build reads no
      // clock on the path it would be measuring.
      _cost.startEdit();
      _styling.edited(edit);
    },
    selection: () => _selection,
    onSelection: (next) {
      setState(() => _ownSelection = next);
      widget.onSelection?.call(next);
      _scheduleCaret();
      _suggest.refresh();
    },
    onEdited: (edit) {
      _touch.hide();
      _syncLines(edit);
      setState(() {
        _ownSelection = _ownSelection.clampTo(widget.buffer.length);
      });
      _scheduleCaret();
      _reveal.ensureCaretVisible();
      _notifyChanged(edit);
      _cost.endEdit();
      _suggest.refresh(typed: true);
    },
  );

  /// What the frame this view is drawing costs it, in parts (#316).
  ///
  /// The exported logs show typing as a run of frames whose build is 11-33 ms,
  /// and `[frames] slow frame` (main.dart) reports that frame's own `build` —
  /// which Flutter counts as build + layout + paint together — so it cannot
  /// say whether the edit path, the lines, or the paint made it. These are the
  /// parts: the synchronous edit path, then the view's own build, its
  /// subtree's layout and its paint. What is left between their sum and that
  /// frame's own `build` is work *outside* this view — the shell rebuilding
  /// around it — which is how the two lines split a frame.
  ///
  /// Measured on every frame the view draws, not only the ones a keystroke
  /// arrives in: a scroll or a window resize lays the same lines out again (a
  /// frame of `build 66.6 ms` with no keystroke and nothing else in the log,
  /// 12:25 session), and those are frames this has to be able to name.
  ///
  /// Held to half of 60 Hz ([FrameCost.frameBarMicros]), so the line appears
  /// while the rest of the app still has room in the frame; written as
  /// `[edit] frame: …`, the logger naming the view.
  final FrameCost _cost = FrameCost(
    label: '',
    log: const AppLogger(name: 'edit'),
  );

  /// The buffer revision this view last drew or edited, so an edit made
  /// behind its back is seen. (Comparing the old widget's buffer with the new
  /// one's could not see it: it is the same object.)
  int _seenRevision = 0;

  @override
  void didUpdateWidget(MarkdownSourceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onStage != widget.onStage) {
      // Show and hide are a rebuild of the overlay portal, and the portal
      // refuses one during a build: the pane's frame is enough to wait.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _codeCopies.sync(onStage: widget.onStage);
      });
    }
    // The note became a template, or stopped being one: its lines are
    // coloured again at the build this update is part of, and a template is
    // checked off the build (the answer notifies listeners outside this one).
    if (oldWidget.templateCommands != widget.templateCommands) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _hints
          ..run()
          ..refresh();
      });
    }
    if (!identical(oldWidget.surface, widget.surface)) {
      oldWidget.surface?.detachView(this);
      widget.surface?.attachView(this);
    }
    if (!identical(oldWidget.spellCheck, widget.spellCheck)) {
      oldWidget.spellCheck?.removeListener(_onSpellingChanged);
      widget.spellCheck?.addListener(_onSpellingChanged);
    }
    if (!identical(oldWidget.templateCheck, widget.templateCheck)) {
      oldWidget.templateCheck?.removeListener(_onSpellingChanged);
      widget.templateCheck?.addListener(_onSpellingChanged);
      // A check attached now (the note became a template, its folder having
      // been read): the problems are worked out at once, not on the next
      // keystroke. Off the build: the answer notifies listeners outside this
      // view too, and one of them may be the widget now rebuilding it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _hints
          ..run()
          ..refresh();
      });
    }
    if (!identical(oldWidget.findMatches, widget.findMatches)) {
      oldWidget.findMatches?.removeListener(_onSpellingChanged);
      widget.findMatches?.addListener(_onSpellingChanged);
    }
    if (!identical(oldWidget.deadLinks, widget.deadLinks)) {
      oldWidget.deadLinks?.removeListener(_onDeadLinksChanged);
      widget.deadLinks?.addListener(_onDeadLinksChanged);
    }
    if (!identical(oldWidget.mathCache, widget.mathCache)) {
      oldWidget.mathCache?.removeListener(_onMathTypeset);
      widget.mathCache?.addListener(_onMathTypeset);
    }
    if (!identical(oldWidget.buffer, widget.buffer)) {
      // Another note: the keyboard, the history and the caret were this one's.
      // The panel too, and it is the one thing here that cannot be rebuilt
      // from the new text: it holds the offsets of the link it was opened in
      // and the rows that complete it, so `Enter` would write a note name
      // into the note that took its place (#494).
      _suggest.dropInUpdate();
      final attached = _input.isAttached;
      _input.detach();
      _history = widget.history ?? widget.surface?.history ?? EditHistory();
      _ownSelection =
          widget.surface?.initialSelection ?? const SelectionModel.at(0);
      _input = _makeInput();
      _typing.brackets.clear();
      _styling.restyle();
      _folds.clear();
      _rows.rebuild();
      _seenRevision = widget.buffer.revision;
      // Another note to check: the first answer is read off it, not off the
      // one it replaced.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _hints.run();
      });
      if (attached) _input.attach(viewId: View.of(context).viewId);
    } else if (widget.buffer.revision != _seenRevision) {
      // An edit this view did not make (a command, a revert): the colours are
      // read again rather than adjusted, because there is no `SourceEdit` to
      // follow. The link the panel stood in may be gone or moved — the caret
      // is clamped into whatever replaced it — and its offsets are the ones
      // read from the text that went, so the panel goes with them (#494).
      _suggest.dropInUpdate();
      _styling.restyle();
      _folds.clear();
      _rows.rebuild();
      _seenRevision = widget.buffer.revision;
      _ownSelection = _ownSelection.clampTo(widget.buffer.length);
      _hints.schedule();
      // And the platform's copy is now of a note that is not there any more.
      _input.sendSelection();
    }
    if (oldWidget.selection != widget.selection ||
        oldWidget.caretWidth != widget.caretWidth) {
      _scheduleCaret();
    } else if (oldWidget.hideMarkers != widget.hideMarkers ||
        // By value (#789): source mode with a chosen face builds its theme
        // in every build (`surfaceThemeFor`), and a copy of the same values
        // moves no caret.
        oldWidget.theme != widget.theme ||
        oldWidget.showLineNumbers != widget.showLineNumbers ||
        oldWidget.column != widget.column ||
        oldWidget.padding != widget.padding) {
      // The caret's line is drawn another way — source to live and back
      // above all — and the caret kept the place and the height it had.
      _measureCaretAfterFrame();
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
    _handles.dispose();
    _pointer.dispose();
    widget.surface?.detachView(this);
    widget.spellCheck?.removeListener(_onSpellingChanged);
    widget.templateCheck?.removeListener(_onSpellingChanged);
    widget.findMatches?.removeListener(_onSpellingChanged);
    widget.deadLinks?.removeListener(_onDeadLinksChanged);
    widget.mathCache?.removeListener(_onMathTypeset);
    _hints.dispose();
    _suggest
      ..removeListener(_onSuggestChanged)
      ..dispose();
    _input.detach();
    if (_ownsFocus) _focus.dispose();
    WindowVisibility.shown.removeListener(_onWindowShown);
    _focusReturn.dispose();
    _blink.dispose();
    _styling.dispose();
    _typewriter.dispose();
    _semanticsTick.dispose();
    _caret.dispose();
    _footnoteMath.dispose();
    _touch
      ..removeListener(_onTouchChanged)
      ..dispose();
    _menu
      ..removeListener(_onMenuChanged)
      ..dispose();
    HardwareKeyboard.instance.removeHandler(_pointer.modifierChanged);
    if (_ownsScroll) _scroll.dispose();
    super.dispose();
  }

  /// How many source lines the note has.
  int get lineCount => widget.buffer.lineCount;

  /// The spelling changed its mind (a dictionary loaded, a word added, the
  /// underline switched off), the template checker found something else, or
  /// the find bar found something else: the lines on screen are drawn again,
  /// and the hint is read off the problems as they now stand.
  void _onSpellingChanged() {
    if (!mounted) return;
    _hints.refresh();
    setState(() {});
  }

  /// The note's dead links were resolved again (#847): its links are drawn
  /// again, in the colours the answer gives them.
  void _onDeadLinksChanged() {
    if (mounted) setState(() {});
  }

  /// A formula was typeset, or failed to be: the lines that concealed their
  /// source for it are laid out again.
  ///
  /// The line the caret is on is one of them, and it is taller or shorter
  /// now — the spacer takes the formula's room. Nothing about the caret
  /// changed, so no edit came through `_scheduleCaret`: the measurement has to
  /// be asked for by the relayout itself. Post-frame, so a notification that
  /// lands while a frame is building asks for the next one rather than
  /// setting state here.
  void _onMathTypeset() {
    if (mounted) _measureCaretAfterFrame();
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
    final rect = _caret.rect.value;
    final line = _caretLineIndex;
    if (rect == null || line < 0) return null;
    final local = _selection.extent - widget.buffer.offsetOfLine(line);
    final (_, paragraph) = _pieces.fragmentAt(line, local);
    if (paragraph == null || !paragraph.attached) return null;
    return rect.shift(paragraph.localToGlobal(Offset.zero));
  }

  /// The offset a tap at [global] lands on, or null when it lands outside a
  /// line.
  int? offsetAt(Offset global) => _hits.offsetAt(global);

  /// Scrolls so [line] is at the top, as far as the map knows.
  void jumpToLine(int line) {
    if (line < 0 || line >= lineCount || !_scroll.hasClients) return;
    _rows.reshape(() => _folds.reveal(line));
    _scroll.jumpTo(
      (_geometry.lineBox(line).top - widget.padding.top).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      ),
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
  /// Without [follow] the note stays where it is scrolled, for an edit made
  /// somewhere the caret is not.
  void replaceText(
    int start,
    int end,
    String text, {
    SelectionModel? caret,
    bool follow = true,
  }) => _replaceRange(start, end, text, caret: caret, follow: follow);

  /// Makes the note say [text] because it changed elsewhere (the disk, the
  /// WYSIWYG): the history goes, since undoing past it would write the old
  /// text back over the other change, and nothing is reported as an edit.
  void replaceAll(String text) {
    final buffer = widget.buffer;
    buffer.replaceRange(0, buffer.length, text);
    _history.clear();
    // The panel holds offsets into the text that went (#494).
    _suggest.close();
    _styling.restyle();
    _folds.clear();
    _rows.rebuild();
    _seenRevision = buffer.revision;
    setState(() => _ownSelection = _ownSelection.clampTo(buffer.length));
    _input.sendSelection();
    _hints.run();
    _scheduleCaret();
  }

  /// Selects [next], and tells whoever needs to know.
  void select(SelectionModel next) =>
      _applySelection(next, rebuild: true, reveal: true);

  /// Undoes the last edit, and says whether there was one.
  bool undo() => _applyHistory(_history.undo(widget.buffer));

  /// Redoes the last undone edit, and says whether there was one.
  bool redo() => _applyHistory(_history.redo(widget.buffer));

  /// Rebuilds what an undo or a redo changed, the same way a platform edit
  /// does; [caret] is where the history put the caret, null when it had
  /// nothing to do.
  bool _applyHistory(int? caret) {
    if (caret == null) return false;
    // An undo is an edit like any other: the buffer says which lines it
    // touched, and the tokenizer and the map follow those lines.
    final edit = _history.lastEdit;
    if (edit != null) {
      _styling.edited(edit);
    } else {
      _styling.restyle();
    }
    _syncLines(edit);
    // The word count follows the same edit; the undo record is the one it
    // has, or a rebuild when there is none (a restyle after a reload).
    // Undo puts the caret after what it restored (where it was before a
    // deletion, at the start of typing it took back); redo after what it did.
    setState(() {
      _ownSelection = _selection
          .collapsedTo(caret)
          .clampTo(widget.buffer.length);
    });
    widget.onSelection?.call(_ownSelection);
    _input.sendSelection();
    _scheduleCaret();
    _reveal.ensureCaretVisible();
    // An undo is an edit no keystroke made: the panel is read again off the
    // text it left — it follows a link still there and closes on one gone
    // (#494).
    _suggest.refresh();
    if (edit != null) _notifyChanged(edit);
    return true;
  }

  /// The quote marks before a verbatim line's text, null for a line with
  /// syntax of its own (#579). O(log blocks) a line.
  int? _verbatimQuotes(int line) => verbatimQuotesOf(blockAt?.call(line));

  /// Where the caret goes when the keys move it: by a logical motion, by
  /// visual rows, by a page.
  late final SourceCaretMotion _motion = SourceCaretMotion(
    buffer: () => widget.buffer,
    selection: () => _selection,
    live: () => widget.hideMarkers,
    mounted: () => mounted,
    blockOf: (line) => _styler?.blockOf(line),
    fenceOf: _fenceOf,
    folds: _folds,
    hosts: _hosts,
    noteBox: () => _noteBox,
    scroll: () => _scroll,
    caretRect: () => caretRect,
    caretLine: () => _caretLineIndex,
    paintedOffsetAt: _hits.paintedOffsetAt,
    mappedOffsetAt: _hits.mappedOffsetAt,
    paragraphAt: _paragraphs.paragraphAt,
    band: () => _metrics.band,
    gap: () => _metrics.gap,
    rowHeight: () => _metrics.rowHeight,
    verbatimQuotes: _verbatimQuotes,
    apply: _applySelection,
  );

  /// Moves the caret by [motion], the logical motions the key table calls.
  void moveCaretBy(CaretMotion motion, {bool extend = false}) =>
      _motion.moveBy(motion, extend: extend);

  /// Moves the caret [rows] visual rows up (negative) or down, keeping its
  /// horizontal place ([SourceCaretMotion.moveVertically]).
  void moveCaretVertically(int rows, {bool extend = false}) =>
      _motion.moveVertically(rows, extend: extend);

  /// The source line at the top of the view, and how far into its rows
  /// ([ScrollAnchor]). Null while there is nothing drawn to ask.
  ScrollAnchor? get topAnchor {
    if (!_scroll.hasClients || _heights.length == 0) return null;
    final y = _scroll.offset - widget.padding.top;
    if (y <= 0) return (line: 0, fraction: 0.0);
    final line = _geometry.lineAtY(_scroll.offset);
    final box = _geometry.lineBox(line);
    final into = box.height > 0 ? (_scroll.offset - box.top) / box.height : 0.0;
    return (line: line, fraction: into.clamp(0.0, 1.0));
  }

  /// Whether the view has the note drawn to show an anchor in ([showAnchor]):
  /// it is laid out and holds lines.
  bool get acceptsAnchor => _scroll.hasClients && lineCount > 0;

  /// Scrolls the view so [anchor]'s line is at its top, as far into it as
  /// the anchor says; the caret stays where it is. The rows it lands among
  /// may be estimates — a switch of mode draws every row anew — so it looks
  /// again after each frame that measured them, as long as that moves it.
  void showAnchor(ScrollAnchor anchor, {int attempt = 0}) {
    if (!_scroll.hasClients || lineCount == 0) return;
    final box = _geometry.lineBox(anchor.line.clamp(0, lineCount - 1));
    final atTop = anchor.line == 0 && anchor.fraction == 0;
    final offset = atTop
        ? 0.0
        : (box.top + anchor.fraction * box.height).clamp(
            0.0,
            _scroll.position.maxScrollExtent,
          );
    if ((_scroll.position.pixels - offset).abs() > 0.5) {
      _scroll.jumpTo(offset);
    } else if (attempt > 0) {
      return;
    }
    if (attempt >= 12) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showAnchor(anchor, attempt: attempt + 1);
    });
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
  ///
  /// The last [closing] characters of [text] are closers written ahead of the
  /// caret — the `)` of a `(` — which the history keeps in the step of the
  /// typing inside the pair.
  void _replaceRange(
    int start,
    int end,
    String text, {
    SelectionModel? caret,
    bool verbatim = false,
    bool follow = true,
    int closing = 0,
  }) {
    if (start < 0 || end < start || end > widget.buffer.length) return;
    _touch.hide();
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
      closing: closing,
    );
    _styling.edited(edit);
    final next = (caret ?? SelectionModel.at(start + stored)).clampTo(
      buffer.length,
    );
    _syncLines(edit);
    setState(() => _ownSelection = next);
    widget.onSelection?.call(next);
    _input.sendSelection();
    _scheduleCaret();
    if (follow) _reveal.ensureCaretVisible();
    // The shell saves and counts what it is told about: a cut, a paste or a
    // backspace is as much an edit as a keystroke, and the edit says which
    // lines moved so the word count pays for those and not for the note.
    _notifyChanged(edit);
    // An edit made where the writer is looking rather than typing — a box
    // ticked — types no link.
    _suggest.refresh(typed: follow);
  }

  /// What typing means beyond the characters typed: a bracket's pair, a
  /// list carried on by Enter, Tab's indent, the surface's own deletions
  /// and the clipboard.
  late final SourceTyping _typing = SourceTyping(
    buffer: () => widget.buffer,
    selection: () => _selection,
    live: () => widget.hideMarkers,
    mounted: () => mounted,
    indentWidth: () => widget.indentWidth,
    blockOf: (line) => _styler?.blockOf(line),
    tokensOf: (line) => _lineAt(line).tokens,
    verbatimQuotes: _verbatimQuotes,
    replace: _replaceRange,
    // Past a closing character the writer typed over: the typing goes on
    // in the undo step that wrote the pair (#1053).
    stepTo: (offset) {
      _applySelection(
        _selection.collapsedTo(offset),
        reveal: true,
        endStep: false,
      );
      _history.stepOver(offset);
    },
    swallowedBreak: () => _suggest.takeSwallowedBreak(),
    tableEnter: () => _tableKeys.enter(),
    onPaste: () => widget.onPaste,
  );

  /// The selected text, or null when the selection is a caret.
  String? get selectedText => _typing.selectedText;

  /// Copies the selection to the platform's clipboard.
  Future<void> copySelection() => _typing.copySelection();

  /// Copies the selection and removes it, in one undo step with the removal.
  Future<void> cutSelection() => _typing.cutSelection();

  /// Inserts the clipboard's text at the caret, replacing the selection —
  /// unless [MarkdownSourceView.onPaste] takes the clipboard first.
  Future<void> paste() => _typing.paste();

  /// Whether the caret is in code: a fenced or indented block, display
  /// maths, an inline span — where a paste stays text.
  bool get caretInCode => _typing.caretInCode;

  /// Tab: the lines the selection touches moved in, or spaces at a plain
  /// line's caret ([SourceTyping.indent]).
  void indent() => _typing.indent();

  /// Shift+Tab: the lines the selection touches moved out
  /// ([SourceTyping.outdent]).
  void outdent() => _typing.outdent();

  /// Deletes the selection, or what is before the caret: one character, or a
  /// word with [word].
  ///
  /// The surface's own key, not the platform's: the Linux embedder leaves
  /// Backspace and Delete to the framework (`fl_text_input_handler.cc`:
  /// "already handled inside the framework"), which is `EditableText`'s job and
  /// therefore this surface's. An IME's own delete key still arrives as a
  /// deletion delta.
  void deleteBackward({bool word = false}) =>
      _typing.delete(word ? CaretMotion.wordLeft : CaretMotion.characterLeft);

  /// Deletes the selection, or what is after the caret.
  void deleteForward({bool word = false}) =>
      _typing.delete(word ? CaretMotion.wordRight : CaretMotion.characterRight);

  // ---------------------------------------------------------------- columns

  /// The blocks drawn side by side at the pane's width (#729).
  final LiveHosts _hosts = LiveHosts();

  /// Where the lines are drawn, in the scroll view's coordinates, and which
  /// line a point is on, off the height map and the side-by-side layouts.
  late final SourceGeometry _geometry = SourceGeometry(
    heights: () => _heights,
    folds: _folds,
    hosts: _hosts,
    padding: () => widget.padding,
    band: () => _metrics.band,
    gap: () => _metrics.gap,
    columnsLeft: _metrics.columnsLeft,
  );

  /// The note's offsets the platform's input window may reach around a
  /// caret at [caret]: a side-by-side column's lines past its fences, when
  /// the caret is in one (#729); the whole note otherwise.
  (int, int) _inputReach(int caret) {
    final buffer = widget.buffer;
    final whole = (0, buffer.length);
    if (_hosts.layouts.isEmpty) return whole;
    final line = buffer.lineOf(caret.clamp(0, buffer.length));
    final host = _folds.hostOf(line);
    final layout = host == null ? null : _hosts.openedOn(host);
    if (layout == null) return whole;
    final column = layout.run.columnOf(line);
    if (column < 0 || _motion.passedOver(line)) return whole;
    final lines = layout.run.columns[column];
    final first = _motion.firstOf(lines, forward: true);
    final last = _motion.firstOf(lines, forward: false);
    return (
      buffer.offsetOfLine(first),
      buffer.offsetOfLine(last) + buffer.lineLengthAt(last),
    );
  }

  /// The width line [line] is drawn at: its side-by-side column's, or the
  /// text's.
  double _widthOf(int line) {
    final placed = _geometry.columnOfLine(line);
    if (placed == null) return _metrics.textWidth;
    return placed.layout.widths[placed.column];
  }

  /// What line [index], in [block], draws as a fence line in `live`, or
  /// null ([liveFenceOf]).
  LiveFence? _fenceOf(int index, Block? block) => widget.hideMarkers
      ? liveFenceOf(
          index,
          block,
          widget.buffer,
          runs: () => _rows.liveRuns,
          isHost: _folds.isHost,
        )
      : null;

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
      _rows.reshape(() {
        _folds.unfold(line);
        return true;
      });
    } else {
      final end = _sections.foldableEnd(line);
      if (end == null) return;
      _rows.reshape(() {
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

  /// Unfolds what hides the caret, when an edit, a find or a motion took it
  /// there.
  void _revealCaret() {
    if (_folds.isEmpty) return;
    final line = widget.buffer.lineOf(
      _selection.extent.clamp(0, widget.buffer.length),
    );
    var revealed = false;
    _rows.reshape(() => revealed = _folds.reveal(line));
    if (revealed && mounted) setState(() {});
  }

  /// What the gutter shows beside line [line].
  SourceFoldMark _foldMarkOf(int line) {
    if (!_foldingEnabled) return SourceFoldMark.none;
    if (_folds.isFolded(line)) return SourceFoldMark.closed;
    return _sections.foldableEnd(line) == null
        ? SourceFoldMark.none
        : SourceFoldMark.open;
  }

  /// The note changed, so the shell can save it.
  void _notifyChanged(SourceEdit edit) {
    // A template's problems are read off the text again, once the writer
    // pauses: the keystroke that led here pays for the timer alone (#316).
    _hints.schedule();
    widget.onChanged?.call(edit);
  }

  /// Selects `[start, end)` by a click or a jump: the note rebuilt, and the
  /// wikilink panel left as it is.
  void _select(int start, int end) => _applySelection(
    SelectionModel(anchor: start, extent: end),
    rebuild: true,
    suggest: false,
  );

  /// Selects everything.
  void selectAll() => _select(0, widget.buffer.length);

  /// Whether [global], a position in the window, is on the scrollbar's track
  /// (#1106): a mouse there belongs to the scrollbar, not to the text. Asked
  /// of the bar itself ([pointerOnScrollbar]), so there is no strip when the
  /// platform builds no bar or the note has nothing to scroll.
  bool _onScrollbar(Offset global) => pointerOnScrollbar(
    scrollView: _scrollKey.currentContext?.findRenderObject(),
    metrics: _scroll.hasClients ? _scroll.position : null,
    global: global,
  );

  /// The wikilink or Markdown link under [offset] — its kind, its text as
  /// written, and a Markdown link's resolved target — or null. An offset on
  /// either edge of the link is on it: a click lands between characters, and a
  /// click on the first or the last one lands on the edge.
  ///
  /// A reference link's own source carries no `](href)`, so its target comes
  /// from the parse the line was drawn from; an inline link keeps spelling
  /// its own, which the handler reads off as it always has.
  (TokenKind, String, String?)? linkAt(int offset) {
    final buffer = widget.buffer;
    final line = buffer.lineOf(offset.clamp(0, buffer.length));
    final local = offset - buffer.offsetOfLine(line);
    final styled = _lineAt(line);
    // A link comes as its markers and its text, one token each: the link
    // is the run of them, up to the marker that closes it (#971).
    for (final (:kind, :start, :end) in linkRuns(styled.tokens, styled.text)) {
      if (local >= start && local <= end) {
        final raw = styled.text.substring(start, end);
        // A reference link spells no `](href)`: its target has to come from
        // the parse the line was drawn from. An inline link keeps reading it
        // out of its own source, as it always has.
        final href = kind == TokenKind.link && !raw.contains('](')
            ? _styler?.linkHrefAt(line, start)
            : null;
        return (kind, raw, href);
      }
    }
    return null;
  }

  /// A tap on a diagram `live` draws, or on its parse error: the caret on
  /// note line [line] — the block's first, or the one the error names — and
  /// the block's source shown again (#530).
  void _openDiagramLine(int line) {
    if (line < 0 || line >= widget.buffer.lineCount) return;
    _requestKeyboard();
    placeCaret(widget.buffer.offsetOfLine(line));
  }

  /// Takes the focus, or — when the surface has it — opens the connection
  /// again if the platform closed it, and asks for the keyboard either way.
  void _requestKeyboard() {
    _reveal.keyboardAsked();
    if (!_focus.hasFocus) {
      // The focus change attaches (see `onFocusChange`).
      _focus.requestFocus();
      return;
    }
    _input.attach(viewId: View.of(context).viewId);
  }

  /// Makes [next] the selection — clamped into the note — and tells whoever
  /// needs to know: the typing step ends, the shell and the platform hear of
  /// it, and the caret is measured where it went. Every move the writer
  /// makes comes through here; an edit's caret comes with the edit
  /// ([_replaceRange], [_applyHistory]).
  ///
  /// Only what changed is repainted: a caret that stays collapsed moves no
  /// text, so the two lines involved — the one that lost it and the one that
  /// gained it — repaint through [_caret] and nothing else does, while a
  /// move that creates or clears a *range* rebuilds the note, a range being
  /// a background on the runs it covers. [rebuild] rebuilds it whatever
  /// moved.
  ///
  /// [reveal] scrolls the caret into view. [suggest] lets the wikilink panel
  /// follow the caret — or close behind it.
  void _applySelection(
    SelectionModel next, {
    bool rebuild = false,
    bool reveal = false,
    bool suggest = true,
    bool endStep = true,
  }) {
    final clamped = next.clampTo(widget.buffer.length);
    // A caret the writer moved ends the typing step: what is typed next is
    // undone on its own. Not so a caret that steps over a closer the step
    // wrote (`SourceTyping`).
    if (endStep) _history.seal();
    final wasRange = !_selection.isCollapsed;
    _ownSelection = clamped;
    if (rebuild || !clamped.isCollapsed || wasRange) setState(() {});
    _caret.spot.value = _caret.spotOf(clamped.extent);
    if (suggest) _suggest.refresh();
    widget.onSelection?.call(clamped);
    _input.sendSelection();
    _scheduleCaret();
    if (reveal) _reveal.ensureCaretVisible();
  }

  /// Puts the caret at [offset], tells the platform, and keeps it on screen.
  void placeCaret(int offset) =>
      _applySelection(_selection.collapsedTo(offset), reveal: true);

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
  StyledLine _lineAt(int index) => StyledLine(
    widget.buffer.lineAt(index),
    _tokensAt(index) ?? const <Token>[],
  );

  /// Line [index]'s tokens, or null while they are **not known**: the line of
  /// a long note, before the background reading lands
  /// ([SourceStyling.restyle]).
  ///
  /// A null is not "this line has no tokens" — it is "nobody has read it
  /// yet", and the two must not be confused by a reader that takes tokens as
  /// the line's *structure*: the spelling's skip ranges are made of them
  /// (#373).
  List<Token>? _tokensAt(int index) {
    final text = widget.buffer.lineAt(index);
    final own = widget.lineTokens;
    if (own != null) return own(text);
    final styler = _styler;
    if (styler == null) return null;
    final tokens = styler.tokensOf(index);
    if (!widget.templateCommands) return tokens;
    final commands = templateCommandsIn(text);
    return commands.isEmpty
        ? tokens
        : overlayTokens(tokens, commands, TokenKind.templateCommand);
  }

  /// The rectangle a problem's span covers, in global coordinates, or null
  /// while the piece that holds it is not built.
  ///
  /// As [caretRect], the span is measured in the piece it is drawn in and
  /// shifted by where that piece stands of the line's box — the piece its own
  /// text ends in, since a piece a wrap broke after a space ends on that
  /// space, and the span after it begins where the next piece does.
  Rect? _templateSpanRect(int start, int end) {
    final buffer = widget.buffer;
    final line = buffer.lineOf(start);
    final lineStart = buffer.offsetOfLine(line);
    final lineEnd = lineStart + buffer.lineLengthAt(line);
    final last = (end > start ? end - 1 : start).clamp(lineStart, lineEnd);
    final (piece, paragraph) = _pieces.fragmentAt(line, last - lineStart);
    if (piece == null || paragraph == null) return null;
    return sourcePieceSpanRect(
      piece,
      paragraph,
      start - lineStart,
      end.clamp(lineStart, lineEnd) - lineStart,
    );
  }

  /// The caret's spot, exposed so a test can hold that a move inside a run
  /// tells no line anything. Exposed as a listenable rather than as a value
  /// because *not* notifying is the property.
  @visibleForTesting
  ValueListenable<CaretSpot> get caretSpot => _caret.spot;

  /// From how many lines on a note's colours are read in the background.
  ///
  /// Below it the reading costs a frame or less and is done in place, so
  /// the first frame is already coloured.
  @visibleForTesting
  static int backgroundLines = 50000;

  /// Whether [buffer] is a long note: one whose colours are read in the
  /// background ([backgroundLines]), and whose scan keeps its tags and links
  /// block by block ([references]) — so what follows it as it is edited
  /// reads those rather than its text.
  static bool readsInBackground(SourceBuffer buffer) =>
      buffer.lineCount >= backgroundLines;

  /// From how many lines on a note read in place reads the blocks of its top
  /// alone before its first frame, and the rest a slice at a time after it
  /// (`SourceStyling`).
  ///
  /// The whole scan of a 16 000-line note was most of the 20 ms frame that
  /// opened it on a tablet (device log, 2026-10-20), for a frame that draws
  /// a screen of it. Below this the scan is a few milliseconds, and a note
  /// read whole has its outline at once.
  @visibleForTesting
  static int progressiveLines = BlockScanner.defaultBudget;

  /// Completes when the reading of the note under way has landed — at once
  /// when none is: what a reader of the same lines waits for rather than
  /// reading them again (#1199), and then asks [handOver] for.
  Future<void> get readingLanded => _styling.readingLanded;

  /// The Mermaid block — or, where the note's tasks are at hand
  /// ([TodoBlockScope], asked of this view), the `todo` fence — line
  /// [index] is part of, for `live` to draw in its lines' place
  /// ([liveDiagramOf]).
  LiveDiagram? _diagramOf(int index) => liveDiagramOf(
    index,
    _styler?.blockOf(index),
    widget.buffer,
    drawsTodo: () => TodoBlockScope.of(context) != null,
  );

  /// Measures the caret after the frame that laid its line out.
  void _scheduleCaret() {
    _semanticsTick.value++;
    // The caret moved: the hint follows it off the problems as they stand.
    _hints.refresh();
    _revealCaret();
    _blink.restart();
    _followCaret();
    // Measured *now*, from the layout the last frame left, and again after the
    // next frame: a caret that moved because of a tap or a key is on screen
    // immediately, and the frame that may have re-laid its line corrects it.
    // Waiting only for the post-frame callback makes the caret a frame late,
    // which
    // is how a cursor feels slow when it is doing nothing slow.
    _caret.measure();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _caret.measure();
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

  /// The window was hidden or shown again: the blink stops drawing while it
  /// is hidden and starts over when it is back (#512).
  void _onWindowShown() => _blink.restart();

  /// The keys given back to the note when its window comes back to the
  /// front (#539).
  late final FocusReturn _focusReturn = FocusReturn(
    focus: () => _focus,
    restore: () {
      if (!mounted) return;
      if (_focus.hasFocus) {
        // The focus came back on its own: the connection may not have.
        _input
          ..detach()
          ..attach(viewId: View.of(context).viewId);
      } else {
        _focus.requestFocus();
      }
    },
  );

  /// Whether the caret is blinking right now, for the test that holds the
  /// blink to the window's visibility (#512).
  @visibleForTesting
  bool get caretBlinking => _blink.blinking;

  /// Measures the caret again once the next frame has laid its line out:
  /// the caret stayed where it was while its line was laid out anew, in
  /// another mode or at another width.
  void _measureCaretAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _caret.measure();
    });
  }

  /// How many times the caret was measured, for the test that holds a
  /// rebuild with a theme of the same values to measuring nothing (#789).
  @visibleForTesting
  int get caretMeasures => _caret.measures;

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

  // Every frame the view builds is measured, for the report (#316) — when a
  // profiling round asked for it: what a frame costs is read off a
  // `Stopwatch` round the build and in the render object `timed` wraps it
  // in, on the very path the report is about, and a release build runs
  // neither (#362).
  @override
  Widget build(BuildContext context) => _cost.timed(() => _buildView(context));

  Widget _buildView(BuildContext context) {
    final syntax = widget.syntax ?? SyntaxColors.of(context);
    _metrics.syntax = syntax;
    _metrics.scaler = MediaQuery.textScalerOf(context);
    // The shortcuts wrap the focus, not the other way round: a
    // `CallbackShortcuts`
    // only sees a key that travels through it on the way to the focused node,
    // so
    // one *below* the `Focus` it belongs to never fires.
    var note = _shortcuts(
      Focus(
        focusNode: _focus,
        autofocus: widget.autofocus,
        onKeyEvent: _menuKeys.handle,
        onFocusChange: (hasFocus) {
          _focusReturn.focusChanged(hasFocus: hasFocus);
          // Only the focused note blinks (#512): an editor the keys are not
          // going to keeps its caret, steady, and draws no frame for it.
          _blink.restart();
          if (hasFocus) {
            _input.attach(viewId: View.of(context).viewId);
          } else {
            _input.detach();
            _touch.hide();
            hideContextMenu();
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Another width or text size wraps the caret's line anew.
            if (_metrics.layOut(
              constraints.maxWidth,
              MediaQuery.textScalerOf(context),
            )) {
              _measureCaretAfterFrame();
            }
            final available = _metrics.textWidth;
            // The `columns` blocks that sit side by side at this width.
            _rows.layOutHosts(available);
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
            return _pointer.listen(
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _pointer.tapUp,
                // Selecting by touch: a long press takes the word under the
                // finger, moving it extends by words, and letting go brings
                // the toolbar up. A mouse has its drag instead.
                onLongPressStart: (details) =>
                    _pointer.longPressAt(details.globalPosition, start: true),
                onLongPressMoveUpdate: (details) =>
                    _pointer.longPressAt(details.globalPosition, start: false),
                onLongPressEnd: (_) => _pointer.longPressEnd(),
                // The text's own pointer over the note; the gutter keeps the
                // arrow (`_Line`), and a drawn task box the hand (#505).
                child: ValueListenableBuilder<MouseCursor>(
                  valueListenable: _pointer.cursor,
                  builder: (context, cursor, child) => MouseRegion(
                    cursor: cursor,
                    onExit: (_) => _pointer.exit(),
                    child: child,
                  ),
                  child: NotificationListener<ScrollMetricsNotification>(
                    onNotification: _reveal.onScrollMetrics,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _reveal.onScroll,
                      child: CustomScrollView(
                        key: _scrollKey,
                        controller: _scroll,
                        physics: const ContentClampPhysics(),
                        slivers: <Widget>[
                          SliverPadding(
                            padding: EdgeInsets.only(
                              left: _metrics.leftInset,
                              right: _metrics.rightInset,
                              top: widget.padding.top,
                              // Typewriter mode: room for the last row to
                              // reach the middle.
                              bottom:
                                  widget.padding.bottom +
                                  (footnotes.isEmpty ? slack : 0),
                            ),
                            sliver: sourceRowSlivers(
                              width: available,
                              heights: _heights,
                              folds: _folds,
                              hosts: _hosts,
                              look: (
                                gutter: _metrics.gutter,
                                gap: _metrics.gap,
                                band: _metrics.band,
                                textWidth: _metrics.textWidth,
                                numbered: widget.showLineNumbers,
                                theme: widget.theme,
                                itemsIndent: _metrics.itemsIndent,
                              ),
                              line: _lineWidget,
                            ),
                          ),
                          if (footnotes.isNotEmpty)
                            SliverPadding(
                              // Where the read view puts its section: past the
                              // note's own padding, the text's edges its edges.
                              padding: EdgeInsets.only(
                                left: _metrics.leftInset + _metrics.gutter,
                                right: _metrics.rightInset,
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
    note = SourceSemantics(
      tick: _semanticsTick,
      buffer: widget.buffer,
      selection: () => _selection,
      focused: () => _focus.hasFocus,
      onTap: _requestKeyboard,
      onSelect: select,
      onMove: moveCaretBy,
      onCopy: copySelection,
      onCut: cutSelection,
      onPaste: paste,
      child: note,
    );
    return SourceOverlays(
      scroll: _scroll,
      caretSpot: _caret.spot,
      menu: _menu,
      touch: _touch,
      tables: _handles,
      hints: _hints,
      suggest: _suggest,
      codeCopies: _codeCopies,
      child: note,
    );
  }

  /// Line [index] drawn [width] wide: a row of the note, or a line of a
  /// side-by-side column ([inColumn]), which has no gutter of its own.
  Widget _lineWidget(
    BuildContext context,
    int index, {
    required double width,
    bool inColumn = false,
    double outerIndent = 0,
    int outerQuotes = 0,
  }) {
    final styled = _lineAt(index);
    final block = _styler?.blockOf(index);
    final quoted = widget.hideMarkers
        ? _quotes.of(index, block, widget.buffer)
        : null;
    return SourceLine(
      key: ValueKey<int>(index),
      fold: inColumn ? SourceFoldMark.none : _foldMarkOf(index),
      onFold: () => toggleFold(index),
      onFoldDown: _pointer.controlPressed,
      onDiagramDown: _pointer.diagramDown,
      onDiagramLine: _openDiagramLine,
      paragraphKey: _paragraphs.keyFor(index),
      styled: styled,
      shape: widget.hideMarkers
          ? LineShape.of(
              styled,
              block,
              index,
              quoted: quoted,
              callout: liveCalloutLine(index, block, widget.buffer, _quotes),
            )
          : LineShape.none,
      pictures: widget.hideMarkers && widget.embedResolver != null
          ? _styler?.picturesOf(index) ?? const <LinePicture>[]
          : const <LinePicture>[],
      embedResolver: widget.embedResolver,
      formula: widget.hideMarkers && widget.mathCache != null
          ? liveFormulaOf(_styler?.blockOf(index), widget.buffer)
          : null,
      mathCache: widget.mathCache,
      diagram: widget.hideMarkers ? _diagramOf(index) : null,
      tableRow: widget.hideMarkers && block?.kind == BlockKind.table
          ? (at) => _pieces.tableRowAt(index, block!, at)
          : null,
      tableHeader: block?.kind == BlockKind.table && index == block!.startLine,
      pieceKey: block?.kind == BlockKind.table
          ? (at) => _paragraphs.fragmentKey(index, at)
          : null,
      pieceShift: _caret.shift,
      definition: widget.hideMarkers && block != null
          ? _styler?.definitionRunOf(block)
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
      number: widget.showLineNumbers && !inColumn ? index + 1 : null,
      gutterWidth: inColumn ? 0 : _metrics.gutter,
      theme: widget.theme,
      syntax: _metrics.syntax ?? SyntaxColors.of(context),
      dark: widget.dark,
      hideMarkers: widget.hideMarkers,
      selected: _marks.selectionIn(index),
      composing: _marks.composingIn(index),
      misspelled: _marks.misspelledIn(index),
      deadLinks: _marks.deadLinksIn(index, styled),
      found: _marks.foundIn(index),
      templateProblems: _hints.problemsIn(index),
      misspelledColor: Theme.of(context).colorScheme.error,
      width: width,
      index: index,
      spot: _caret.spot,
      caret: _caret.rect,
      caretOn: _blink.on,
      rowColor: widget.typewriter ? typewriterLineColor(context) : null,
      fence: _fenceOf(index, block),
      outerIndent: outerIndent,
      outerQuotes: outerQuotes,
    );
  }

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
    // On a table's room, the menu is the nearer cell's (#261).
    if (offset != null && !onSelection) placeCaret(_motion.inCell(offset, 0));
    showContextMenu(global);
  }

  /// The keys in a table `live` draws, and the commands on the caret's
  /// table its menus offer (#261).
  late final SourceTableKeys _tableKeys = SourceTableKeys(
    buffer: () => widget.buffer,
    selection: () => _selection,
    live: () => widget.hideMarkers,
    blockOf: (line) => _styler?.blockOf(line),
    select: (next) => _applySelection(next, reveal: true),
    replace: (start, end, text, caret) =>
        _replaceRange(start, end, text, caret: caret),
    indent: ({required outdent}) => outdent ? this.outdent() : indent(),
  );

  /// Opens the context menu at [global], or at the caret without one (the
  /// menu key, Shift+F10).
  void showContextMenu([Offset? global]) => _menu.show(global);

  /// Whether the context menu is up.
  bool get isContextMenuShown => _menu.isShown;

  /// Closes the context menu.
  void hideContextMenu() => _menu.hide();

  /// Whether the suggester panel is up, for the shell's tour and the tests.
  bool get isSuggesterShown => _suggest.isShown;

  /// The caret rectangle at [offset] in global coordinates, from the piece of
  /// its line the offset is drawn in — or null when that line is not built.
  ///
  /// A wrapped table row is drawn as one paragraph per piece, so the rectangle
  /// is measured in that piece's own coordinates and shifted by where it
  /// stands of the line's box, as [caretRect] is.
  Rect? _caretRectAt(int offset) {
    final buffer = widget.buffer;
    final line = buffer.lineOf(offset.clamp(0, buffer.length));
    final lineStart = buffer.offsetOfLine(line);
    final (piece, paragraph) = _pieces.fragmentAt(line, offset - lineStart);
    if (piece == null || paragraph == null) return null;
    return sourcePieceCaretRect(piece, paragraph, offset - lineStart);
  }

  /// The keys the note answers on its focus, before its shortcuts: the
  /// wikilink panel's, Escape, the way out of a table, the menu key.
  late final SourceMenuKeys _menuKeys = SourceMenuKeys(
    menu: _menu,
    touch: _touch,
    suggest: _suggest,
    selection: () => _selection,
    placeCaret: placeCaret,
    tableExit: () => _tableKeys.exit(),
  );

  /// What the surface's own keys do ([sourceShortcuts]).
  late final SourceKeyActions _keyActions = SourceKeyActions(
    moveVertically: moveCaretVertically,
    moveBy: moveCaretBy,
    downOutOfTable: _tableKeys.downOut,
    page: _motion.page,
    tab: _tableKeys.tab,
    copy: copySelection,
    cut: cutSelection,
    paste: paste,
    selectAll: selectAll,
    deleteBackward: deleteBackward,
    deleteForward: deleteForward,
    undo: undo,
    redo: redo,
  );

  /// [child] with the keys the surface answers itself ([sourceShortcuts]).
  Widget _shortcuts(Widget child) =>
      CallbackShortcuts(bindings: sourceShortcuts(_keyActions), child: child);
}
