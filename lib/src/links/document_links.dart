/// The links of a note's text, read by the unified engine.
///
/// What a rename or a move rewrites, an export follows and a task shows is
/// what the index counts and the read view draws as a link: the block scan
/// says which blocks have inline text, and our inline parser reads them
/// (`noteReferencesOf`). A wikilink in indented code, an HTML block or an
/// HTML comment is none of those — it was one to the tokenizer this
/// replaces, and a rename rewrote the `[[Link]]` in a code sample (#1373).
library;

import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// All links in [text], in document order, with absolute offsets.
///
/// Skips what is not read as inline text — fenced and indented code, math
/// blocks, HTML blocks and comments, the frontmatter — and inline code, so
/// only links the user sees as links are returned. Markdown images
/// (`![alt](src)`) and embeds (`![[…]]`) are not links and are skipped;
/// [includeEmbeds] returns them too, marked so a caller that has to carry
/// them on a move (#507) can tell them apart.
///
/// A Markdown link is one written inline, `[text](href)`: a reference link
/// has its destination in a definition, which is no link of its own to
/// rewrite. A bare URL is no link either.
List<ParsedLink> parseLinks(String text, {bool includeEmbeds = false}) {
  // A link is a `[`, a wikilink two of them, an embed or an image a `!`
  // before one.
  if (!text.contains('[')) return const <ParsedLink>[];
  final buffer = SourceBuffer.fromText(text);
  final parser = ReadParser();
  // No definitions asked for: a reference link is skipped whatever they say.
  final scope = DocumentScope.ofLines(buffer, 0, const <int>[]);
  final out = <ParsedLink>[];
  for (final block in BlockScanner(buffer).index.blocks) {
    if (!blockHasInlineText(block.kind)) continue;
    if (!BlockParser.blockText(block, buffer).contains('[')) continue;
    final here = <ParsedLink>[];
    parser
        .read(block, buffer, scope: scope)
        .forEachInline(
          (inline) => _collect(inline, buffer, includeEmbeds, here),
        );
    here.sort((a, b) => a.start.compareTo(b.start));
    out.addAll(here);
  }
  return out;
}

/// The links of [inline], added to [out], without recursion.
void _collect(
  ReadInline inline,
  SourceBuffer buffer,
  bool includeEmbeds,
  List<ParsedLink> out,
) {
  final text = inline.text;
  // Where [node] starts and ends in the note: the offsets a rewrite edits.
  (int, int) offsets(InlineNode node) {
    final first = inline.map.positionOf(node.start)!;
    final last = inline.map.positionOf(node.end - 1)!;
    return (
      buffer.offsetOfLine(first.line) + first.column,
      buffer.offsetOfLine(last.line) + last.column + 1,
    );
  }

  /// The destination written between the parentheses that follow [node]'s
  /// label, which ends at [labelEnd], or null for a node that is no inline
  /// link: a reference, or one the parser made of something else.
  (String, bool, String?)? written(InlineNode node, int labelEnd) {
    if (labelEnd + 1 >= node.end ||
        text.codeUnitAt(labelEnd) != 0x5D ||
        text.codeUnitAt(labelEnd + 1) != 0x28 ||
        text.codeUnitAt(node.end - 1) != 0x29) {
      return null;
    }
    return linkDestinationOf(text.substring(labelEnd + 2, node.end - 1));
  }

  final stack = <InlineNode>[...inline.nodes.reversed];
  while (stack.isNotEmpty) {
    final node = stack.removeLast();
    switch (node) {
      case WikiLinkNode(:final inner, embed: true):
        // `![[…]]`: shown rather than linked, a reference a move carries.
        final ref = parseWikiRef(inner);
        if (!includeEmbeds || ref.target.isEmpty) continue;
        final (start, end) = offsets(node);
        out.add(WikiLink(start: start, end: end, ref: ref, embed: true));
      case WikiLinkNode(:final inner):
        final ref = parseWikiRef(inner);
        // `[[]]`, `[[|]]` and `[[#]]` carry nothing to resolve or display.
        if (ref.target.isEmpty && ref.fragment == null && ref.alias == null) {
          continue;
        }
        final (start, end) = offsets(node);
        out.add(WikiLink(start: start, end: end, ref: ref));
      case LinkNode(:final children, auto: false):
        final open = node.start + 1;
        final labelEnd = children.isEmpty ? open : children.last.end;
        final destination = written(node, labelEnd);
        if (destination != null) {
          final (href, angled, title) = destination;
          final (start, end) = offsets(node);
          out.add(
            MarkdownLink(
              start: start,
              end: end,
              text: text.substring(open, labelEnd).trim(),
              href: href,
              angled: angled,
              title: title,
            ),
          );
        }
        stack.addAll(children.reversed);
      case ImageNode(:final children):
        final open = node.start + 2;
        final labelEnd = children.isEmpty ? open : children.last.end;
        final destination = written(node, labelEnd);
        if (includeEmbeds && destination != null) {
          final (href, angled, title) = destination;
          final (start, end) = offsets(node);
          out.add(
            MarkdownLink(
              start: start,
              end: end,
              text: text.substring(open, labelEnd).trim(),
              href: href,
              embed: true,
              angled: angled,
              title: title,
            ),
          );
        }
      case InlineContainer(:final children):
        stack.addAll(children.reversed);
      case TextNode() ||
          CodeNode() ||
          HtmlNode() ||
          MathNode() ||
          TagNode() ||
          SoftBreakNode() ||
          HardBreakNode() ||
          FootnoteRefNode():
        break;
    }
  }
}
