/// A note's tags and links, read the way the unified engine reads the note.
///
/// What the index keeps of a note besides its text is its inline tags and its
/// links, and nothing else a parse makes. A whole-note parse pays for every
/// run of every line: two minutes on the 247 MB stress note, for the 3 % of
/// its lines that have a `#` or a `[` (`docs/records/huge-notes.md`, item 8).
/// So only a block that can hold one is read:
///
/// * the **block scan** says which blocks have inline text at all — never a
///   fence, a formula, the frontmatter or an HTML block;
/// * a block with no `#` and no `[` holds none;
/// * any other is read as the read view reads it (`ReadParser`: the tree,
///   our inline parser), and its tags, wikilinks, embeds, links and images
///   are its nodes — a code span or a formula holds none of them.
///
/// The same reading draws the note, so what the index calls a link is what
/// the note shows as one.
library;

import 'package:niman/src/frontmatter/parser.dart' show normalizeTag;
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/app_syntax.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The inline tags, the links and the embeds of one note.
final class NoteReferences {
  /// Creates the references of a note.
  const new({
    required this.tags,
    required this.links,
    this.embeds = const <ParsedLink>[],
  });

  /// Its inline `#tags`, normalized, each once, in the order they first
  /// appear.
  final List<String> tags;

  /// Its wikilinks and Markdown links, in document order.
  ///
  /// A link's offsets are where its block's text puts it: exact outside a
  /// quote, and inside one measured without the quote's `>` marks. The
  /// index keeps the kind and the target, never the offsets.
  final List<ParsedLink> links;

  /// Its embeds (`![[…]]`) and Markdown images (`![…](…)`), in document
  /// order, each marked as an embed.
  ///
  /// Not links the note offers to follow, but references a rename or a move
  /// must carry all the same (#507): the index keeps an edge for them, so
  /// the note is found again and rewritten.
  final List<ParsedLink> embeds;
}

/// The tags and links of [text]; see the library comment for what is read.
NoteReferences noteReferencesOf(String text) {
  final buffer = SourceBuffer.fromText(text);
  final blocks = BlockScanner(buffer).index.blocks;
  final parser = ReadParser();
  DocumentScope? scope;
  DocumentScope scopeOf() =>
      scope ??= DocumentScope.scan(buffer, buffer.revision);
  return collectReferences([
    for (final block in blocks)
      blockReferencesOf(block, buffer, parser, scopeOf),
  ]);
}

/// The tags and links of one block: what a note's references are made of,
/// block by block, for a reader that keeps them per block and reads again
/// only the blocks an edit changed (`NoteReferenceCache`).
///
/// `scoped` says the answer may hang on the note's link definitions — a
/// link was read, or a `[` that one could make one — so it is to be read
/// again when they change.
typedef BlockReferences = ({
  List<String> tags,
  List<ParsedLink> links,
  List<ParsedLink> embeds,
  bool scoped,
});

/// A block with no tag and no link and no embed.
const BlockReferences noBlockReferences = (
  tags: <String>[],
  links: <ParsedLink>[],
  embeds: <ParsedLink>[],
  scoped: false,
);

/// The references of [block] in [buffer]; [scope] is asked only when a
/// link can be in it. A link's offsets are where the note had it when the
/// block was read.
BlockReferences blockReferencesOf(
  Block block,
  SourceBuffer buffer,
  ReadParser parser,
  DocumentScope Function() scope,
) {
  if (!_hasInlineText(block.kind)) return noBlockReferences;
  final raw = BlockParser.blockText(block, buffer);
  final bracket = raw.contains('[');
  // Without a `[` only a tag can be in it — and a heading's own hashes are
  // none: every heading was parsed whole for nothing (#581).
  if (!bracket && !AppSyntax.mayHoldTag(raw)) return noBlockReferences;
  // A tag needs no definition: without a `[` the note's are not asked for.
  final read = parser.read(
    block,
    buffer,
    scope: bracket ? scope() : DocumentScope.ofLines(buffer, 0, const []),
  );
  final out = _Collected(buffer);
  void visit(BlockNode node) {
    switch (node) {
      case QuoteNode(:final children):
        final title = read.titleOf(node);
        if (title != null) out.read(title);
        children.forEach(visit);
      case ItemNode(:final children) || FootnoteNode(:final children):
        children.forEach(visit);
      case ListNode(:final items):
        items.forEach(visit);
      case LeafNode():
        final leaf = read.leaf(node);
        final inline = leaf.inline;
        if (inline != null) out.read(inline);
        for (final row in leaf.rows) {
          row.forEach(out.read);
        }
    }
  }

  visit(read.node);
  if (out.tags.isEmpty &&
      out.links.isEmpty &&
      out.embeds.isEmpty &&
      !out.scoped) {
    return noBlockReferences;
  }
  out.links.sort((a, b) => a.start.compareTo(b.start));
  return (
    tags: out.tags,
    links: out.links,
    embeds: out.embeds,
    scoped: out.scoped,
  );
}

