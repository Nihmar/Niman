/// Drawing a whole note, with no viewport in the way.
///
/// Everything else in this directory assumes a window: the read view lays out
/// only what fits, because that is what a reader needs and what makes a long
/// note open at all. Export is the opposite — a PDF, a print, an image of the
/// note — and D12 makes it a seam rather than an afterthought, because a
/// renderer that can only draw what is on screen cannot be made to draw the
/// rest later without rewriting it (`docs/dev/unified-surface.md` §8.6).
///
/// The seam is in two halves, and both are the ones that matter:
///
/// * [MarkdownExportView] draws **every** block at a given width, in one
///   column, asking nothing of a scroll position or a viewport. It is the same
///   block view the read view uses, so the two cannot drift: there is one
///   block painter and both callers use it;
/// * [MarkdownExport.capture] records an already-laid-out note into an image,
///   through a picture, which is the part a page, a printer or an encoder
///   needs and the part a widget tree cannot do by itself.
///
/// What is deliberately *not* here is the offscreen pipeline that attaches the
/// view without a window: that is a dozen lines of `RenderView`, `BuildOwner`
/// and `PipelineOwner` whose API moves between Flutter versions, and it
/// belongs with the caller that wants it. Laying the whole note out is the hard
/// half, and it is tested here.
///
/// One thing an export cannot do is wait: a formula not already in the cache is
/// rendered through its synchronous seam. Export is driven by a button and a
/// button may block a frame; a note being *read* may not, which is why the read
/// view tolerates the asynchronous seam and this does not.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/render/block_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// Draws a whole note, whatever the window is doing.
final class MarkdownExportView extends StatelessWidget {
  /// Creates a view of every block of [buffer], [width] wide.
  const new({
    required this.buffer,
    required this.parser,
    required this.theme,
    required this.mathCache,
    required this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    super.key,
  });

  /// The note's text.
  final SourceBuffer buffer;

  /// The block parser, owned by the caller so its cache is shared with the
  /// read view that may have parsed some of the same blocks.
  final BlockParser parser;

  /// The typography and metrics, the same ones the read view uses.
  final MarkdownTheme theme;

  /// The math render cache.
  final MathCache mathCache;

  /// How wide the page is. Nothing about this is the window's width.
  final double width;

  /// The inset around the page.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final blocks = BlockScanner(buffer).index.blocks;
    return SizedBox(
      width: width,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var at = 0; at < blocks.length; at++)
              BlockView(
                parsed: parser.of(blocks[at], buffer),
                theme: theme,
                mathCache: mathCache,
                spaced: BlockView.spacedBefore(
                  blocks[at],
                  at + 1 < blocks.length ? blocks[at + 1] : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A painting context that can be told to close its picture.
///
/// `PaintingContext.stopRecordingIfNeeded` is protected: the framework calls it
/// at the end of a frame's paint phase, and an offscreen recording has no frame
/// to end. The subclass is the public way to reach it — a layer whose picture
/// was never closed is what `toImage` asserts on.
final class _RecordingContext extends PaintingContext {
  // Super parameters are not available here: `PaintingContext`'s own
  // parameters are named `_containerLayer` and `estimatedBounds`.
  // ignore: use_super_parameters
  new(ContainerLayer layer, Rect bounds) : super(layer, bounds);

  /// Closes the current picture, if one is open.
  void finish() => stopRecordingIfNeeded();
}

/// Records a laid-out note into a picture.
abstract final class MarkdownExport {
  /// Records [box] — a laid-out [MarkdownExportView] — into an image.
  ///
  /// The caller owns the layout, because attaching a tree without a window is
  /// the caller's business; this owns the recording, which is the half that
  /// turns a tree into something a page or an encoder can take. The box paints
  /// into an [OffsetLayer] — a `PaintingContext` takes a layer and its bounds,
  /// not a canvas — and the layer is recorded into a picture through
  /// `toImage`, at as many device pixels per logical pixel as [pixelRatio].
  static Future<ui.Image> capture(
    RenderBox box, {
    Offset offset = Offset.zero,
    double pixelRatio = 1,
  }) async {
    final bounds = offset & box.size;
    final layer = OffsetLayer(offset: offset);
    final context = _RecordingContext(layer, bounds);
    box.paint(context, offset);
    // The picture the box drew into is only complete once the context closes
    // it, and a layer with an unfinished picture is what `toImage` asserts on.
    // Closing it is protected, which is what the subclass is for.
    context.finish();
    try {
      return await layer.toImage(bounds, pixelRatio: pixelRatio);
    } finally {
      layer.dispose();
    }
  }

  /// Measures a laid-out [MarkdownExportView]'s height.
  ///
  /// The height a note takes at a given width is the number a paginating caller
  /// needs before it can decide anything, and it is not derivable from the
  /// source: a line breaks where it breaks.
  static double heightOf(RenderBox box) => box.size.height;
}
