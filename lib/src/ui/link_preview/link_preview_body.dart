import 'package:flutter/material.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/anchor.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/link_preview.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// The note a link points at, read (#846): the read view's own widget over
/// the note's text, with nothing in it to follow or to edit — a link in the
/// card is only drawn — scrolled to the heading or block the link names.
///
/// It scrolls by itself, so a card of a fixed size holds a note of any length
/// (the first [PreviewLimits.bytes] bytes of it).
final class LinkPreviewBody extends StatefulWidget {
  /// The body of [preview], typeset with [mathCache].
  const new({required this.preview, required this.mathCache, super.key});

  /// What to show.
  final LinkPreview preview;

  /// The math render cache the note's formulas are typeset through.
  final MathCache mathCache;

  @override
  State<LinkPreviewBody> createState() => _LinkPreviewBodyState();
}

final class _LinkPreviewBodyState extends State<LinkPreviewBody> {
  late SourceBuffer _buffer = SourceBuffer.fromText(widget.preview.text);
  final ReadParser _parser = ReadParser();
  final GlobalKey<MarkdownReadViewState> _view =
      GlobalKey<MarkdownReadViewState>();

  @override
  void initState() {
    super.initState();
    _seek();
  }

  @override
  void didUpdateWidget(LinkPreviewBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preview.text != widget.preview.text) {
      _buffer = SourceBuffer.fromText(widget.preview.text);
    }
    if (oldWidget.preview.path != widget.preview.path ||
        oldWidget.preview.anchor != widget.preview.anchor) {
      _seek();
    }
  }

  /// Takes the card to the heading or the block the link names, once the read
  /// view has a frame to jump in; the top when the note has none such.
  void _seek() {
    final line = anchorLineOf(widget.preview.text, widget.preview.anchor);
    if (line == null || line == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _view.currentState?.jumpToLine(line);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownReadView(
      key: _view,
      buffer: _buffer,
      parser: _parser,
      mathCache: widget.mathCache,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
    );
  }
}

/// The line of [text] the link's [anchor] (`A#B`, `^id`) names, or null when
/// it names none or [text] has no such place.
int? anchorLineOf(String text, String? anchor) {
  if (anchor == null) return null;
  return switch (parseAnchor(anchor)) {
    final HeadingAnchor heading => headingLineOf(outlineOfText(text), heading),
    BlockIdAnchor(:final id) => blockLineOf(blockAnchorsOfText(text), id),
    null => null,
  };
}