/// What one block's inline texts reference.
final class _Collected {
  new(this.buffer);

  final SourceBuffer buffer;
  final List<String> tags = <String>[];
  final List<ParsedLink> links = <ParsedLink>[];
  final List<ParsedLink> embeds = <ParsedLink>[];
  bool scoped = false;

  /// Collects [inline]'s references, without recursion.
  void read(ReadInline inline) {
    final text = inline.text;
    final stack = <InlineNode>[...inline.nodes.reversed];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      switch (node) {
        case TagNode(:final name):
          tags.add(normalizeTag(name));
        case WikiLinkNode(:final inner, embed: true):
          // `![[…]]`: not a link the note offers, but a reference a move
          // carries (#507). A target-less embed (`![[#h]]`) names no file.
          final ref = parseWikiRef(inner);
          if (ref.target.isEmpty) continue;
          final (start, end) = _offsets(inline, node);
          embeds.add(WikiLink(start: start, end: end, ref: ref, embed: true));
        case WikiLinkNode(:final inner):
          final ref = parseWikiRef(inner);
          // `[[]]`, `[[|]]` and `[[#]]` carry nothing to resolve or show.
          if (ref.target.isEmpty && ref.heading == null && ref.alias == null) {
            continue;
          }
          final (start, end) = _offsets(inline, node);
          links.add(WikiLink(start: start, end: end, ref: ref));
        case LinkNode(:final destination, :final children):
          scoped = true;
          final (start, end) = _offsets(inline, node);
          links.add(
            MarkdownLink(
              start: start,
              end: end,
              text: _bracketed(text, node, children),
              href: destination,
            ),
          );
          stack.addAll(children.reversed);
        case ImageNode(:final destination, :final children):
          // A Markdown image is an embed, not a link (#507).
          scoped = true;
          final (start, end) = _offsets(inline, node);
          embeds.add(
            MarkdownLink(
              start: start,
              end: end,
              text: _bracketed(text, node, children),
              href: destination,
              embed: true,
            ),
          );
        case TextNode(text: final written):
          // A `[` no link took: a definition the note gains may make one.
          if (written.contains('[')) scoped = true;
        case InlineContainer(:final children):
          stack.addAll(children.reversed);
        case CodeNode() ||
            HtmlNode() ||
            MathNode() ||
            SoftBreakNode() ||
            HardBreakNode() ||
            FootnoteRefNode():
          break;
      }
    }
  }

  /// Where [node] of [inline] starts and ends in the note.
  (int, int) _offsets(ReadInline inline, InlineNode node) {
    final first = inline.map.positionOf(node.start)!;
    final last = inline.map.positionOf(node.end - 1)!;
    return (
      buffer.offsetOfLine(first.line) + first.column,
      buffer.offsetOfLine(last.line) + last.column + 1,
    );
  }

  /// A link's or an image's text between its brackets, as written,
  /// trimmed; the whole of a bare autolink.
  static String _bracketed(
    String text,
    InlineNode node,
    List<InlineNode> children,
  ) {
    if (node is LinkNode && node.auto) {
      return children.isEmpty
          ? ''
          : text.substring(children.first.start, children.last.end).trim();
    }
    final open = node.start + (node is ImageNode ? 2 : 1);
    final close = children.isEmpty ? open : children.last.end;
    return text.substring(open, close).trim();
  }
}

/// A note's references out of its blocks', given in the blocks' order: each
/// tag once, in the order it first appears, and the links in the order the
/// note has them.
NoteReferences collectReferences(Iterable<BlockReferences> blocks) {
  final tags = <String>{};
  final links = <ParsedLink>[];
  final embeds = <ParsedLink>[];
  for (final block in blocks) {
    if (identical(block, noBlockReferences)) continue;
    tags.addAll(block.tags);
    links.addAll(block.links);
    embeds.addAll(block.embeds);
  }
  return NoteReferences(tags: tags.toList(), links: links, embeds: embeds);
}

/// Whether a block of [kind] has inline text, where a tag or a link can be.
bool _hasInlineText(BlockKind kind) => switch (kind) {
  BlockKind.paragraph ||
  BlockKind.heading ||
  BlockKind.listItem ||
  BlockKind.quote ||
  BlockKind.table => true,
  _ => false,
};
