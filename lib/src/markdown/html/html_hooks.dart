/// Where a page built on the writer (`TreeHtml`) draws a construct its own
/// way: the export's code colours, formulas, diagrams, callouts, wikilinks
/// and pictures (`docs/dev/block-tree.md`, phase 7). Each answer is HTML,
/// or null for the writer's own, `cmark-gfm`'s.
library;

import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/callout.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';

/// The writer's ways out; every one answers null, the writer's own.
class HtmlHooks {
  /// Hooks that change nothing.
  const new();

  /// [leaf], whose lines as its container reads them are [lines], as
  /// HTML of a block of its own: a fence, a math block, an HTML block.
  String? leaf(LeafNode leaf, List<String> lines) => null;

  /// A callout's frame around [body], its blocks' HTML; [title] its written
  /// title's inline HTML, or null for one its type titles.
  String? callout(Callout callout, String body, String? title) => null;

  /// The `id` of a heading whose inline text, as written, is [text]; null
  /// for none.
  String? headingId(String text) => null;

  /// One of the app's own inline constructs, or raw HTML, as HTML: a
  /// [MathNode], a [WikiLinkNode], a [TagNode], an [HtmlNode].
  String? inline(InlineNode node) => null;

  /// Where a link to [destination] goes on the page — or the empty string
  /// for no link at all, its text standing alone.
  String? linkTarget(String destination) => null;

  /// Where a picture of [destination] is read from on the page.
  String? imageSource(String destination) => null;

  /// Whether attributes are written as XHTML has them: a value for every
  /// one (`data-footnotes=""`), as an EPUB's chapter must.
  bool get xhtml => false;
}
