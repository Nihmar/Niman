/// The section a note ends with: its footnotes, and the way back to each.
///
/// The package ends a document with a list of the footnote definitions it
/// collected, numbered in the order the references are cited and carrying a
/// backlink on each. The engine parses a block at a time, so the definitions
/// never reach the block that cites them and no single block can draw this —
/// which is why it is a section of its own, appended to the read view, built
/// from the definitions `DocumentScope` scanned.
///
/// Its text is the package's — `1. body ↩` — with the body drawn as the
/// package draws it too: as prose, its inline syntax rendered.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/block_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// One footnote, drawn: its number, its body, and the way back.
///
/// The body is prose, parsed and drawn as a paragraph of the note is — its
/// formulas typeset, its emphasis stressed — in the quote's colour: it was
/// drawn as its source, `$x^2$` and `*big*` as written (device screenshot
/// 2026-09-23). The number is set as a list's, and the way back is the
/// arrow alone: a button's minimum height stood a row of blank between
/// every two footnotes.
final class FootnoteRow extends StatelessWidget {
  /// Draws the [number]-th footnote.
  const new({
    required this.footnote,
    required this.number,
    required this.theme,
    required this.parser,
    required this.mathCache,
    this.scope,
    this.onTapBack,
    super.key,
  });

  /// The definition.
  final Footnote footnote;

  /// Where it sits in the list, counting from one.
  final int number;

  /// The typography it is drawn with, the note's own.
  final MarkdownTheme theme;

  /// The parser its body is read with.
  final BlockParser parser;

  /// The math render cache, one per surface.
  final MathCache mathCache;

  /// The note's link and footnote definitions, for what the body cites.
  final DocumentScope? scope;

  /// Called when the backlink is tapped.
  final VoidCallback? onTapBack;

  @override
  Widget build(BuildContext context) {
    final body = footnote.body;
    final parsed = parser.parseText(
      Block(
        kind: BlockKind.paragraph,
        startLine: 0,
        endLine: '\n'.allMatches(body).length + 1,
      ),
      body,
      () => scope ?? DocumentScope.scan(SourceBuffer.fromText(body), 0),
    );
    final em = MediaQuery.textScalerOf(context).scale(theme.body.fontSize!);
    return Padding(
      padding: EdgeInsets.only(top: theme.blockSpacing * 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: theme.listIndentPerLevel,
            child: Text(
              '$number.',
              style: theme.marker.copyWith(color: theme.markerDim),
            ),
          ),
          Expanded(
            child: BlockView(
              parsed: parsed,
              theme: theme.quoted,
              mathCache: mathCache,
              scope: scope,
            ),
          ),
          // The package's own arrow, so the two renderings say the same
          // thing to a reader and to the comparison.
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapBack,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: em * 0.5),
                child: Text('\u21A9', style: theme.link),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    required this.parser,
    required this.mathCache,
    this.scope,
    this.onTapBack,
    super.key,
  });

  /// The parser the bodies are read with.
  final BlockParser parser;

  /// The math render cache, one per surface.
  final MathCache mathCache;

  /// The note's link and footnote definitions.
  final DocumentScope? scope;

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
            parser: parser,
            mathCache: mathCache,
            scope: scope,
            onTapBack: onTapBack == null
                ? null
                : () => onTapBack!(footnotes[at]),
          ),
      ],
    );
  }
}
