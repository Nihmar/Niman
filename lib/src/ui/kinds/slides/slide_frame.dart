import 'package:flutter/material.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// The size a slide is laid out at, in logical pixels (#534): one layout,
/// scaled to the pane, the projector, the thumbnails and the PDF alike.
const Size slideSize = Size(960, 540);

/// How much larger than a note's text a slide's is: a 16 px line on a
/// 960 px slide reads as a footnote on a projector.
const double slideTextScale = 1.8;

/// One slide, drawn: its Markdown through the note's own read view, laid
/// out at [slideSize] and scaled to whatever box it is given.
///
/// What overflows the slide is clipped, not shrunk — the editor is where a
/// slide gets shorter. [live] false makes it a picture (a thumbnail): no
/// taps, no focus, no scroll.
final class SlideFrame extends StatefulWidget {
  /// Draws [markdown] as one slide.
  const new({
    required this.markdown,
    required this.resolveEmbed,
    this.onTapLink,
    this.onTapWikiLink,
    this.live = true,
    super.key,
  });

  /// The slide's Markdown.
  final String markdown;

  /// Resolves a picture's target to an absolute path.
  final Future<String?> Function(String target) resolveEmbed;

  /// Follows a link's href.
  final ValueChanged<String>? onTapLink;

  /// Follows a wikilink's inner text.
  final ValueChanged<String>? onTapWikiLink;

  /// Whether the slide answers taps; a thumbnail does not.
  final bool live;

  @override
  State<SlideFrame> createState() => _SlideFrameState();
}

final class _SlideFrameState extends State<SlideFrame> {
  final ReadParser _parser = ReadParser();
  final MathCache _mathCache = MathCache();
  late SourceBuffer _buffer = SourceBuffer.fromText(widget.markdown);

  @override
  void didUpdateWidget(covariant SlideFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markdown != widget.markdown) {
      _buffer = SourceBuffer.fromText(widget.markdown);
    }
  }

  @override
  void dispose() {
    _mathCache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onTapLink = widget.onTapLink;
    final view = MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(slideTextScale)),
      child: MarkdownReadView(
        buffer: _buffer,
        parser: _parser,
        mathCache: _mathCache,
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
        embedResolver: widget.resolveEmbed,
        onTapLink: onTapLink == null
            ? null
            : (text, href) => onTapLink(href ?? ''),
        onTapWikiLink: widget.onTapWikiLink,
      ),
    );
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: ClipRect(
        child: FittedBox(
          child: SizedBox.fromSize(
            size: slideSize,
            child: widget.live
                ? view
                : IgnorePointer(child: ExcludeFocus(child: view)),
          ),
        ),
      ),
    );
  }
}
