/// The windowed read view: only the blocks the viewport shows are laid out.
///
/// This is the rule the whole surface is built around
/// (`docs/records/unified-surface.md` §8.4). The numbers say why: laying out every
/// block of the geometry note costs 552 ms — 33 frames at 60 Hz — and its
/// inline phase costs 378 ms for the document against 5 ms for a viewport. So
/// the view asks the parser for a block only when the sliver hands it one, and
/// the height map answers for the ones it has never seen.
///
/// The seam between the two is `BlockHeightMap`, and it is an **estimator**:
/// the sliver measures its children for real, and the map answers the one
/// question a scrollable cannot avoid — how long the whole note is — with
/// measurements where a frame has been and estimates where none has. It used to
/// hand the sliver a *forced* extent per block instead, which clipped every
/// block taller than its estimate (#250, §8.4.4).
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:niman/src/core/frame_cost.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/dead_links.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_index.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/block_view.dart';
import 'package:niman/src/markdown/render/code_piece_view.dart';
import 'package:niman/src/markdown/render/content_clamp_physics.dart';
import 'package:niman/src/markdown/render/inline_spans.dart'
    show LinkPreviewHooks;
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/marked_block.dart';
import 'package:niman/src/markdown/render/note_margins.dart';
import 'package:niman/src/markdown/render/range_highlight.dart';
import 'package:niman/src/markdown/render/read_block_marks.dart';
import 'package:niman/src/markdown/render/read_code_pieces.dart';
import 'package:niman/src/markdown/render/read_entries.dart';
import 'package:niman/src/markdown/render/read_jumps.dart';
import 'package:niman/src/markdown/render/read_selection.dart';
import 'package:niman/src/markdown/render/read_slivers.dart';
import 'package:niman/src/markdown/render/read_view_keys.dart';
import 'package:niman/src/markdown/render/scroll_anchor.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// A note, read.
final class MarkdownReadView extends StatefulWidget {
  /// Creates a read view over [buffer].
  const new({
    required this.buffer,
    required this.parser,
    required this.mathCache,
    this.controller,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.column = NoteColumn.off,
    this.onTapLink,
    this.onTapWikiLink,
    this.deadLinks,
    this.linkPreview,
    this.embedResolver,
    this.knownScan,
    this.sharedScan,
    this.onToggleTask,
    this.marks = const [],
    this.onTapMark,
    this.selectionActions,
    super.key,
  });

  /// The blocks marked, by line, ascending: a book's annotated paragraphs
  /// (#285), or the part of one annotated (#283), tinted as a highlighter
  /// marks.
  final List<BlockMark> marks;

  /// Called with a marked block's lines, its first and one past its last,
  /// when it is tapped, and where on screen the tap landed.
  final void Function(int startLine, int endLine, Rect at)? onTapMark;

  /// What the menu of a selection offers beside Copy and Select all; null
  /// leaves the text unselectable (#283).
  final List<ReadSelectionAction>? selectionActions;

  /// Called with a task item's line, in [buffer], when its checkbox is
  /// tapped: the pane reads a copy of the note, so ticking it is the note
  /// owner's edit. Null leaves the boxes as pictures.
  final void Function(int line)? onToggleTask;

  /// The note's text.
  final SourceBuffer buffer;

  /// The block parser, owned by the caller so its cache outlives a rebuild.
  final ReadParser parser;

  /// The math render cache, one per surface.
  final MathCache mathCache;

  /// The scroll controller, for the shell's tabs and its place keeping.
  final ScrollController? controller;

  /// The inset above and below the content, and any beyond the note's own
  /// on the sides ([noteTextInsets]).
  final EdgeInsets padding;

  /// The shell's note column: the text set in a centred column of its
  /// width, as the legacy preview and the source pane set it. Without it
  /// the read view ran from the pane's left edge on a wide window.
  final NoteColumn column;

  /// Called when a link is tapped.
  final void Function(String text, String? href)? onTapLink;

  /// Called when a wikilink is tapped.
  final void Function(String inner)? onTapWikiLink;

  /// The links of the note that name nothing (#847), drawn muted; null draws
  /// every link as a live one.
  final ValueListenable<DeadLinks>? deadLinks;

