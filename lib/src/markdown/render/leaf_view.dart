/// One leaf of a block, drawn: a paragraph, a heading, a code block, a
/// formula, a table, a rule.
///
/// | leaf | drawn as |
/// |---|---|
/// | paragraph, heading | rich text from its inline nodes |
/// | fenced or indented code | a box of monospace lines, fences its padding |
/// | HTML | its source in the same box, a row per line, as `live` draws it |
/// | math | the display typesetter |
/// | table | a real table, each cell its inline nodes |
/// | thematic break | a row with a rule across its middle, as `live` draws it |
/// | frontmatter | nothing: it is metadata |
/// | blank | one of `live`'s rows per blank line |
///
/// A leaf leaves no room of its own around it: the space between two is
/// the blank lines the note has between them, drawn as `live` draws them,
/// so the two modes are one page and a glyph does not move when it flips.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/links/dead_links.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/render/code_copy.dart';
import 'package:niman/src/markdown/render/diagram_view.dart';
import 'package:niman/src/markdown/render/inline_spans.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/math_text.dart';
import 'package:niman/src/markdown/render/read_table.dart';
import 'package:niman/src/markdown/render/todo_block_scope.dart';
import 'package:niman/src/preview/code_highlight.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_widget.dart';

/// Draws one leaf.
final class LeafView extends StatelessWidget {
  /// A view of [leaf].
  const new({
    required this.leaf,
    required this.theme,
    required this.mathCache,
    required this.taps,
    this.footnoteNumbers = const <String, int>{},
    this.availableWidth,
    this.printed = false,
    super.key,
  });

  /// The leaf, read.
  final ReadLeaf leaf;

  /// The typography and metrics it is drawn with.
  final MarkdownTheme theme;

  /// The math render cache, one per surface.
  final MathCache mathCache;

  /// What a tap on a link, a wikilink or an embed calls.
  final InlineTaps taps;

  /// The number each footnote is cited as, by its normalized label.
  final Map<String, int> footnoteNumbers;

  /// How wide the pane is, so a display formula wider than it can be broken
  /// across lines instead of cut (#257).
  final double? availableWidth;

  /// Whether the leaf is drawn on a page (an export) rather than on a
  /// screen: a diagram carries no full-screen button there.
  final bool printed;

  @override
  Widget build(BuildContext context) {
    final dead = taps.deadLinks;
    // The links that name nothing are resolved apart from the page and arrive
    // when they do (#847): the leaf draws again by itself, as the leaves
    // around it stand.
    if (dead == null || leaf.inline == null && leaf.rows.isEmpty) {
      return _drawn(context);
    }
    return ValueListenableBuilder<DeadLinks>(
      valueListenable: dead,
      builder: (context, _, _) => _drawn(context),
    );
  }

  Widget _drawn(BuildContext context) => switch (leaf.kind) {
    BlockKind.paragraph => _rich(theme.body, hideBlockId: true),
    BlockKind.heading => _heading(context),
    BlockKind.fencedCode => _fenced(context),
    BlockKind.indentedCode => _code(context, null),
    BlockKind.math => _math(),
    BlockKind.table => _table(),
    BlockKind.thematicBreak => _rule(context),
    BlockKind.blank => SizedBox(height: leaf.lines.length * _row(context)),
    BlockKind.html => _html(),
    BlockKind.div => SizedBox(
      height: MediaQuery.textScalerOf(context).scale(theme.divBand),
    ),
    BlockKind.frontmatter ||
    BlockKind.quote ||
    BlockKind.listItem => const SizedBox.shrink(),
  };

