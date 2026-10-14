import 'package:flutter/material.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/render/inline_spans.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/preview/math_cache.dart';

/// What stands in the text where a cloze's gap goes while it is read as
/// Markdown: a private-use character no note holds, swapped for the blank
/// once the spans are made.
const String _gapMark = '';

/// A question or an answer, drawn: its Markdown through the read view's
/// own inline renderer, so emphasis, code, math and pictures look in the
/// deck as they do in the note.
///
/// With [cloze] the card's gap ([FlashCard.clozeGap]) is drawn as a small
/// blank, the hidden word's place.
final class CardText extends StatelessWidget {
  /// Draws [markdown]; [mathCache] is the deck view's, shared by its rows.
  const new(
    this.markdown, {
    required this.mathCache,
    this.style,
    this.maxLines,
    this.cloze = false,
    super.key,
  });

  /// The text, as the note writes it.
  final String markdown;

  /// The formulas typeset so far.
  final MathCache mathCache;

  /// The style the text is drawn in; the note body's by default.
  final TextStyle? style;

  /// The most lines drawn, or null for all of them.
  final int? maxLines;

  /// Whether the text is a cloze's question, with its gap.
  final bool cloze;

  @override
  Widget build(BuildContext context) {
    final theme = markdownThemeOf(context);
    final base = style ?? theme.body;
    final text = cloze
        ? markdown.replaceAll(FlashCard.clozeGap, _gapMark)
        : markdown;
    final inline = ReadInline(text: text, nodes: InlineParser(text).parse());
    final spans = InlineSpans(
      theme: theme,
      base: base,
      mathCache: mathCache,
      taps: (
        onTapLink: null,
        onTapWikiLink: null,
        embedResolver: null,
        embedImages: null,
        deadLinks: null,
        linkPreview: null,
      ),
    ).of(inline);
    return Text.rich(
      TextSpan(
        style: base,
        children: cloze ? _withGaps(spans, context) : spans,
      ),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }

  /// [spans] with the gap mark of each piece of text turned into a blank.
  static List<InlineSpan> _withGaps(
    List<InlineSpan> spans,
    BuildContext context,
  ) {
    final out = <InlineSpan>[];
    for (final span in spans) {
      final text = span is TextSpan ? span.text : null;
      if (span is! TextSpan || text == null || !text.contains(_gapMark)) {
        out.add(span);
        continue;
      }
      final parts = text.split(_gapMark);
      for (var at = 0; at < parts.length; at++) {
        if (at > 0) out.add(_gap(context));
        if (parts[at].isNotEmpty) {
          out.add(TextSpan(text: parts[at], style: span.style));
        }
      }
    }
    return out;
  }

  static InlineSpan _gap(BuildContext context) => WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Container(
      key: const Key('card-gap'),
      width: 36,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}
