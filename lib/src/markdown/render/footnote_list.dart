/// The section a note ends with: its footnotes, and the way back to each.
///
/// The package ends a document with a list of the footnote definitions it
/// collected, numbered in the order the references are cited and carrying a
/// backlink on each. The engine parses a block at a time, so the definitions
/// never reach the block that cites them and no single block can draw this —
/// which is why it is a section of its own, appended to the read view, built
/// from the definitions `DocumentScope` scanned.
///
/// Its text is the package's text on purpose — `1. body ↩` — because the gate
/// that decides whether this engine may replace the preview compares what a
/// reader sees. A prettier rendering would be a different rendering, and the
/// difference belongs to a commit that also changes the preview.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';

/// One footnote, drawn: its number, its body, and the way back.
final class FootnoteRow extends StatelessWidget {
  /// Draws the [number]-th footnote.
  const new({
    required this.footnote,
    required this.number,
    required this.theme,
    this.onTapBack,
    super.key,
  });

  /// The definition.
  final Footnote footnote;

  /// Where it sits in the list, counting from one.
  final int number;

  /// The typography it is drawn with, the note's own.
  final MarkdownTheme theme;

  /// Called when the backlink is tapped.
  final VoidCallback? onTapBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: theme.blockSpacing * 0.5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: theme.listIndentPerLevel,
          child: Text('$number.', style: theme.marker),
        ),
        Expanded(child: Text(footnote.body, style: theme.quote)),
        // The package's own arrow, so the two renderings say the same thing to
        // a reader and to the comparison.
        TextButton(
          onPressed: onTapBack,
          child: Text('\u21A9', style: theme.link),
        ),
      ],
    ),
  );
}

/// The rule that separates a note from its footnotes.
final class FootnoteDivider extends StatelessWidget {
  /// Draws the rule above the section.
  const new({required this.theme, super.key});

  /// The typography it is drawn with.
  final MarkdownTheme theme;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: theme.blockSpacing * 2),
    child: Divider(color: theme.rule, thickness: theme.ruleThickness),
  );
}

/// The definitions, drawn as the list the note ends with.
///
/// The whole list at once, which is what an export wants — it draws the note
/// whether or not anyone is looking. The read view draws the same rows through
/// a lazy sliver instead, because a note's footnotes are as many as its author
/// wrote and a section that lays them all out at the top of the frame costs the
/// frame.
final class FootnoteList extends StatelessWidget {
  /// Draws [footnotes], numbered from one.
  const new({
    required this.footnotes,
    required this.theme,
    this.onTapBack,
    super.key,
  });

  /// The definitions, in citation order.
  final List<Footnote> footnotes;

  /// The typography they are drawn with, the note's own.
  final MarkdownTheme theme;

  /// Called with a label when its backlink is tapped.
  final void Function(Footnote footnote)? onTapBack;

  @override
  Widget build(BuildContext context) {
    if (footnotes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FootnoteDivider(theme: theme),
        for (var at = 0; at < footnotes.length; at++)
          FootnoteRow(
            footnote: footnotes[at],
            number: at + 1,
            theme: theme,
            onTapBack: onTapBack == null
                ? null
                : () => onTapBack!(footnotes[at]),
          ),
      ],
    );
  }
}