  /// What the links tell the link preview (#846): a pointer on one, a long
  /// press; null previews nothing.
  final LinkPreviewHooks? linkPreview;

  /// Resolves an embed's target to an absolute path, or null.
  final Future<String?> Function(String target)? embedResolver;

  /// The blocks and definitions of a buffer, when someone already holds them
  /// for exactly its lines — the editor, which keeps its own reading of the
  /// note current edit by edit — or null.
  ///
  /// Asked before the note is scanned: on a 246 MB note the scan is 3.3 s in
  /// an isolate, and handing the note to the isolate held the frame that
  /// opened the pane (252 ms, device log 2026-09-23).
  final DocumentScan? Function(SourceBuffer buffer)? knownScan;

  /// The blocks and definitions of the buffer's lines once another reader
  /// that is scanning them has them — the editor, mounted behind this pane
  /// and reading the same note in its own isolate — or null when there is
  /// none, or they no longer match (#1199).
  ///
  /// Asked when [knownScan] has nothing yet, before the pane scans for
  /// itself: a long note opened straight in the read view mounts both panes
  /// at once, and each scanned it, so the note's blocks were held twice for
  /// as long as the tab was open — ~270 MB more on the stress note.
  final Future<DocumentScan?> Function(SourceBuffer buffer)? sharedScan;

  @override
  State<MarkdownReadView> createState() => MarkdownReadViewState();
}

/// The read view's state, so a shell can ask what it shows.
final class MarkdownReadViewState extends State<MarkdownReadView> {
  /// The read pane's own trace, distinct from the legacy preview's `preview`
  /// logger so a device log says which of the two was slow.
  static const AppLogger _log = AppLogger(name: 'read');

  /// The blocks the pane shows, and the height map over them.
  final ReadEntries _entries = ReadEntries();

  /// Whether the pane has a revision worth keeping on screen while the next
  /// one is scanned: it has none before its first scan, and an *empty page* —
  /// what a note view hands it while the note has no buffer yet, off stage —
  /// is not one. Keeping that page is what made the first press of the preview
  /// on a huge note bring up a blank pane (#432): the pane had drawn the empty
  /// page, so a revision "was" on screen, and the top of the note did not take
  /// its place until the whole scan landed.
  bool get _nothingToKeep {
    final shown = _entries.shown;
    return shown == null || shown.length == 0;
  }

  /// Counts the scans started, so an answer that a later one overtook is
  /// dropped.
  int _scans = 0;

  /// Whether a background scan is running.
  bool get scanning => _scanning;
  bool _scanning = false;

  /// A line asked for by [jumpToLine] while there were no blocks to jump
  /// into, taken once the scan lands.
  int? _pendingJump;

  /// From how many lines on a note is scanned in the background.
  ///
  /// Below it the scan costs a frame or less (35 ms for 50 000 lines) and
  /// is done in place, so the first frame already has the blocks.
  @visibleForTesting
  static int backgroundLines = 50000;

  /// How many lines of a note scanned in the background are drawn while it
  /// is: a phone's screens of them, in a few milliseconds of scan
  /// ([DocumentScan.head]).
  @visibleForTesting
  static int headLines = 5000;

  /// Whether the blocks shown are the top of the note alone, drawn while the
  /// whole of it is scanned.
  bool _head = false;

  /// Whether [line] is past what the pane has blocks for yet: a jump there
  /// waits for the scan.
  bool _notYet(int line) {
    final blocks = _entries.blocks;
    return _scanning &&
        (blocks.isEmpty || (_head && line >= blocks.last.endLine));
  }

  /// How many blocks have been built and drawn.
  ///
  /// The windowing's evidence: it is what a test reads to prove that opening a
  /// long note did not lay the whole of it out.
  int get builtBlocks => _entries.built;

  /// How many blocks the note has.
  int get blockCount => _entries.blocks.length;

  /// The blocks this pane scanned for the page, or null before the first
  /// scan lands.
  ///
  /// What the shell asks when it needs something the scan already found —
  /// a list to count, so far — rather than reading the note for it.
  List<Block>? get blocks =>
      _entries.shown == null || _head ? null : _entries.blocks;

