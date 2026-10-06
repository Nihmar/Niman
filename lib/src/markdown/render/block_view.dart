/// One block, drawn from its node of the tree (`docs/dev/block-tree.md`,
/// phase 5).
///
/// The renderer is a mapping, not an engine: the tree has said what the
/// block holds — a quote and what is inside its marks, an item and its
/// blocks, a list inside either — and our inline parser what each leaf's
/// text is. What is left is which widget to use: the containers here, the
/// leaves in `LeafView`.
///
/// | node | drawn as |
/// |---|---|
/// | quote | a bar, and its blocks indented past it |
/// | callout | its box, its title, and its blocks under them |
/// | list | its items, one under the other |
/// | item | its marker, then its blocks at the item's indent |
/// | leaf | `LeafView` |
///
/// A block an item holds after its own — the paragraph after a blank line,
/// the quote under it — is a block of its own to the scanner, and stands
/// at its item's indent: one marker column per item around it.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/render/callout_box.dart';
import 'package:niman/src/markdown/render/inline_spans.dart';
import 'package:niman/src/markdown/render/item_marks.dart';
import 'package:niman/src/markdown/render/leaf_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/preview/math_cache.dart';

/// Draws one block of a note.
final class BlockView extends StatelessWidget {
  /// Creates a view of [read], a block read by `ReadParser`.
  const new({
    required this.read,
    required this.theme,
    required this.mathCache,
    this.availableWidth,
    this.onTapLink,
    this.onTapWikiLink,
    this.embedResolver,
    this.embedImages,
    this.onToggleTask,
    this.printed = false,
    super.key,
  });

  /// The block, read.
  final ReadBlock read;

  /// The typography and metrics it is drawn with.
  final MarkdownTheme theme;

  /// The math render cache, one per surface.
  final MathCache mathCache;

  /// How wide the pane is, so a display formula wider than it can be broken
  /// across lines instead of cut (#257). Null when the caller does not know
  /// — a test, an intrinsic pass — and the formula is drawn whole.
  final double? availableWidth;

  /// Called when a link is tapped, with its text and its target.
  final void Function(String text, String? href)? onTapLink;

  /// Called when a wikilink is tapped, with what is between its brackets.
  final void Function(String inner)? onTapWikiLink;

  /// Resolves an embed's target to a picture.
  final Future<String?> Function(String target)? embedResolver;

  /// The pictures an export already decoded, by the target as written:
  /// drawn on the first build, with no resolver and no frame to wait for
  /// (#63, H3).
  final Map<String, ui.Image>? embedImages;

  /// Called with a task item's line when its checkbox is tapped; null draws
  /// the box and leaves it alone.
  final void Function(int line)? onToggleTask;

  /// Whether the block is drawn on a page (an export) rather than on a
  /// screen.
  final bool printed;

  /// Past this many containers inside one another, one is drawn as its
  /// blocks alone, with no bar or marker column of its own: a pathological
  /// note's thousand quotes would be a page of indent.
  static const int _maxNesting = 8;

  @override
  Widget build(BuildContext context) {
    final block = read.block;
    // A footnote definition's blocks are drawn with the footnotes, at the
    // note's end, not where the definition stands; its blank lines are the
    // note's spacing, as they were.
    if (block.footnote != 0 && block.kind != BlockKind.blank) {
      return const SizedBox.shrink();
    }
    // The items the block stands in: an item's own block stands in its
    // parents, any other block in its item too.
    final items = block.kind == BlockKind.listItem
        ? block.listDepth
        : block.listDepth + 1;
    final indent = items <= 0 ? 0.0 : items * theme.listIndentPerLevel;
    final width = availableWidth;
    final drawn = _Drawer(
      view: this,
      scaler: MediaQuery.textScalerOf(context),
    ).node(read.node, theme, width == null ? null : width - indent, 0);
    return indent == 0
        ? drawn
        : Padding(
            padding: EdgeInsets.only(left: indent),
            child: drawn,
          );
  }
}

/// One drawing of a block's node and the nodes inside it.
final class _Drawer {
  new({required this.view, required this.scaler});

  final BlockView view;
  final TextScaler scaler;

  ReadBlock get read => view.read;

  late final InlineTaps _taps = (
    onTapLink: view.onTapLink,
    onTapWikiLink: view.onTapWikiLink,
    embedResolver: view.embedResolver,
    embedImages: view.embedImages,
  );

  /// [node] in [theme], [width] wide, [nesting] containers deep.
  Widget node(
    BlockNode node,
    MarkdownTheme theme,
    double? width,
    int nesting,
  ) => switch (node) {
    QuoteNode() => _quote(node, theme, width, nesting),
    ListNode(:final items) => _column([
      for (final item in items) _item(item, theme, width, nesting),
    ]),
    ItemNode() => _item(node, theme, width, nesting),
    // A definition's blocks are the footnotes' (see [BlockView.build]).
    FootnoteNode() => const SizedBox.shrink(),
    LeafNode() => LeafView(
      leaf: read.leaf(node),
      theme: theme,
      mathCache: view.mathCache,
      taps: _taps,
      footnoteNumbers: read.footnoteNumbers,
      availableWidth: width,
      printed: view.printed,
    ),
  };

