/// The read view's reading of a note: each block the scanner found, as its
/// node of the tree, its leaves' inline text read by our own parser
/// (`docs/dev/block-tree.md`, phase 5).
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/block_tree.dart';
import 'package:niman/src/markdown/html/code_html.dart';
import 'package:niman/src/markdown/html/leaf_text.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';
import 'package:niman/src/markdown/inline/link_references.dart';
import 'package:niman/src/markdown/leaf_inline.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_map.dart';
import 'package:niman/src/markdown/table/markdown_table.dart';
import 'package:niman/src/markdown/task_box.dart';

/// Reads blocks for the read view.
///
/// Holds one reading per block, dropped as soon as the buffer's revision
/// moves: a block is read when it is drawn, and kept only while it is
/// still true.
final class ReadParser {
  /// Creates a parser over its own cache.
  new();

  final Map<int, ReadBlock> _cache = <int, ReadBlock>{};
  SourceBuffer? _source;
  int _revision = -1;
  int _reads = 0;

  /// The definitions last scanned, or null before the first. Set from
  /// outside when they were scanned elsewhere (in the background), so the
  /// reading does not scan for them again.
  DocumentScope? scope;

  /// The numbers the footnotes are cited as, for [_numbersOf]'s scope.
  Map<String, int> _numbers = const <String, int>{};
  DocumentScope? _numbered;

  /// How many blocks have actually been read, for the tests and the bench:
  /// the point of the cache is that this stays near the visible count.
  int get parseCount => _reads;

  /// [block] of [buffer], read; cached until the buffer changes.
  ReadBlock of(Block block, SourceBuffer buffer) {
    if (!identical(_source, buffer) || _revision != buffer.revision) {
      _cache.clear();
      _source = buffer;
      _revision = buffer.revision;
    }
    final key = Object.hash(block.startLine, block.endLine, block.kind);
    final cached = _cache[key];
    if (cached != null) return cached;
    return _cache[key] = read(block, buffer);
  }

  /// [block] of [buffer], read without consulting the cache, with
  /// [scope]'s definitions — given by a reader that keeps them current
  /// itself, as `live` does, line by line — or the note's.
  ReadBlock read(Block block, SourceBuffer buffer, {DocumentScope? scope}) =>
      _read(block, buffer, scope ?? _scopeOf(buffer));

  /// [text] — Markdown of its own, a footnote's body — its blocks read with
  /// [scope]'s definitions, or its own; the blank lines it ends with left
  /// out.
  List<ReadBlock> ofText(String text, {DocumentScope? scope}) {
    final buffer = SourceBuffer.fromText(text);
    final definitions = scope ?? DocumentScope.scan(buffer, buffer.revision);
    final blocks = <Block>[...BlockScanner(buffer).index.blocks];
    while (blocks.isNotEmpty && blocks.last.kind == BlockKind.blank) {
      blocks.removeLast();
    }
    return [for (final block in blocks) _read(block, buffer, definitions)];
  }

  /// The footnotes of [buffer], in citation order: the section the read
  /// view ends a note with.
  List<Footnote> footnotesOf(SourceBuffer buffer) => _scopeOf(buffer).footnotes;

  ReadBlock _read(Block block, SourceBuffer buffer, DocumentScope scope) {
    _reads++;
    return _Reader(
      buffer: buffer,
      block: block,
      scope: scope,
      numbers: _numbersOf(scope),
    ).read();
  }

  /// The document-scoped definitions, scanned once per revision.
  DocumentScope _scopeOf(SourceBuffer buffer) {
    final cached = scope;
    if (cached != null &&
        identical(cached.source, buffer) &&
        cached.revision == buffer.revision) {
      return cached;
    }
    return scope = DocumentScope.scan(buffer, buffer.revision);
  }

  /// The number each footnote of [scope] is cited as — its place in the
  /// section, counting from one — by its normalized label.
  Map<String, int> _numbersOf(DocumentScope scope) {
    if (identical(_numbered, scope)) return _numbers;
    _numbered = scope;
    final numbers = <String, int>{};
    for (final footnote in scope.footnotes) {
      numbers.putIfAbsent(
        LinkReferences.normalize(footnote.label),
        () => numbers.length + 1,
      );
    }
    return _numbers = numbers;
  }
}

/// One block's reading.
final class _Reader {
  new({
    required this.buffer,
    required this.block,
    required this.scope,
    required this.numbers,
  });

  final SourceBuffer buffer;
  final Block block;
  final DocumentScope scope;
  final Map<String, int> numbers;

  final Map<LeafNode, ReadLeaf> _leaves = Map<LeafNode, ReadLeaf>.identity();
  final Map<ItemNode, bool> _tasks = Map<ItemNode, bool>.identity();
  final Map<QuoteNode, ReadInline> _titles =
      Map<QuoteNode, ReadInline>.identity();