  /// The note's headings, read off the blocks this pane already scanned for
  /// the page, or null before the first scan lands.
  ///
  /// The note view's outline: a heading is a block, and these are the blocks
  /// on screen — no second walk of the text (see [outlineOfBlocks]).
  List<OutlineEntry>? get headings {
    final shown = _entries.shown;
    final blocks = _entries.blocks;
    if (shown == null || _head || blocks.isEmpty) return null;
    return outlineOfBlocks(
      BlockIndex(blocks: blocks, revision: shown.revision),
      shown.lineAt,
    );
  }

  /// The document's height: what a frame has drawn for real, plus an estimate
  /// for the part no frame has reached. Null before the first layout.
  double? get totalExtent => _entries.heights?.totalExtent;

  /// How many blocks a frame has laid out and measured.
  ///
  /// The estimator's evidence, as [builtBlocks] is the windowing's.
  int get measuredBlocks => _entries.heights?.measuredCount ?? 0;

  /// Scrolls so the block holding source [line] is at the top (#256).
  ///
  /// A jump arrives as a *line* — a `[[note#Heading]]`, an outline tap, a note
  /// opened at an anchor — and the pixel it used to become was a uniform
  /// fraction of the note's estimated height, which is wrong by a screen on a
  /// note whose blocks differ this much in height (one source line each, five
  /// or thirty visual ones). The height map knows where every block starts, so
  /// the line resolves to a block and the block to its offset. What that offset
  /// is worth is the map's business: exact where a frame has drawn, estimated
  /// where none has, and a jump into unvisited territory lands on the estimate
  /// and leaves the reader there (the alternative — moving under a finger
  /// already on the screen — is worse, §8.4.3).
  ///
  /// Does nothing without a controller, or for a line past the last block.
  void jumpToLine(int line) {
    if (_notYet(line)) {
      _pendingJump = line;
      return;
    }
    final index = _entries.indexAt(line);
    if (index == null) return;
    // A block of a side-by-side `columns` block is drawn in it: the jump
    // lands on the block's top.
    _jumps.toEntry(_entries.hosts.entryOf(index));
  }

  /// The view's moves to a place in the note, each settling over the
  /// frames that measure where it landed.
  late final ReadJumps _jumps = ReadJumps(
    entries: _entries,
    scroll: () => _scroll,
    mounted: () => mounted,
    top: () => widget.padding.top,
  );

  /// Where the blocks report the part of them selected.
  final ReadSelectionScope _selection = ReadSelectionScope();

  /// The text selected, where it is; null when none is (#283).
  ReadSelection? get selection => _selection.selection;

  /// The block holding source [line]: its first line and its text
  /// (`ReadBlock.plainText`); null when there is none there, or none drawn yet.
  ({int line, String text})? blockTextAt(int line) {
    final shown = _entries.shown;
    final index = _entries.indexAt(line);
    if (shown == null || index == null) return null;
    final block = _entries.blocks[index];
    return (
      line: block.startLine,
      text: widget.parser.of(block, shown).plainText,
    );
  }

  /// The blocks from the one holding [line] to the last opening before
  /// [end], each with its first line and read: what a voice reads of the
  /// note, in order (#1276). Empty while none is drawn.
  Iterable<({int line, ReadBlock block})> readBlocks(int line, int end) sync* {
    final shown = _entries.shown;
    final blocks = _entries.blocks;
    final from = _entries.indexAt(line) ?? 0;
    if (shown == null) return;
    for (var i = from; i < blocks.length && blocks[i].startLine < end; i++) {
      final block = blocks[i];
      yield (line: block.startLine, block: widget.parser.of(block, shown));
    }
  }

  /// The scroll the view is moved by: the shell's, or the view's own.
  ScrollController get _scroll =>
      widget.controller ?? (_ownScroll ??= ScrollController());
  ScrollController? _ownScroll;

  /// The view's focus: the keys that move it are heard while it has it
  /// ([readViewKey]).
  final FocusNode _focus = FocusNode(debugLabel: 'read view');

