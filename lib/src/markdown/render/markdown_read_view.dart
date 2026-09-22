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

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/block_view.dart';
import 'package:niman/src/markdown/render/footnote_list.dart';
import 'package:niman/src/markdown/render/markdown_blocks_sliver.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
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
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.column = NoteColumn.off,
    this.onTapLink,
    this.onTapWikiLink,
    this.embedResolver,
    super.key,
  });

  /// The note's text.
  final SourceBuffer buffer;

  /// The block parser, owned by the caller so its cache outlives a rebuild.
  final BlockParser parser;

  /// The math render cache, one per surface.
  final MathCache mathCache;

  /// The scroll controller, for the shell's tabs and its place keeping.
  final ScrollController? controller;

  /// The inset around the content.
  final EdgeInsets padding;

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

  @override
  State<MarkdownReadView> createState() => MarkdownReadViewState();
}

/// The read view's state, so a shell can ask what it shows.
final class MarkdownReadViewState extends State<MarkdownReadView> {
  /// The read pane's own trace, distinct from the legacy preview's `preview`
  /// logger so a device log says which of the two was slow.
  static const AppLogger _log = AppLogger(name: 'read');

  late BlockScanner _scanner;
  late List<Block> _blocks;
  BlockHeightMap? _heights;
  int _built = 0;

  /// How many blocks have been built and drawn.
  ///
  /// The windowing's evidence: it is what a test reads to prove that opening a
  /// long note did not lay the whole of it out.
  int get builtBlocks => _built;

  /// How many blocks the note has.
  int get blockCount => _blocks.length;

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
    final controller = widget.controller;
    if (heights == null || controller == null || !controller.hasClients) {
      return;
    }
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

  @override
  void initState() {
    super.initState();
    _rescan();
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
  /// slow to appear, and it now says what it cost.
  void _rescan() {
    final clock = Stopwatch()..start();
    _scanner = BlockScanner(widget.buffer);
    _blocks = _scanner.index.blocks;
    _heights = BlockHeightMap(count: _blocks.length, estimate: _estimateOf);
    _built = 0;
    _log.debug(
      'scan: ${_blocks.length} blocks, ${widget.buffer.lineCount} lines in '
      '${clock.elapsedMilliseconds}ms',
    );
  }

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
  /// differ by more than their line count: a fence carries its padding, a rule
  /// is one line whatever its text, and the frontmatter takes no room at all.
  /// A wrong estimate only costs a jump that lands slightly off before the
  /// block is measured.
  double _estimateOf(int index) {
    final block = _blocks[index];
    final theme = _theme ?? _fallbackTheme;
    final spacing = theme.blockSpacing;
    return switch (block.kind) {
      BlockKind.frontmatter => 0,
      BlockKind.blank => spacing + theme.lineHeight * 0.5,
      BlockKind.thematicBreak => theme.ruleThickness + spacing,
      BlockKind.heading => theme.lineHeight * 1.3 + spacing,
      BlockKind.fencedCode || BlockKind.indentedCode =>
        block.lineCount * theme.lineHeight + 2 * theme.codePadding + spacing,
      BlockKind.math => block.lineCount * theme.lineHeight * 1.6 + spacing,
      BlockKind.table ||
      BlockKind.html => block.lineCount * theme.lineHeight + spacing,
      BlockKind.paragraph ||
      BlockKind.listItem ||
      BlockKind.quote => block.lineCount * theme.lineHeight + spacing,
    };
  }

  MarkdownTheme? _theme;
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
    final heights = _heights;
    if (heights == null || _blocks.isEmpty) {
      return const SizedBox.shrink();
    }
    // Measured here, once, rather than by a `LayoutBuilder` per formula: a
    // `LayoutBuilder` cannot answer an intrinsic query, and a display formula
    // inside a table cell (a column sized by `IntrinsicColumnWidth`) is asked
    // for one. This one is the pane's, around a scroll view nobody asks.
    return LayoutBuilder(
      builder: (context, constraints) {
        final pane = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final side = widget.column.sideSpaceIn(pane);
        return _scrollView(
          heights,
          widget.padding + EdgeInsets.symmetric(horizontal: side),
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
      controller: widget.controller,
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
        SliverPadding(padding: padding, sliver: _footnoteSliver()),
      ],
    );
  }

  /// The footnotes, one row per sliver child.
  Widget _footnoteSliver() {
    final notes = widget.parser.footnotesOf(widget.buffer);
    return SliverList.builder(
      itemCount: notes.isEmpty ? 0 : notes.length + 1,
      itemBuilder: (context, index) {
        final theme = _theme ?? _fallbackTheme;
        if (index == 0) return FootnoteDivider(theme: theme);
        return FootnoteRow(
          footnote: notes[index - 1],
          number: index,
          theme: theme,
        );
      },
    );
  }

  /// Draws block [index], parsing it for the first time if need be.
  ///
  /// How tall it comes out is the sliver's business: a `RenderSliver` lays its
  /// own children out, and this one records what it measures (#251).
  Widget _blockAt(BuildContext context, int index, double availableWidth) {
    final block = _blocks[index];
    _built++;
    _traceFirstContent();
    return BlockView(
      parsed: widget.parser.of(block, widget.buffer),
      theme: _theme ?? _fallbackTheme,
      mathCache: widget.mathCache,
      availableWidth: availableWidth,
      onTapLink: widget.onTapLink,
      onTapWikiLink: widget.onTapWikiLink,
      embedResolver: widget.embedResolver,
    );
  }
}