  ReadBlock read() {
    final node = BlockTree.ofBlock(block, buffer);
    _visit(node, top: true);
    return ReadBlock(
      block: block,
      node: node,
      leaves: _leaves,
      tasks: _tasks,
      titles: _titles,
      footnoteNumbers: numbers,
    );
  }

  /// Reads [node]'s leaves; [top] when it is the block's own node, and
  /// [item] the item whose first block it is.
  void _visit(BlockNode node, {bool top = false, ItemNode? item}) {
    switch (node) {
      case QuoteNode(:final children, :final title):
        if (title != null) {
          final (:text, :map) = LeafInline.paragraph([title], buffer.lineAt);
          _titles[node] = _inline(text, map);
        }
        children.forEach(_visit);
      case FootnoteNode(:final children):
        children.forEach(_visit);
      case ItemNode(:final children):
        for (var at = 0; at < children.length; at++) {
          _visit(children[at], item: at == 0 ? node : null);
        }
      case ListNode(:final items):
        items.forEach(_visit);
      case LeafNode():
        _leaves[node] = _leaf(node, top: top, item: item);
    }
  }

  ReadLeaf _leaf(LeafNode node, {required bool top, ItemNode? item}) {
    final lines = [
      for (final span in node.lines)
        buffer.lineAt(span.line).substring(span.start, span.end),
    ];
    final entering = top ? block.entering : null;
    switch (node.kind) {
      case BlockKind.paragraph:
        var (:text, :map) = LeafInline.paragraph(node.lines, buffer.lineAt);
        if (text.startsWith('[')) {
          final rest = LinkReferences.parseInto(
            text,
            <String, LinkReference>{},
          );
          text = text.substring(rest);
          map = map.from(rest);
        }
        if (item != null) {
          final task = TaskBox.of(text);
          if (task != null) {
            _tasks[item] = task.checked;
            text = text.substring(task.length);
            map = map.from(task.length);
          }
        }
        return ReadLeaf(node: node, lines: lines, inline: _inline(text, map));
      case BlockKind.heading:
        final (:text, :map) = lines.length == 1
            ? LeafInline.atxHeading(node.lines.single, buffer.lineAt)
            : LeafInline.setextHeading(node.lines, buffer.lineAt);
        return ReadLeaf(node: node, lines: lines, inline: _inline(text, map));
      case BlockKind.table:
        return _table(node, lines, continued: entering?.table ?? false);
      case BlockKind.fencedCode:
        final fence = entering?.fence;
        final parts = CodeHtml.fenceParts(
          LeafText.withLeftOver(node, lines, opening: fence == null),
          open: fence == null ? null : (fence.char, fence.length, fence.indent),
        );
        return ReadLeaf(
          node: node,
          lines: lines,
          code: parts.code,
          continued: fence != null,
          closed: parts.closed,
        );
      case BlockKind.indentedCode:
        return ReadLeaf(
          node: node,
          lines: lines,
          code: CodeHtml.indentedCode(
            lines,
            starts: [
              for (final span in node.lines)
                LineSyntax.columnsTo(buffer.lineAt(span.line), span.start),
            ],
            leftOver: node.leftOver,
          ),
        );
      case BlockKind.html || BlockKind.math:
        return ReadLeaf(
          node: node,
          lines: lines,
          code: lines,
          continued:
              entering != null &&
              (node.kind == BlockKind.math
                  ? entering.math
                  : entering.html != null),
        );
      case BlockKind.thematicBreak ||
          BlockKind.blank ||
          BlockKind.frontmatter ||
          BlockKind.quote ||
          BlockKind.listItem:
        return ReadLeaf(node: node, lines: lines);
    }
  }

  /// A table's rows, each cell read; [continued] when its lines go on
  /// with a table a block above opened, and have no head of their own.
  ReadLeaf _table(
    LeafNode node,
    List<String> lines, {
    required bool continued,
  }) {
    final head = continued || lines.length < 2
        ? null
        : LeafInline.cells(node.lines.first, buffer.lineAt);
    final body = head == null ? node.lines : node.lines.skip(2);
    final columns = head?.length;
    List<ReadInline> row(List<MappedText> cells) => [
      for (var at = 0; at < (columns ?? cells.length); at++)
        if (at < cells.length)
          _inline(cells[at].text, cells[at].map)
        else
          _inline('', SourceMap()),
    ];
    return ReadLeaf(
      node: node,
      lines: lines,
      continued: head == null,
      aligns: head == null
          ? const <TableAlign>[]
          : MarkdownTable.alignsOf(lines[1]),
      rows: [
        if (head != null) row(head),
        for (final span in body) row(LeafInline.cells(span, buffer.lineAt)),
      ],
    );
  }

  ReadInline _inline(String text, SourceMap map) => ReadInline(
    text: text,
    map: map,
    nodes: text.isEmpty
        ? const []
        : InlineParser(
            text,
            references: scope.references,
            footnotes: scope.footnoteKeys,
          ).parse(),
  );
}