  /// Gives the view the keyboard, so its keys move it.
  void focus() => _focus.requestFocus();

  /// The source line at the top of the view, and how far into it: a
  /// block's lines share its height evenly, so a paragraph of one line is
  /// that line and a code block of forty is cut in forty. Null while there
  /// is nothing drawn to ask.
  ScrollAnchor? get topAnchor => _jumps.topAnchor;

  /// Whether the view has the note drawn to show an anchor in
  /// ([showAnchor]): it is laid out, and holds blocks or is still reading
  /// them in.
  bool get acceptsAnchor =>
      _scroll.hasClients && (_entries.blocks.isNotEmpty || _scanning);

  /// Scrolls the view so [anchor]'s line is at its top, as far into it as
  /// the anchor says — and again after each frame that measured the blocks
  /// it landed among, as [jumpToLine] does. Taken once the scan lands, for
  /// a note still being read.
  void showAnchor(ScrollAnchor anchor) {
    if (_notYet(anchor.line)) {
      _pendingAnchor = anchor;
      return;
    }
    _jumps.toAnchor(anchor);
  }

  /// An anchor asked for while there were no blocks to show it in.
  ScrollAnchor? _pendingAnchor;

  @override
  void initState() {
    super.initState();
    _rescan();
  }

  @override
  void dispose() {
    _focus.dispose();
    _ownScroll?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MarkdownReadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.buffer, widget.buffer) ||
        oldWidget.buffer.revision != widget.buffer.revision) {
      _rescan();
    }
  }

  /// The scan of [buffer]: the one the editor behind this pane is making of
  /// the same lines when it has one ([MarkdownReadView.sharedScan]), else
  /// this pane's own, in an isolate — also when the editor's fails: its
  /// styling is not what this pane waits for (#1236).
  Future<DocumentScan> _scanOf(SourceBuffer buffer) async {
    DocumentScan? shared;
    try {
      shared = await widget.sharedScan?.call(buffer);
    } on Object catch (error) {
      _log.warning("the editor's scan failed ($error); scanning here");
    }
    if (shared != null && shared.revision == buffer.revision) return shared;
    return await scanInBackground(buffer);
  }

  /// Rebuilds the block list and the height map for the current text.
  ///
  /// The scan is O(document) by nature — its incrementality is for edits, not
  /// for the first look — so it is the first thing to measure when the pane is
  /// slow to appear, and it says what it cost.
  ///
  /// A long note is scanned in an isolate ([scanInBackground]): 2.9 s of a
  /// frozen window on a 246 MB note (0.0.9 stress test). Meanwhile the
  /// revision before it stays on screen when there is one — a buffer the
  /// editor handed over as a copy does not change under it — and nothing
  /// when the buffer is one that changed in place, whose old blocks no
  /// longer match its lines, or when the page it holds is empty (see
  /// [_nothingToKeep]).
  void _rescan() {
    final buffer = widget.buffer;
    final scan = ++_scans;
    final clock = Stopwatch()..start();
    final known = widget.knownScan?.call(buffer);
    if (known != null && known.revision == buffer.revision) {
      _scanning = false;
      _show(buffer, known);
      _log.debug(
        'scan: ${_entries.blocks.length} blocks, ${buffer.lineCount} lines '
        'taken as they were in ${clock.elapsedMilliseconds}ms',
      );
      return;
    }
    if (buffer.lineCount < backgroundLines) {
      _scanning = false;
      _show(buffer, DocumentScan.of(buffer));
      _log.debug(
        'scan: ${_entries.blocks.length} blocks, ${buffer.lineCount} lines in '
        '${clock.elapsedMilliseconds}ms',
      );
      return;
    }
    _scanning = true;
    if (identical(_entries.shown, buffer)) _clear();
    if (_nothingToKeep) {
      // Nothing to draw for the wait, which on a phone was 22 s of an empty
      // pane for the 247 MB note (device log, 2026-09-24): the top of the
      // note goes on screen now, and the rest comes with the scan.
      _show(buffer, DocumentScan.head(buffer, headLines));
      _head = true;
      _log.debug(
        'scan: the top shown, ${_entries.blocks.length} blocks, '
        'in ${clock.elapsedMilliseconds}ms; the rest in the background',
      );
    }
    unawaited(
      _scanOf(buffer).then((result) {
        if (!mounted || scan != _scans) return;
        if (!identical(widget.buffer, buffer) ||
            buffer.revision != result.revision) {
          return;
        }
        _log.debug(
          'scan: ${result.blocks.length} blocks, ${buffer.lineCount} lines '
          'in ${clock.elapsedMilliseconds}ms, in the background',
        );
        // Where the reader is in the top, to be kept when the whole note
        // takes its place: its blocks are the same, their measurements not.
        final kept = _head ? topAnchor : null;
        setState(() {
          _scanning = false;
          _head = false;
          _show(buffer, result);
        });
        if (kept != null && (kept.line > 0 || kept.fraction > 0)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) showAnchor(kept);
          });
        }
        final jump = _pendingJump;
        _pendingJump = null;
        if (jump != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) jumpToLine(jump);
          });
        }
        final anchor = _pendingAnchor;
        _pendingAnchor = null;
        if (anchor != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) showAnchor(anchor);
          });
        }
      }),
    );
  }

  /// Draws [scan], the blocks of [buffer], with the definitions it brings.
  ///
  /// Every scan brings its own — `DocumentScan.of` reads them with the
  /// blocks, and the editor's hand-over keeps them current — so there is no
  /// earlier scope to keep. Keeping one when the lines opening with `[` were
  /// unchanged saved nothing, since the new one was already read, and missed
  /// a footnote cited mid-sentence: the citations are the footnotes' order.
  void _show(SourceBuffer buffer, DocumentScan scan) {
    widget.parser.scope = scan.scope;
    _entries.show(buffer, scan);
  }

  /// Draws nothing until the next scan lands.
  void _clear() {
    _head = false;
    _entries.clear();
  }

  /// The lines a code block is drawn in pieces of, past twice as many
  /// ([ReadCodePieces.pieceLines]).
  static const int pieceLines = ReadCodePieces.pieceLines;

  /// Logs the frame that first put content on screen: how many blocks the scan
  /// found, how many that frame built, and how long the whole open took.
  ///
  /// The editor has had `note open first frame` since T-PP-22 and the read pane
  /// had nothing, so a device report of "the preview was slow to open" could
  /// not be split into scan, layout and wait. Called from [_blockAt], which the
  /// sliver runs during layout, so the callback lands at the end of the frame
  /// that drew these blocks.
  void _traceFirstContent() {
    if (_traced || _entries.built == 0) return;
    _traced = true;
    final elapsed = _opened.elapsedMilliseconds;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _log.info(
        'first content: ${_entries.blocks.length} blocks, '
        '${_entries.built} built, '
        '${elapsed}ms after the view was created',
      );
    });
  }

  /// Started when the view is created: the open the trace above reports.
  final Stopwatch _opened = Stopwatch()..start();

  /// Whether the first content was logged (once per view, not once per frame).
  bool _traced = false;

  /// What a frame this pane draws costs it (#316).
  ///
  /// The pane's bar is a whole frame, not the view's half: the source view
  /// inside the editor pane has a line of its own at half, and what this one
  /// adds is everything else — the blocks the read pane lays out while it
  /// scrolls or the note settles, which the device logs show as 76-93 ms
  /// frames with a high `build` and no line of their own.
  final FrameCost _cost = FrameCost(
    label: 'read pane',
    log: _log,
    barMicros: FrameCost.paneBarMicros,
  );

  @override
  Widget build(BuildContext context) {
    _entries
      ..theme = markdownThemeOf(context)
      ..textScaler = MediaQuery.textScalerOf(context);
    final heights = _entries.heights;
    if (heights == null || _entries.blocks.isEmpty || _entries.shown == null) {
      if (_scanning) {
        return const Align(
          alignment: Alignment.topCenter,
          child: LinearProgressIndicator(key: Key('read-view-scanning')),
        );
      }
      return const SizedBox.shrink();
    }
    // Measured here, once, rather than by a `LayoutBuilder` per formula: a
    // `LayoutBuilder` cannot answer an intrinsic query, and a display formula
    // inside a table cell (a column sized by `IntrinsicColumnWidth`) is asked
    // for one. This one is the pane's, around a scroll view nobody asks.
    //
    // The keys a reader moves a page with — the arrows, the page keys, Home
    // and End — while the view has the keyboard, which a click on it gives.
    return Focus(
      focusNode: _focus,
      onKeyEvent: (node, event) => readViewKey(
        event,
        _scroll,
        row: MediaQuery.textScalerOf(context).scale(_entries.theme.lineHeight),
        toEnd: _jumps.toEnd,
      ),
      // A selectable view takes the keyboard itself, where it is clicked:
      // taken back on each click, a selection would be dropped.
      child: switch (widget.selectionActions) {
        final actions? => ReadSelectionArea(
          scope: _selection,
          actions: actions,
          child: _page(heights),
        ),
        null => Listener(
          onPointerDown: (_) => _focus.requestFocus(),
          child: _page(heights),
        ),
      },
    );
  }

  /// The note's page: its blocks and its footnotes, laid out on the pane.
  Widget _page(BlockHeightMap heights) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pane = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        // No room for line numbers: a page that is only read draws none,
        // and kept their gutter empty down its left.
        final insets = noteTextInsets(
          side: widget.column.sideSpaceIn(pane),
          numbers: 0,
        );
        return _scrollView(
          heights,
          widget.padding +
              EdgeInsets.only(left: insets.left, right: insets.right),
          pane,
        );
      },
    );
  }

  /// The note's blocks, then its footnotes, inset by [padding] in a pane
  /// [pane] wide.
  Widget _scrollView(BlockHeightMap heights, EdgeInsets padding, double pane) {
    final availableWidth = pane - padding.horizontal;
    _entries.layOutHosts(
      availableWidth,
      enabled: widget.selectionActions == null,
    );
    return _cost.timed(
      () => CustomScrollView(
        controller: _scroll,
        physics: const ContentClampPhysics(),
        slivers: readSlivers(
          entries: _entries,
          heights: heights,
          padding: padding,
          width: availableWidth,
          head: _head,
          parser: widget.parser,
          mathCache: widget.mathCache,
          blockAt: _blockAt,
        ),
      ),
    );
  }

  /// Draws block [index], parsing it for the first time if need be.
  ///
  /// How tall it comes out is the sliver's business: a `RenderSliver` lays its
  /// own children out, and this one records what it measures (#251).
  ///
  /// [outerItems] is how many list items the sliver drawing it already
  /// stands in: a column of a `columns` block opened in an item.
  Widget _blockAt(
    BuildContext context,
    int index,
    double availableWidth, {
    int outerItems = 0,
  }) {
    final entries = _entries;
    final block = entries.blocks[index];
    entries.built++;
    _traceFirstContent();
    final piece = entries.pieces[index];
    if (piece != null) {
      return CodePieceView(
        buffer: entries.shown!,
        block: block,
        first: piece.first,
        last: piece.last,
        theme: entries.theme,
        whole: (start: piece.start, end: piece.end),
      );
    }
    final view = BlockView(
      read: widget.parser.of(block, entries.shown!),
      theme: entries.theme,
      mathCache: widget.mathCache,
      availableWidth: availableWidth,
      onTapLink: widget.onTapLink,
      onTapWikiLink: widget.onTapWikiLink,
      deadLinks: widget.deadLinks,
      linkPreview: widget.linkPreview,
      embedResolver: widget.embedResolver,
      onToggleTask: widget.onToggleTask,
      outerItems: outerItems,
    );
    final marks = marksIn(widget.marks, block);
    final tapMark = widget.onTapMark;
    Widget drawn = marks.isEmpty
        ? view
        : MarkedBlock(
            key: ValueKey('marked-block-${block.startLine}'),
            marks: marks,
            onTap: tapMark == null
                ? null
                : (at) => tapMark(block.startLine, block.endLine, at),
            child: view,
          );
    if (widget.selectionActions != null) {
      drawn = SelectableBlock(
        scope: _selection,
        line: block.startLine,
        child: drawn,
      );
    }
    return drawn;
  }
}