  /// [nodes], one under the other.
  List<Widget> _all(
    List<BlockNode> nodes,
    MarkdownTheme theme,
    double? width,
    int nesting,
  ) => [for (final child in nodes) node(child, theme, width, nesting)];

  static Widget _column(List<Widget> children) => children.length == 1
      ? children.single
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );

  /// A blockquote: a bar, and its blocks indented past it, each drawn as
  /// any block is — a quote inside it with its own bar, a list with its
  /// bullets. A callout (#279) is its box, its title, and its blocks.
  Widget _quote(
    QuoteNode quote,
    MarkdownTheme theme,
    double? width,
    int nesting,
  ) {
    final inner = width == null ? null : width - theme.quoteIndentPerLevel;
    final children = _all(quote.children, theme.quoted, inner, nesting + 1);
    if (nesting >= BlockView._maxNesting) return _column(children);
    final callout = quote.callout;
    if (callout != null) {
      return CalloutBox(callout: callout, theme: theme, body: children);
    }
    // The bar is inside the quote's indent, as `live` draws it: a box adds
    // its border to its padding, and the text stood the bar's width further
    // in than past the bar in `live`.
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.quoteBar, width: theme.quoteBarWidth),
        ),
      ),
      padding: EdgeInsets.only(
        left: theme.quoteIndentPerLevel - theme.quoteBarWidth,
      ),
      child: children.isEmpty
          // An empty quote is a row of its bar.
          ? SizedBox(height: scaler.scale(theme.lineHeight))
          : _column(children),
    );
  }

  /// A list item: its marker, then its blocks at the item's indent.
  ///
  /// The marker is drawn, not read from the text, and it agrees with `live`
  /// on purpose: a bullet is a dot whatever the note wrote (`-`, `*` or
  /// `+`), an ordered item shows its place in the list, and a task item is
  /// a box rather than the `[x]` it was written as. The dot and the box are
  /// `live`'s own (`item_marks.dart`), in the same room: centred in the
  /// marker column, on the item's first row.
  Widget _item(ItemNode item, MarkdownTheme theme, double? width, int nesting) {
    final column = theme.listIndentPerLevel;
    final inner = width == null ? null : width - column;
    final children = _all(item.children, theme, inner, nesting + 1);
    if (nesting >= BlockView._maxNesting) return _column(children);
    final em = scaler.scale(theme.body.fontSize!);
    final task = read.taskOf(item);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: column,
          child: item.ordered && task == null
              ? _number('${item.ordinal}${item.delimiter}', em, theme)
              : _mark(item, em, theme, task: task),
        ),
        Expanded(
          child: children.isEmpty
              ? SizedBox(height: _firstRow(theme))
              : _column(children),
        ),
      ],
    );
  }

  /// How tall an item's first row is: one line of its text.
  double _firstRow(MarkdownTheme theme) {
    final painter = TextPainter(
      text: TextSpan(text: ' ', style: theme.body),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final row = painter.height;
    painter.dispose();
    return row;
  }

  /// An ordered item's number: on one row, ending a few pixels before the
  /// item's text, and running out to the left when it is wider than the
  /// column — a `10.` wrapped to two rows in it, and the numbers of a list
  /// did not line up. It is where `live` draws it (`live_decorations.dart`),
  /// in its colour.
  static Widget _number(String display, double em, MarkdownTheme theme) =>
      Padding(
        padding: EdgeInsets.only(right: em * numberGapEm),
        child: OverflowBox(
          maxWidth: double.infinity,
          // As tall as the number: the column's height is the item's to set.
          fit: OverflowBoxFit.deferToChild,
          alignment: Alignment.topRight,
          child: Text(
            display,
            style: theme.marker.copyWith(color: theme.markerDim),
            maxLines: 1,
            softWrap: false,
          ),
        ),
      );

  /// A bullet, or a task item's checkbox when [task] says whether it is
  /// ticked — the box ticked by a tap when [BlockView.onToggleTask] is
  /// given, the whole marker column being the target, so a finger need not
  /// find the box's own few pixels.
  Widget _mark(
    ItemNode item,
    double em,
    MarkdownTheme theme, {
    required bool? task,
  }) {
    final row = _firstRow(theme);
    final mark = CustomPaint(
      size: Size(theme.listIndentPerLevel, row),
      painter: ItemMarkPainter(
        em: em,
        row: row,
        color: theme.markerDim,
        task: task,
      ),
    );
    final toggle = view.onToggleTask;
    if (task == null || toggle == null) return mark;
    final line = item.line;
    return Semantics(
      checked: task,
      onTap: () => toggle(line),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => toggle(line),
          child: Align(alignment: Alignment.topLeft, child: mark),
        ),
      ),
    );
  }
}
