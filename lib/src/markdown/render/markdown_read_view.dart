/// The windowed read view: only the blocks the viewport shows are laid out.
///
/// This is the rule the whole surface is built around
/// (`docs/dev/unified-surface.md` §8.4). The numbers say why: laying out every
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

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_index.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/block_view.dart';
import 'package:niman/src/markdown/render/content_clamp_physics.dart';
import 'package:niman/src/markdown/render/footnote_list.dart';
import 'package:niman/src/markdown/render/markdown_blocks_sliver.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/note_margins.dart';
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
    this.lineNumbers = false,
    this.onTapLink,
    this.onTapWikiLink,
    this.embedResolver,
    this.knownScan,
    this.onToggleTask,
    super.key,
  });

  /// Called with a task item's line, in [buffer], when its checkbox is
  /// tapped: the pane reads a copy of the note, so ticking it is the note
  /// owner's edit. Null leaves the boxes as pictures.
  final void Function(int line)? onToggleTask;

  /// The note's text.
  final SourceBuffer buffer;

  /// The block parser, owned by the caller so its cache outlives a rebuild.
  final BlockParser parser;

  /// The math render cache, one per surface.
  final MathCache mathCache;

  /// The scroll controller, for the shell's tabs and its place keeping.
  final ScrollController? controller;

  /// The inset above and below the content, and any beyond the note's own
  /// on the sides ([noteTextInsets]).
  final EdgeInsets padding;

  /// Whether the editor draws line numbers: the read view keeps their room
  /// without drawing them, so its text stands where the editor's does.
  final bool lineNumbers;

  /// The shell's note column: the text set in a centred column of its
  /// width, as the legacy preview and the source pane set it. Without it
  /// the read view ran from the pane's left edge on a wide window.
  final NoteColumn column;

  /// Called when a link is tapped.
  final void Function(String text, String? href)? onTapLink;

  /// Called when a wikilink is tapped.
  final void Function(ExtensionSpan span)? onTapWikiLink;

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

  @override
  State<MarkdownReadView> createState() => MarkdownReadViewState();
}

/// The read view's state, so a shell can ask what it shows.
final class MarkdownReadViewState extends State<MarkdownReadView> {
  /// The read pane's own trace, distinct from the legacy preview's `preview`
  /// logger so a device log says which of the two was slow.
  static const AppLogger _log = AppLogger(name: 'read');

  List<Block> _blocks = const <Block>[];

  /// The buffer [_blocks] were scanned from: the widget's, or — while a
  /// long note's next revision is scanned in the background — the one
  /// before it, drawn until the scan comes back.
  SourceBuffer? _shown;

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
  BlockHeightMap? _heights;
  int _built = 0;

  /// How many blocks have been built and drawn.
  ///
  /// The windowing's evidence: it is what a test reads to prove that opening a
  /// long note did not lay the whole of it out.
  int get builtBlocks => _built;

  /// How many blocks the note has.
  int get blockCount => _blocks.length;

  /// The blocks this pane scanned for the page, or null before the first
  /// scan lands.
  ///
  /// What the shell asks when it needs something the scan already found —
  /// a list to count, so far — rather than reading the note for it.
  List<Block>? get blocks => _shown == null ? null : _blocks;

  /// The note's headings, read off the blocks this pane already scanned for
  /// the page, or null before the first scan lands.
  ///
  /// The note view's outline: a heading is a block, and these are the blocks
  /// on screen — no second walk of the text (see [outlineOfBlocks]).
  List<OutlineEntry>? get headings {
    final shown = _shown;
    if (shown == null || _blocks.isEmpty) return null;
    return outlineOfBlocks(
      BlockIndex(blocks: _blocks, revision: shown.revision),
      shown.lineAt,
    );
  }

  /// The document's height: what a frame has drawn for real, plus an estimate
  /// for the part no frame has reached. Null before the first layout.
  double? get totalExtent => _heights?.totalExtent;

