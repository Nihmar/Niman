/// The scanner's blocks made a tree (`docs/dev/block-tree.md`): the one
/// reading of a note's structure, which every surface can draw from.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/callout.dart';
import 'package:niman/src/markdown/footnote_syntax.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Where a line of a container's content starts in the note, and the
/// columns of a tab an item's indent ended inside that it carries on: they
/// count toward the indent of an item inside, and nothing else
/// (`LineSyntax.dedent`).
///
/// And whether the line is lazy — in a quote without its `>`, in an item
/// short of its indent — at this level or any around it: a lazy line is
/// no setext underline.
typedef _Origin = ({int line, int column, int leftOver, bool lazy});

/// A quote's content: how many quotes its first line opened, and the lines
/// inside their marks, with where each starts.
typedef _Quoted = ({int depth, List<String> lines, List<_Origin> starts});

/// Builds the tree of a text from the scanner's blocks.
///
/// The scanner keeps a note flat: a quote is one block, an item's own
/// block holds its marker line and the text that goes on with it, and the
/// blocks after it in the item say how deep they stand. The tree takes a
/// container block's inside — a quote's without its marks, an item's
/// without its marker and indent — and scans it again, as the read view
/// has always done for quotes; and it hangs each later block of a list
/// under the item its depth names.
final class BlockTree {
  new _({required this.appSyntax});

  /// Whether the app's own block syntax is read (`LineRules.appSyntax`).
  final bool appSyntax;

  /// The tree of [text], a whole note.
  ///
  /// [appSyntax] off reads it as the specifications do, without the app's
  /// frontmatter and display math.
  static List<BlockNode> of(String text, {bool appSyntax = true}) {
    final lines = text.split('\n');
    return BlockTree._(appSyntax: appSyntax)._build(text, [
      for (var at = 0; at < lines.length; at++)
        (line: at, column: 0, leftOver: 0, lazy: false),
    ]);
  }

  /// The node of [block], one of the blocks the scanner made of [buffer]
  /// — a whole note — read as the tree reads it: a quote's or an item's
  /// inside scanned again, a leaf mapped to the note's lines.
  ///
  /// What a surface that draws a block at a time takes from the tree: a
  /// block's own node, without the note's. What is not in it is what the
  /// tree hangs across blocks — the later blocks of an item, a construct
  /// an item's marker line opened and the lines after it go on with —
  /// which are nodes of their own blocks.
  static BlockNode ofBlock(
    Block block,
    SourceBuffer buffer, {
    bool appSyntax = true,
  }) {
    final tree = BlockTree._(appSyntax: appSyntax);
    final (local, starts) = _contentOf(block, buffer, _inNote);
    return block.kind == BlockKind.listItem
        ? tree._item(block, local, starts)
        : tree._node(block, local, starts);
  }

  /// Where line [line] of a note starts: at its own start.
  static _Origin _inNote(int line) =>
      (line: line, column: 0, leftOver: 0, lazy: false);

  /// The content of each quote built, by its outermost node: a block that
  /// goes on with the quote is read again with it.
  final Map<QuoteNode, _Quoted> _quoted = Map<QuoteNode, _Quoted>.identity();

  /// The blocks of [text], whose line `i` starts in the note at
  /// `origins[i]`.
  List<BlockNode> _build(String text, List<_Origin> origins) {
    final buffer = SourceBuffer.fromText(text);
    final scanner = BlockScanner(
      buffer,
      leftOver: [for (final origin in origins) origin.leftOver],
      lazy: [for (final origin in origins) origin.lazy],
      appSyntax: appSyntax,
    );
    _Origin origin(int line) => origins[line];
    final note = <BlockNode>[];
    // The footnote definition open where the scan is: the items in it are
    // its own.
    FootnoteNode? footnote;
    var roots = note;
    // The items open where the scan is, outermost first: a block at list
    // depth `d` stands in the first `d + 1`.
    final open = <ItemNode>[];
    for (final block in scanner.index.blocks) {
      if (block.footnote == Block.opensFootnote) {
        final label = FootnoteSyntax.opening(buffer.lineAt(block.startLine))!
            .$1;
        final children = <BlockNode>[];
        footnote = FootnoteNode(
          line: origins[block.startLine].line,
          label: label,
          children: children,
        );
        note.add(footnote);
        roots = footnote.children;
        open.clear();
      } else if (block.footnote == 0 && footnote != null) {
        footnote = null;
        roots = note;
        open.clear();
      }
      final (local, starts) = _contentOf(block, buffer, origin);
      if (block.kind == BlockKind.listItem) {
        final parents = block.listDepth.clamp(0, open.length);
        open.length = parents;
        final item = _item(block, local, starts);
        _addItem(parents == 0 ? roots : open[parents - 1].children, item);
        // Items its marker line opens inside it (`- - a`) are open after it.
        for (var inner = item; ;) {
          open.add(inner);
          final first = inner.children.isEmpty ? null : inner.children.first;
          if (first is! ListNode || first.line != item.line) break;
          inner = first.items.first;
        }
        continue;
      }
      open.length = (block.listDepth + 1).clamp(0, open.length);
      final into = open.isEmpty ? roots : open.last.children;
      if (!_continues(into, block, buffer, origin, local, starts)) {
        into.add(_node(block, local, starts));
      }
    }
    return note;
  }

