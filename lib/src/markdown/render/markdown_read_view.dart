/// The windowed read view: only the blocks the viewport shows are laid out.
///
/// This is the rule the whole surface is built around
/// (`docs/dev/unified-surface.md` §8.4). The numbers say why: laying out every
/// block of the geometry note costs 552 ms — 33 frames at 60 Hz — and its
/// inline phase costs 378 ms for the document against 5 ms for a viewport. So
/// the view asks the parser for a block only when the sliver hands it one, and
/// the height map answers for the ones it has never seen.
///
/// The seam between the two is `BlockHeightMap`: the sliver needs an extent
/// for every block to place any of them, and the map gives a frozen estimate
/// until a block is drawn and its real height measured between frames.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/block_view.dart';
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

  /// The document's height, as the height map currently knows it.
  double? get totalExtent => _heights?.totalExtent;

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
  void _rescan() {
    _scanner = BlockScanner(widget.buffer);
    _blocks = _scanner.index.blocks;
    _heights = BlockHeightMap(blocks: _blocks, estimate: _estimateOf);
    _built = 0;
  }

  /// A block's height before it has ever been drawn.
  ///
  /// Per kind rather than one global "pixels per line", because the kinds
  /// differ by more than their line count: a fence carries its padding, a rule
  /// is one line whatever its text, and the frontmatter takes no room at all.
  /// A wrong estimate only costs a jump that lands slightly off before the
  /// block is measured.
  double _estimateOf(Block block) {
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
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification ||
            notification is ScrollUpdateNotification) {
          _applyMeasurements();
        }
        return false;
      },
      child: CustomScrollView(
        controller: widget.controller,
        slivers: <Widget>[
          SliverPadding(
            padding: widget.padding,
            sliver: SliverVariedExtentList(
              itemExtentBuilder: (index, dimensions) =>
                  heights.extentFor(index),
              delegate: _BlockDelegate(
                count: _blocks.length,
                heights: heights,
                build: _blockAt,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Draws block [index], parsing it for the first time if need be.
  Widget _blockAt(BuildContext context, int index) {
    final block = _blocks[index];
    _built++;
    return _Measured(
      onSize: (size) => _measure(index, size.height),
      child: BlockView(
        parsed: widget.parser.of(block, widget.buffer),
        theme: _theme ?? _fallbackTheme,
        mathCache: widget.mathCache,
        onTapLink: widget.onTapLink,
        onTapWikiLink: widget.onTapWikiLink,
        embedResolver: widget.embedResolver,
      ),
    );
  }

  void _measure(int index, double height) {
    final block = _blocks[index];
    _heights?.measured(index, height, block.lineCount);
    _applyMeasurements();
  }

  /// Applies what has been measured, between frames.
  void _applyMeasurements() {
    final heights = _heights;
    if (heights == null || !heights.hasPending) return;
    if (heights.applyMeasurements() && mounted) {
      setState(() {});
    }
  }
}

/// The sliver's children, with the document's real height attached.
///
/// A lazy list otherwise guesses its scrollable extent from the children it has
/// laid out, and on a long note that guess is a fraction of the truth — every
/// jump beyond it is clamped, which is what once pulled the preview away from
/// the editor. The height map holds an extent for every block, so it can say.
final class _BlockDelegate extends SliverChildBuilderDelegate {
  /// Creates the delegate.
  new({
    required this.count,
    required this.heights,
    required Widget Function(BuildContext context, int index) build,
  }) : super(build, childCount: count);

  /// How many blocks there are.
  final int count;

  /// The heights, for the total extent.
  final BlockHeightMap heights;

  @override
  double? estimateMaxScrollOffset(
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) => heights.totalExtent;
}

/// Reports a child's size after the frame that laid it out.
final class _Measured extends SingleChildRenderObjectWidget {
  const new({required this.onSize, required super.child});

  final void Function(Size size) onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasured(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasured renderObject) {
    renderObject.onSize = onSize;
  }
}

/// The render object behind [_Measured].
final class _RenderMeasured extends RenderProxyBox {
  new(this.onSize);

  void Function(Size size) onSize;

  @override
  void performLayout() {
    super.performLayout();
    final measured = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(measured));
  }
}