  /// How tall one of `live`'s rows is: a line of prose, at the size the
  /// note's text is read at.
  double _row(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(theme.lineHeight);

  InlineSpans _spans(TextStyle base) => InlineSpans(
    theme: theme,
    base: base,
    mathCache: mathCache,
    taps: taps,
    availableWidth: availableWidth,
    footnoteNumbers: footnoteNumbers,
    deadLinks: taps.deadLinks?.value ?? DeadLinks.none,
  );

  /// The leaf's inline text, in [style]: nothing when it has none — a
  /// paragraph of link reference definitions is syntax, not prose.
  ///
  /// A paragraph's trailing ` ^id` is left out of what is drawn ([hideBlockId],
  /// #844): the id is the block's name for a `[[note#^id]]` link, not prose.
  Widget _rich(TextStyle style, {bool hideBlockId = false}) {
    final inline = leaf.inline;
    if (inline == null || inline.isEmpty) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        children: _spans(style).of(inline, hideBlockId: hideBlockId),
        style: style,
      ),
      textAlign: TextAlign.start,
    );
  }

  /// A heading, at its level's size. A setext heading's underline is a row
  /// of the heading, as `live` has it, with nothing drawn on it: drawn as
  /// its text, it put `====` on screen; left out, the page stood a row
  /// short of `live`'s from there on.
  Widget _heading(BuildContext context) {
    final style = theme.heading(leaf.node.headingLevel);
    final inline = leaf.inline;
    if (leaf.lines.length < 2 || inline == null || inline.isEmpty) {
      return _rich(style, hideBlockId: true);
    }
    return Text.rich(
      TextSpan(
        children: [
          ..._spans(style).of(inline, hideBlockId: true),
          const TextSpan(text: '\n'),
        ],
        style: style,
      ),
    );
  }

  /// A fenced block: a Mermaid diagram or a list of tasks when its language
  /// says so, code otherwise.
  Widget _fenced(BuildContext context) {
    final language = leaf.node.fenceInfo;
    // A `todo` fence is its question, empty or not: the list it asks for,
    // where the note's tasks are at hand, and the code it is where not.
    if (language != null &&
        language.toLowerCase() == 'todo' &&
        !leaf.continued &&
        leaf.closed) {
      final list = TodoBlockScope.of(context)
          ?.build(context, source: leaf.code.join('\n'), theme: theme);
      if (list != null) return list;
    }
    if (language != null &&
        language.toLowerCase() == 'mermaid' &&
        !leaf.continued) {
      final content = leaf.code.join('\n');
      if (content.trim().isNotEmpty) {
        // A tap reads the diagram, and leaves the read view where it is:
        // only `live`, where the source is, shows it on a tap.
        return BlockDiagramView(
          source: content,
          theme: theme,
          fullScreen: !printed,
        );
      }
    }
    return _code(context, language);
  }

  /// A code block: a filled box of monospace lines, the code coloured by
  /// the language the fence names.
  ///
  /// The box is `live`'s: its code a padding in from the sides, and a
  /// fence's row above and below it — the rows `live` draws the fences on,
  /// hidden, inside its box — so the code's rows land on `live`'s. A fence
  /// an item's marker line opened is two boxes, the item's and the one of
  /// the lines after it: the first has no end, the second no top.
  Widget _code(BuildContext context, String? language) {
    final fenced = leaf.kind == BlockKind.fencedCode;
    final opened = fenced && !leaf.continued;
    final closed = fenced && leaf.closed;
    final row = _row(context);
    const round = Radius.circular(4);
    final top = !fenced || opened ? round : Radius.zero;
    final bottom = !fenced || closed ? round : Radius.zero;
    final text = leaf.code.join('\n');
    final box = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.codeBackground,
        borderRadius: BorderRadius.only(
          topLeft: top,
          topRight: top,
          bottomLeft: bottom,
          bottomRight: bottom,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        theme.codePadding,
        opened ? row : 0,
        theme.codePadding,
        closed ? row : 0,
      ),
      // A fence with nothing between its lines has no row of code.
      child: leaf.code.isEmpty
          ? null
          : language == null || language.isEmpty
          ? Text(text, style: theme.code)
          : Text.rich(
              CodeHighlighter(
                language: language,
                theme: theme.codeHighlight,
              ).format(text),
              // A fence with no palette (the fallback theme, before the
              // first build) still gets the monospace metrics.
              style: theme.code,
            ),
    );
    // A button copies the code (#541); a printed page has nothing to press.
    if (printed || leaf.code.isEmpty) return box;
    return CodeCopyFrame(code: () => text, child: box);
  }

  /// An HTML block: its source, as written, in a code block's box — a row
  /// per line and a padding in from the sides, where `live` draws it.
  Widget _html() => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: theme.codeBackground,
      borderRadius: BorderRadius.circular(4),
    ),
    padding: EdgeInsets.symmetric(horizontal: theme.codePadding),
    child: Text(leaf.code.join('\n'), style: theme.code),
  );

  /// A display formula, centered, half a spacing above and below it as
  /// `live` sets it (`liveFormulaUnder`).
  ///
  /// The [Center] is load-bearing, not decoration: a leaf is laid out with
  /// a **tight** width, and the katex painter starts its ink at the canvas
  /// origin whatever size it is handed, which put every formula at the
  /// column's left edge (#252). Center hands the view its own width back.
  Widget _math() {
    final tex = displayTexOf(leaf.code.join('\n'));
    // The `$$` an item's marker line opened, alone: the formula is the
    // lines after it, a block of their own.
    if (tex.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.blockSpacing / 2),
      child: Center(
        child: BlockMathView(
          cache: mathCache,
          maxWidth: availableWidth,
          tex: tex,
          style: mathStyleFor(theme.body),
        ),
      ),
    );
  }

  /// A thematic break: a row, the rule across its middle, where `live`
  /// draws it.
  Widget _rule(BuildContext context) => SizedBox(
    height: _row(context),
    child: Center(
      child: Container(height: theme.ruleThickness, color: theme.rule),
    ),
  );

  /// A table: its cells, each its inline nodes, fitted to the pane as `live`
  /// fits it (#1108).
  Widget _table() => ReadTable(
    rows: leaf.rows,
    aligns: leaf.aligns,
    head: !leaf.continued,
    theme: theme,
    spansOf: _spans,
    footnoteNumbers: footnoteNumbers,
    availableWidth: availableWidth,
  );
}
