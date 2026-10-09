import 'package:flutter/material.dart';
import 'package:niman/src/export/slide_page.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

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
    required this.mathCache,
    this.onTapLink,
    this.onTapWikiLink,
    this.live = true,
    super.key,
  });

  /// The slide's Markdown.
  final String markdown;

  /// Resolves a picture's target to an absolute path.
  final Future<String?> Function(String target) resolveEmbed;

  /// The formulas typeset so far: one cache for the deck, which owns
  /// and disposes it (#672), not one per slide drawn.
  final MathCache mathCache;

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
  late SourceBuffer _buffer = SourceBuffer.fromText(widget.markdown);

  @override
  void didUpdateWidget(covariant SlideFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markdown != widget.markdown) {
      _buffer = SourceBuffer.fromText(widget.markdown);
    }
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
        mathCache: widget.mathCache,
        padding: slidePadding,
        embedResolver: widget.resolveEmbed,
        // A link with no target (`[x]()`) goes nowhere (#674): followed,
        // it resolved as a note named nothing.
        onTapLink: onTapLink == null
            ? null
            : (text, href) {
                if (href != null && href.trim().isNotEmpty) onTapLink(href);
              },
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
