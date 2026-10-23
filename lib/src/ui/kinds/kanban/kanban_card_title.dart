import 'package:flutter/material.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/kanban/card_text.dart';
import 'package:niman/src/kanban/kanban_card.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/render/inline_spans.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/preview/math_cache.dart';

/// A card's title as the read view draws inline text (#1167): links,
/// wikilinks and formulas as they are there, without the tags and the due
/// date, which are chips. It wraps; a tap on a link follows it, a tap
/// elsewhere goes to the card.
final class KanbanCardTitle extends StatelessWidget {
  /// The title of [card]; links go through [host].
  const new({
    required this.card,
    required this.host,
    required this.mathCache,
    super.key,
  });

  /// The card.
  final KanbanCard card;

  /// The note's window, which follows links.
  final NoteKindHost host;

  /// The formulas typeset so far.
  final MathCache mathCache;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final markdown = markdownThemeOf(context);
    final done = card.checked ?? false;
    final base = (theme.textTheme.bodyMedium ?? markdown.body).copyWith(
      decoration: done ? TextDecoration.lineThrough : null,
      color: done ? theme.colorScheme.onSurfaceVariant : null,
    );
    final text = cardShownTitle(card.title);
    final span = TextSpan(
      style: base,
      children: InlineSpans(
        theme: markdown,
        base: base,
        mathCache: mathCache,
        taps: (
          onTapLink: (_, href) {
            if (href != null && href.trim().isNotEmpty) {
              host.openLink(context, href);
            }
          },
          onTapWikiLink: (inner) => host.openWikiLink(context, inner),
          embedResolver: null,
          embedImages: null,
          deadLinks: null,
          linkPreview: null,
        ),
      ).of(ReadInline(text: text, nodes: InlineParser(text).parse())),
    );
    return Text.rich(span, key: const Key('kanban-card-title'));
  }
}
