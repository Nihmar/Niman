/// One block of a note as the read view draws it: its node of the tree,
/// each leaf's lines and, for the leaves with inline text, our inline
/// parser's nodes (`docs/dev/block-tree.md`, phase 5). `ReadParser` makes
/// it.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/links/parser.dart' show wikiDisplayText;
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/table/markdown_table.dart';

/// A piece of inline text, read: what it says and its nodes.
@immutable
final class ReadInline {
  /// [text] read into [nodes].
  const new({required this.text, required this.nodes});

  /// The text, as the inline parser was given it.
  final String text;

  /// Its nodes, each over its range of [text].
  final List<InlineNode> nodes;

  /// Whether there is nothing to draw.
  bool get isEmpty => nodes.isEmpty;

  /// What a reader sees of it as plain text: a formula's tex, a
  /// wikilink's display text, an image's description, a line break a
  /// space.
  String get plainText {
    final out = StringBuffer();
    final stack = <InlineNode>[...nodes.reversed];
    while (stack.isNotEmpty) {
      switch (stack.removeLast()) {
        case TextNode(:final text):
          out.write(text);
        case CodeNode(:final code):
          out.write(code);
        case HtmlNode(:final html):
          out.write(html);
        case SoftBreakNode() || HardBreakNode():
          out.write(' ');
        case FootnoteRefNode():
          break;
        case MathNode(:final tex):
          out.write(tex);
        case WikiLinkNode(:final inner):
          out.write(wikiDisplayText(inner));
        case TagNode(:final name):
          out.write('#$name');
        case InlineContainer(:final children):
          stack.addAll(children.reversed);
      }
    }
    return out.toString();
  }
}

/// A leaf of a block, read.
@immutable
final class ReadLeaf {
  /// [node], whose lines are [lines].
  const new({
    required this.node,
    required this.lines,
    this.inline,
    this.rows = const <List<ReadInline>>[],
    this.aligns = const <TableAlign>[],
    this.code = const <String>[],
    this.continued = false,
    this.closed = false,
  });

  /// The leaf in the tree.
  final LeafNode node;

  /// Its lines as its container reads them: its quote marks, its items'
  /// indents off.
  final List<String> lines;

  /// A paragraph's or a heading's inline text, read: a paragraph's without
  /// the link reference definitions it starts with, and without an item's
  /// task box. Null for the other kinds.
  final ReadInline? inline;

  /// A table's rows, its head first, its delimiter row left out; each row
  /// as many cells as the head.
  final List<List<ReadInline>> rows;

  /// A table's columns' alignments.
  final List<TableAlign> aligns;

  /// A code block's code lines — a fence's without its fences, an
  /// indented block's without its indent — and an HTML block's or a math
  /// block's lines.
  final List<String> code;

  /// Whether the leaf goes on with a construct a block above it opened —
  /// the lines of a fence an item's marker line opened, which are a block
  /// of their own to the scanner: it has no opening line, nor a table's
  /// head.
  final bool continued;

  /// Whether a fence's last line closes it: a note may never close one.
  final bool closed;

  /// What it is.
  BlockKind get kind => node.kind;
}

/// One block, read.
@immutable
final class ReadBlock {
  /// [block], whose node is [node].
  const new({
    required this.block,
    required this.node,
    required this._leaves,
    required this._tasks,
    required this.footnoteNumbers,
  });

  /// The scanner's block.
  final Block block;

  /// Its node of the tree.
  final BlockNode node;

  final Map<LeafNode, ReadLeaf> _leaves;
  final Map<ItemNode, bool> _tasks;

  /// The number each footnote is cited as, by its normalized label.
  final Map<String, int> footnoteNumbers;

  /// [leaf], read.
  ReadLeaf leaf(LeafNode leaf) => _leaves[leaf]!;

  /// Whether [item] is a task, and ticked; null when it is not one.
  bool? taskOf(ItemNode item) => _tasks[item];

  /// What a reader sees of the block as one line of plain text, for a
  /// passage quoted out of it (#284): its leaves' text, joined by a space.
  String get plainText {
    final parts = <String>[];
    void add(BlockNode node) {
      switch (node) {
        case QuoteNode(:final children, :final callout):
          if (callout != null) parts.add(callout.title);
          children.forEach(add);
        case ItemNode(:final children) || FootnoteNode(:final children):
          children.forEach(add);
        case ListNode(:final items):
          items.forEach(add);
        case LeafNode():
          final read = leaf(node);
          final inline = read.inline;
          if (inline != null) {
            parts.add(inline.plainText);
          } else if (read.rows.isNotEmpty) {
            for (final row in read.rows) {
              parts.addAll(row.map((cell) => cell.plainText));
            }
          } else if (_isCode(node.kind)) {
            parts.add(read.code.join(' '));
          }
      }
    }

    add(node);
    return parts
        .map((part) => part.replaceAll(_blank, ' ').trim())
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  static bool _isCode(BlockKind kind) =>
      kind == BlockKind.fencedCode ||
      kind == BlockKind.indentedCode ||
      kind == BlockKind.math;

  static final RegExp _blank = RegExp(r'\s+');
}