  /// How many blocks a frame has laid out and measured.
  ///
  /// The estimator's evidence, as [builtBlocks] is the windowing's.
  int get measuredBlocks => _heights?.measuredCount ?? 0;

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
    if (_blocks.isEmpty && _scanning) {
      _pendingJump = line;
      return;
    }
    final index = _blockIndexAt(line);
    if (index == null) return;
    _jumpToIndex(index, attempt: 0);
  }

  /// How many frames a line jump may take to settle.
  ///
  /// Each pass lands where the map says the target is, the frame that lands
  /// measures the blocks around it, and the target's own offset then moves by
  /// what those measurements were wrong by — a paragraph estimated at one
  /// visual line and drawn at three pushes it down, three times further than
  /// the map thought. That converges geometrically — every pass covers the
  /// ground the last one got wrong — and this bounds it. Measured on an anchor
  /// jump into a note of thirty-word paragraphs: three passes, and the last one
  /// moves nothing.
  static const int _maxJumpAttempts = 12;

  /// One pass of [jumpToLine]: jump to where the map says [index] starts, then
  /// look again after the frame that landed.
  void _jumpToIndex(int index, {required int attempt}) {
    final heights = _heights;
    final controller = _scroll;
    if (heights == null || !controller.hasClients) return;
    final offset = heights
        .offsetOf(index)
        .clamp(0.0, controller.position.maxScrollExtent);
    final moved = (controller.position.pixels - offset).abs() > 0.5;
    if (moved) {
      controller.jumpTo(offset);
    } else if (attempt > 0) {
      // The map agrees with where we are: nothing left to correct.
      return;
    }
    if (attempt >= _maxJumpAttempts) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _jumpToIndex(index, attempt: attempt + 1);
    });
  }

  /// The index of the block holding source [line], or null when the note has
  /// none that early.
  ///
  /// The blocks tile the note and are ordered by line, so this is the last one
  /// that starts at or before [line]: a line inside a wrapped paragraph, or the
  /// blank line under it, belongs to a block either way.
  int? _blockIndexAt(int line) {
    if (_blocks.isEmpty) return null;
    var low = 0;
    var high = _blocks.length - 1;
    if (_blocks[low].startLine > line) return null;
    while (low < high) {
      final middle = (low + high + 1) >> 1;
      if (_blocks[middle].startLine <= line) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return low;
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
  ScrollAnchor? get topAnchor {
    final heights = _heights;
    final scroll = _scroll;
    if (heights == null || _blocks.isEmpty || !scroll.hasClients) return null;
    final y = scroll.offset - widget.padding.top;
    if (y <= 0) return (line: 0, fraction: 0.0);
    final index = heights.indexAt(y);
    if (index == null) {
      // Past the blocks, in the footnotes: the note's last line, whole.
      return (line: _blocks.last.endLine - 1, fraction: 1.0);
    }
    final block = _blocks[index];
    final extent = heights.extentFor(index);
    final lines = block.endLine - block.startLine;
    final into = extent > 0 ? (y - heights.offsetOf(index)) / extent : 0.0;
    final exact = into.clamp(0.0, 1.0) * lines;
    final line = exact.floor().clamp(0, lines - 1);
    return (line: block.startLine + line, fraction: exact - line);
  }

  /// Scrolls the view so [anchor]'s line is at its top, as far into it as
  /// the anchor says — and again after each frame that measured the blocks
  /// it landed among, as [jumpToLine] does. Taken once the scan lands, for
  /// a note still being read.
  void showAnchor(ScrollAnchor anchor) {
    if (_blocks.isEmpty && _scanning) {
      _pendingAnchor = anchor;
      return;
    }
    _showAnchor(anchor, attempt: 0);
  }

  /// An anchor asked for while there were no blocks to show it in.
  ScrollAnchor? _pendingAnchor;

  void _showAnchor(ScrollAnchor anchor, {required int attempt}) {
    final heights = _heights;
    final scroll = _scroll;
    if (heights == null || !scroll.hasClients) return;
    final index = _blockIndexAt(anchor.line);
    if (index == null) return;
    final block = _blocks[index];
    final lines = block.endLine - block.startLine;
    final into = lines > 0
        ? ((anchor.line - block.startLine) + anchor.fraction) / lines
        : 0.0;
    final atTop = anchor.line == 0 && anchor.fraction == 0;
    final offset = atTop
        ? 0.0
        : (widget.padding.top +
                  heights.offsetOf(index) +
                  into * heights.extentFor(index))
              .clamp(0.0, scroll.position.maxScrollExtent);
    final moved = (scroll.position.pixels - offset).abs() > 0.5;
    if (moved) {
      scroll.jumpTo(offset);
    } else if (attempt > 0) {
      return;
    }
    if (attempt >= _maxJumpAttempts) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showAnchor(anchor, attempt: attempt + 1);
    });
  }

  /// Goes to the note's end, and again after each frame that measured the
  /// rows it landed on and moved the end — as long as it moves.
  void _toEnd({int attempt = 0}) {
    final scroll = _scroll;
    if (!scroll.hasClients) return;
    final end = scroll.position.maxScrollExtent;
    if ((scroll.position.pixels - end).abs() <= 0.5 && attempt > 0) return;
    scroll.jumpTo(end);
    if (attempt >= _maxJumpAttempts) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _toEnd(attempt: attempt + 1);
    });
  }

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
  /// longer match its lines.
  void _rescan() {
    final buffer = widget.buffer;
    final scan = ++_scans;
    final clock = Stopwatch()..start();
    final known = widget.knownScan?.call(buffer);
    if (known != null && known.revision == buffer.revision) {
      _scanning = false;
      _show(buffer, known);
      _log.debug(
        'scan: ${_blocks.length} blocks, ${buffer.lineCount} lines taken as '
        'they were in ${clock.elapsedMilliseconds}ms',
      );
      return;
    }
    if (buffer.lineCount < backgroundLines) {
      _scanning = false;
      _show(buffer, DocumentScan.of(buffer));
      _log.debug(
        'scan: ${_blocks.length} blocks, ${buffer.lineCount} lines in '
        '${clock.elapsedMilliseconds}ms',
      );
      return;
    }
    _scanning = true;
    if (identical(_shown, buffer)) _clear();
    unawaited(
      scanInBackground(buffer).then((result) {
        if (!mounted || scan != _scans) return;
        if (!identical(widget.buffer, buffer) ||
            buffer.revision != result.revision) {
          return;
        }
        _log.debug(
          'scan: ${result.blocks.length} blocks, ${buffer.lineCount} lines '
          'in ${clock.elapsedMilliseconds}ms, in the background',
        );
        setState(() {
          _scanning = false;
          _show(buffer, result);
        });
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
    _shown = buffer;
    widget.parser.scope = scan.scope;
    final changes = scan.changes;
    if (!_follow(changes, scan.blocks)) {
      _blocks = _pieced(scan.blocks);
      // A block's estimate when a frame first comes near it: every block of
      // the 246 MB stress note, 2.4 M, was most of the frame that showed it.
      _heights = BlockHeightMap.lazy(
        count: _blocks.length,
        estimate: _estimateOf,
        estimateSpan: _estimateSpanOf,
      );
      _built = 0;
    }
    _handed = changes?.token;
  }

  /// The mark of the editor's hand-over the pane shows, or null when what it
  /// shows was scanned from the text.
  Object? _handed;

  /// Takes [blocks] by replaying [changes] over the heights the pane has,
  /// when they follow the hand-over it shows: the blocks the edits did not
  /// touch keep the height a frame measured, and only the new ones are
  /// estimated — O(the changes), where a new map was O(blocks), 100–200 ms
  /// on a note of 2 M of them, and forgot every measurement.
  ///
  /// False, with nothing changed, when they do not follow it, were not
  /// worth keeping, or a long code block is involved: the pane lays those
  /// out in pieces that are entries of their own, and the changes count
  /// blocks.
  bool _follow(ScanChanges? changes, List<Block> blocks) {
    final heights = _heights;
    final stretches = changes?.stretches;
    if (changes == null ||
        stretches == null ||
        heights == null ||
        changes.since == null ||
        !identical(changes.since, _handed) ||
        _pieces.isNotEmpty) {
      return false;
    }
    var length = heights.length;
    for (final stretch in stretches) {
      length += stretch.inserted - stretch.removed;
      for (
        var at = stretch.start;
        at < stretch.start + stretch.inserted;
        at++
      ) {
        if (_isLongCode(blocks[at])) return false;
      }
    }
    if (length != blocks.length) return false;
    // The estimates are asked with the new indices, of the new list.
    _blocks = blocks;
    for (final stretch in stretches) {
      heights.splice(
        stretch.start,
        stretch.removed,
        stretch.inserted,
        _estimateOf,
      );
    }
    return true;
  }

  /// Draws nothing until the next scan lands.
  void _clear() {
    _shown = null;
    _blocks = const <Block>[];
    _pieces.clear();
    _heights = null;
    _built = 0;
    _handed = null;
  }

  /// The lines a code block is drawn in pieces of, past twice as many.
  ///
  /// A block is the sliver's unit of layout, and a code block is one
  /// paragraph: a fence of 12 000 lines — a log pasted in, or a note whose
  /// fence never closes — was laid out whole the moment any of it scrolled
  /// into view, and one such frame took 74 s (0.0.9 stress test). Pieces of
  /// this many lines are laid out as the viewport reaches them, like any
  /// other block.
  static const int pieceLines = 200;

  /// Which entries of the block list are pieces of a longer code block, and
  /// where in it: the first carries the opening fence, the last the closing
  /// one.
  final Map<int, ({bool first, bool last})> _pieces =
      <int, ({bool first, bool last})>{};

  /// [blocks] with every code block longer than twice [pieceLines] cut into
  /// pieces of that many lines, each an entry of its own.
  List<Block> _pieced(List<Block> blocks) {
    _pieces.clear();
    if (!blocks.any(_isLongCode)) return blocks;
    final out = <Block>[];
    for (final block in blocks) {
      if (!_isLongCode(block)) {
        out.add(block);
        continue;
      }
      for (var at = block.startLine; at < block.endLine; at += pieceLines) {
        final end = at + pieceLines < block.endLine
            ? at + pieceLines
            : block.endLine;
        _pieces[out.length] = (
          first: at == block.startLine,
          last: end == block.endLine,
        );
        out.add(
          Block(
            kind: block.kind,
            startLine: at,
            endLine: end,
            quoteDepth: block.quoteDepth,
            listDepth: block.listDepth,
            fenceInfo: block.fenceInfo,
          ),
        );
      }
    }
    return out;
  }

  static bool _isLongCode(Block block) =>
      (block.kind == BlockKind.fencedCode ||
          block.kind == BlockKind.indentedCode) &&
      block.lineCount > 2 * pieceLines;

  /// Logs the frame that first put content on screen: how many blocks the scan
  /// found, how many that frame built, and how long the whole open took.
  ///
  /// The editor has had `note open first frame` since T-PP-22 and the read pane
  /// had nothing, so a device report of "the preview was slow to open" could
  /// not be split into scan, layout and wait. Called from [_blockAt], which the
  /// sliver runs during layout, so the callback lands at the end of the frame
  /// that drew these blocks.
  void _traceFirstContent() {
    if (_traced || _built == 0) return;
    _traced = true;
    final elapsed = _opened.elapsedMilliseconds;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _log.info(
        'first content: ${_blocks.length} blocks, $_built built, '
        '${elapsed}ms after the view was created',
      );
    });
  }

  /// Started when the view is created: the open the trace above reports.
  final Stopwatch _opened = Stopwatch()..start();

  /// Whether the first content was logged (once per view, not once per frame).
  bool _traced = false;

  /// Block [index]'s height before it has ever been drawn.
  ///
  /// Per kind rather than one global "pixels per line", because the kinds
  /// differ by more than their line count: a heading is set larger, a
  /// formula taller, and the frontmatter takes no room at all. A code block
  /// is its lines' rows, its fences' rows its padding.
  /// A wrong estimate only costs a jump that lands slightly off before the
  /// block is measured.
  double _estimateOf(int index) {
    final block = _blocks[index];
    final theme = _theme ?? _fallbackTheme;
    // A line at the size the text is read at: the theme's is the text's own.
    final line = _textScaler.scale(theme.lineHeight);
    return switch (block.kind) {
      BlockKind.frontmatter => 0,
      BlockKind.thematicBreak => line,
      BlockKind.heading => line * 1.3,
      BlockKind.math => block.lineCount * line * 1.6,
      BlockKind.fencedCode ||
      BlockKind.indentedCode ||
      BlockKind.blank ||
      BlockKind.table ||
      BlockKind.html ||
      BlockKind.listItem ||
      BlockKind.paragraph ||
      BlockKind.quote => block.lineCount * line,
    };
  }

  /// Blocks `[first, end)`'s height before they are asked one by one: a line
  /// each of their lines, O(1) — the lines they span are where the first
  /// starts and the next begins. What [_estimateOf] adds by kind (a
  /// heading's size, a formula's height) comes in as the blocks are asked.
  double _estimateSpanOf(int first, int end) {
    final from = _blocks[first].startLine;
    final to = end < _blocks.length
        ? _blocks[end].startLine
        : _blocks[end - 1].endLine;
    final theme = _theme ?? _fallbackTheme;
    return (to - from) * _textScaler.scale(theme.lineHeight);
  }

  MarkdownTheme? _theme;

  /// The scaler the note's text is read at, as of the last build.
  TextScaler _textScaler = TextScaler.noScaling;
  static const MarkdownTheme _fallbackTheme = MarkdownTheme(
    body: TextStyle(fontSize: 14, height: 1.5),
    heading1: TextStyle(fontSize: 25),
    heading2: TextStyle(fontSize: 21),
    heading3: TextStyle(fontSize: 18),
    heading4: TextStyle(fontSize: 16),
    heading5: TextStyle(fontSize: 14),
    heading6: TextStyle(fontSize: 13),
    code: TextStyle(fontSize: 14, fontFamily: 'monospace'),
    quote: TextStyle(fontSize: 14),
    tableCell: TextStyle(fontSize: 14),
    tableHeader: TextStyle(fontSize: 14),
    link: TextStyle(fontSize: 14),
    wikilink: TextStyle(fontSize: 14),
    tag: TextStyle(fontSize: 14),
    marker: TextStyle(fontSize: 14),
    rule: Color(0xFF888888),
    codeHighlight: <String, TextStyle>{},
    codeBackground: Color(0xFFEEEEEE),
    quoteBar: Color(0xFFCCCCCC),
    tableBorder: Color(0xFFCCCCCC),
    markerDim: Color(0xFF999999),
    blockSpacing: 10,
    listIndentPerLevel: 22,
    quoteIndentPerLevel: 12,
    codePadding: 8,
    quoteBarWidth: 3,
    ruleThickness: 1,
    tableCellPadding: EdgeInsets.all(4),
    lineHeight: 21,
  );

  @override
  Widget build(BuildContext context) {
    _theme = markdownThemeOf(context);
    _textScaler = MediaQuery.textScalerOf(context);
    final heights = _heights;
    if (heights == null || _blocks.isEmpty || _shown == null) {
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
        row: MediaQuery.textScalerOf(context)
            .scale((_theme ?? _fallbackTheme).lineHeight),
        toEnd: _toEnd,
      ),
      child: Listener(
        onPointerDown: (_) => _focus.requestFocus(),
        child: _page(heights),
      ),
    );
  }

  /// The note's page: its blocks and its footnotes, laid out on the pane.
  Widget _page(BlockHeightMap heights) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pane = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final insets = noteTextInsets(
          side: widget.column.sideSpaceIn(pane),
          numbers: widget.lineNumbers
              ? lineNumbersWidth(
                  _shown!.lineCount,
                  (_theme ?? _fallbackTheme).body,
                  MediaQuery.textScalerOf(context),
                )
              : 0,
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
    return CustomScrollView(
      controller: _scroll,
      physics: const ContentClampPhysics(),
      slivers: <Widget>[
        SliverPadding(
          padding: padding,
          // A sliver that places its children from the height map and measures
          // the ones it lays out: `SliverVariedExtentList` forced every extent
          // and clipped what was taller than its estimate (#250), and
          // `SliverList` measured them all and made a far jump cost the note
          // (#251).
          sliver: SliverMarkdownBlocks(
            heights: heights,
            delegate: SliverChildBuilderDelegate(
              (context, index) => _blockAt(context, index, availableWidth),
              childCount: heights.length,
            ),
          ),
        ),
        // The definitions a note ends with. They are not blocks — no block
        // can draw them, because the definitions never reach the block that
        // cites them — so the section is appended, and through a *lazy* list
        // for the same reason the note itself is: a section that lays out
        // every footnote at the top of the frame costs the frame. Measured:
        // appending it whole took first content from 76 ms to 112 ms on the
        // geometry note and the jump from 9 ms to 56.
        //
        // Keyed by the text it was read from: a list kept across a new text
        // kept its children and where they were laid out, and a far offset
        // had it asking the viewport for corrections that never agreed — a
        // layout loop (`read_view_geometry_test`, the fixtures in a row).
        SliverPadding(
          key: ObjectKey(_shown),
          padding: padding,
          sliver: _footnoteSliver(),
        ),
      ],
    );
  }

  /// The footnotes, one row per sliver child.
  Widget _footnoteSliver() => footnoteSliver(
    footnotes: widget.parser.footnotesOf(_shown!),
    theme: _theme ?? _fallbackTheme,
    parser: widget.parser,
    mathCache: widget.mathCache,
    scope: widget.parser.scope,
  );

  /// Draws block [index], parsing it for the first time if need be.
  ///
  /// How tall it comes out is the sliver's business: a `RenderSliver` lays its
  /// own children out, and this one records what it measures (#251).
  Widget _blockAt(BuildContext context, int index, double availableWidth) {
    final block = _blocks[index];
    _built++;
    _traceFirstContent();
    final piece = _pieces[index];
    if (piece != null) {
      return CodePieceView(
        buffer: _shown!,
        block: block,
        first: piece.first,
        last: piece.last,
        theme: _theme ?? _fallbackTheme,
      );
    }
    return BlockView(
      parsed: widget.parser.of(block, _shown!),
      theme: _theme ?? _fallbackTheme,
      mathCache: widget.mathCache,
      availableWidth: availableWidth,
      onTapLink: widget.onTapLink,
      onTapWikiLink: widget.onTapWikiLink,
      embedResolver: widget.embedResolver,
      onToggleTask: widget.onToggleTask,
      scope: widget.parser.scope,
    );
  }
}