  /// Whether [block] goes on with the last node of [into], which it then
  /// joins: a construct an item's marker line opened (`- > q`, a fence after
  /// the marker) is read in the item's content, and the lines after the
  /// marker line that go on with it are blocks of their own to the scanner —
  /// the state entering them says the construct is still open.
  bool _continues(
    List<BlockNode> into,
    Block block,
    SourceBuffer buffer,
    _Origin Function(int line) origins,
    List<String> local,
    List<_Origin> starts,
  ) {
    final entering = block.entering;
    if (into.isEmpty || entering == null) return false;
    // Indented code runs on over blank lines, which are its own: the
    // scanner makes the code after them a block of its own, the code block
    // is one.
    if (block.kind == BlockKind.indentedCode && entering.indentedCode) {
      var at = into.length - 1;
      while (at >= 0 &&
          into[at] is LeafNode &&
          (into[at] as LeafNode).kind == BlockKind.blank) {
        at--;
      }
      final code = at >= 0 ? into[at] : null;
      if (code is LeafNode &&
          code.kind == BlockKind.indentedCode &&
          at < into.length - 1) {
        into
          ..[at] = LeafNode(
            kind: BlockKind.indentedCode,
            lines: [
              ...code.lines,
              for (final blank in into.sublist(at + 1))
                ...(blank as LeafNode).lines,
              ..._spans(local, starts),
            ],
            leftOver: [
              ..._leftOverOf(code),
              for (final blank in into.sublist(at + 1))
                ..._leftOverOf(blank as LeafNode),
              for (final start in starts) start.leftOver,
            ],
          )
          ..removeRange(at + 1, into.length);
        return true;
      }
    }
    final last = into.last;
    if (last is QuoteNode && block.kind == BlockKind.quote) {
      final quoted = _quoted[last];
      if (quoted == null || entering.quoteDepth == 0) return false;
      // Inside the marks the quote has, not the ones this line has.
      final (more, from) = _contentOf(block, buffer, origins, quoted.depth);
      into.last = _quote(
        quoted.depth,
        [...quoted.lines, ...more],
        [...quoted.starts, ...from],
      );
      return true;
    }
    if (last is! LeafNode || last.kind != block.kind) return false;
    final open = switch (block.kind) {
      BlockKind.fencedCode => entering.fence != null,
      BlockKind.math => entering.math,
      BlockKind.html => entering.html != null,
      BlockKind.indentedCode => entering.indentedCode,
      BlockKind.table => entering.table,
      _ => false,
    };
    if (!open) return false;
    into.last = LeafNode(
      kind: last.kind,
      lines: [...last.lines, ..._spans(local, starts)],
      headingLevel: last.headingLevel,
      fenceInfo: last.fenceInfo,
      leftOver: [
        ..._leftOverOf(last),
        for (final start in starts) start.leftOver,
      ],
    );
    return true;
  }

  /// [leaf]'s left-over columns, one a line.
  static List<int> _leftOverOf(LeafNode leaf) => leaf.leftOver.isEmpty
      ? List<int>.filled(leaf.lines.length, 0)
      : leaf.leftOver;

  /// [block]'s lines in the coordinates of the container it stands in, its
  /// quote marks off ([BlockParser.contentText]) — [quoteDepth] of them
  /// when given — and where each starts in the note.
  static (List<String>, List<_Origin>) _contentOf(
    Block block,
    SourceBuffer buffer,
    _Origin Function(int line) origins, [
    int? quoteDepth,
  ]) {
    final first = buffer.lineAt(block.startLine);
    final local = <String>[];
    final starts = <_Origin>[];
    for (var line = block.startLine; line < block.endLine; line++) {
      final text = buffer.lineAt(line);
      final (prefix, columns) = quoteDepth == null
          ? BlockParser.linePrefix(
              block,
              text,
              BlockParser.listStripOf(
                block,
                first,
                line - block.startLine,
                text,
              ),
            )
          : BlockParser.quotePrefix(
              text,
              quoteDepth,
              BlockParser.itemPrefixLength(block, text),
            );
      local.add(text.substring(prefix));
      final origin = origins(line);
      // A quote's line without its `>` is the quote's lazily.
      final lazy =
          block.quoteDepth > 0 &&
          prefix <= BlockParser.itemPrefixLength(block, text);
      starts.add((
        line: origin.line,
        column: origin.column + prefix,
        leftOver: prefix == 0 ? origin.leftOver : columns,
        lazy: origin.lazy || lazy,
      ));
    }
    return (local, starts);
  }

  /// The node of [block], not an item, over [local] lines starting at
  /// [starts].
  BlockNode _node(Block block, List<String> local, List<_Origin> starts) {
    if (block.kind == BlockKind.quote) {
      return _quote(block.quoteDepth, local, starts);
    }
    return LeafNode(
      kind: block.kind,
      lines: _spans(local, starts),
      headingLevel: block.headingLevel,
      fenceInfo: block.fenceInfo,
      definition: block.definition != 0,
      leftOver: [for (final start in starts) start.leftOver],
    );
  }

  /// [depth] quotes around [lines], their content, scanned again.
  ///
  /// With the app's syntax, the innermost is a callout when its first line
  /// says so, and its content is the lines after that one: a callout's
  /// title is no paragraph its body could go on with (`> [!note]` /
  /// `>     code` is code in the callout, as Obsidian reads it).
  QuoteNode _quote(int depth, List<String> lines, List<_Origin> starts) {
    final callout = appSyntax ? Callout.of(lines.first) : null;
    final from = callout == null ? 0 : 1;
    final mark = callout == null ? 0 : Callout.markLength(lines.first);
    final written =
        callout != null && lines.first.substring(mark).trim().isNotEmpty;
    var node = QuoteNode(
      line: starts.first.line,
      callout: callout,
      title: written
          ? (
              line: starts.first.line,
              start: starts.first.column + mark,
              end: starts.first.column + lines.first.length,
            )
          : null,
      children: from >= lines.length
          ? <BlockNode>[]
          : _build(lines.sublist(from).join('\n'), starts.sublist(from)),
    );
    for (var level = 1; level < depth; level++) {
      node = QuoteNode(line: starts.first.line, children: [node]);
    }
    _quoted[node] = (depth: depth, lines: lines, starts: starts);
    return node;
  }

  /// Where [local] lines starting at [starts] stand in the note.
  static List<SourceSpan> _spans(List<String> local, List<_Origin> starts) => [
    for (var at = 0; at < local.length; at++)
      (
        line: starts[at].line,
        start: starts[at].column,
        end: starts[at].column + local[at].length,
      ),
  ];

  /// The item [block] opens, over [local] lines starting at [starts]: its
  /// marker, and its content — the marker line past the item's indent, the
  /// lines after it past that indent when they reach it and as they stand
  /// when they go on lazily — scanned again.
  ItemNode _item(Block block, List<String> local, List<_Origin> starts) {
    final first = local.first;
    final marker = LineSyntax.listMarkerOf(first)!;
    final item = LineSyntax.itemContent(first, marker);
    final indent = item.indent;
    final content = <String>[];
    final from = <_Origin>[];
    void add(int at, int cut, int leftOver, {bool lazy = false}) {
      content.add(local[at].substring(cut));
      from.add((
        line: starts[at].line,
        column: starts[at].column + cut,
        leftOver: leftOver,
        lazy: starts[at].lazy || lazy,
      ));
    }

    add(0, item.at, item.leftOver);
    for (var at = 1; at < local.length; at++) {
      final text = local[at];
      final leftOver = starts[at].leftOver;
      if (LineSyntax.columnsOf(text, leftOver) < indent) {
        add(at, 0, leftOver, lazy: true);
        continue;
      }
      final (rest, columns) = LineSyntax.dedent(text, indent);
      add(at, text.length - rest.length, columns);
    }
    final (start, width, _) = marker;
    final at = starts.first;
    return ItemNode(
      line: at.line,
      marker: (
        line: at.line,
        start: at.column + start,
        end: at.column + start + width,
      ),
      delimiter: first[start + width - 1],
      ordinal: block.listOrdinal,
      children: _withoutEmptyMarkerLine(_build(content.join('\n'), from)),
    );
  }

  /// [children] of an item without the blank line its marker line makes
  /// when nothing follows the marker: the item's content starts on the
  /// line after, and that line is no blank line between two of its blocks
  /// (`-` / `  foo` is a tight item).
  static List<BlockNode> _withoutEmptyMarkerLine(List<BlockNode> children) {
    final first = children.isEmpty ? null : children.first;
    if (first is! LeafNode || first.kind != BlockKind.blank) return children;
    final rest = first.lines.sublist(1);
    return [
      if (rest.isNotEmpty)
        LeafNode(
          kind: BlockKind.blank,
          lines: rest,
          leftOver: _leftOverOf(first).sublist(1),
        ),
      ...children.skip(1),
    ];
  }

  /// Adds [item] to [into]: to the list its last block is, past blank
  /// lines, when the item has that list's delimiter, or as a list of its
  /// own.
  static void _addItem(List<BlockNode> into, ItemNode item) {
    for (var at = into.length - 1; at >= 0; at--) {
      final node = into[at];
      if (node is LeafNode && node.kind == BlockKind.blank) continue;
      if (node is ListNode && node.items.first.delimiter == item.delimiter) {
        node.items.add(item);
        return;
      }
      break;
    }
    into.add(ListNode(items: [item]));
  }
}
