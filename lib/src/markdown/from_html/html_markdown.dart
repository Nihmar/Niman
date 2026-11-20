/// HTML to the Markdown the read view draws: an EPUB's chapter, the pages
/// Niman captures.
///
/// The page is set in the app's own typography: what is kept is its
/// structure — headings, paragraphs, emphasis, lists, quotes, code, tables,
/// pictures, links — and its CSS is not read at all. Every character of the
/// page's text is escaped where Markdown or the app's own extensions would
/// read it as syntax (`#tag`, `$math$`, `[[link]]`, `*`, `|`…), so a page is
/// only ever the words it has.
library;

import 'package:html/parser.dart' as html;
import 'package:niman/src/markdown/from_html/block_context.dart';
import 'package:niman/src/markdown/from_html/html_blocks.dart';
import 'package:niman/src/markdown/from_html/html_footnotes.dart';
import 'package:niman/src/markdown/from_html/html_inline.dart';
import 'package:niman/src/markdown/from_html/html_pictures.dart';
import 'package:niman/src/markdown/from_html/markdown_blocks.dart';

export 'package:niman/src/markdown/from_html/html_pictures.dart'
    show markdownImage;

/// What a page came to: its Markdown, and where in it each element with
/// an `id` begins — as a line of the Markdown — for the links that point
/// into the page.
typedef MarkdownWithAnchors = ({String markdown, Map<String, int> anchors});

/// Converts a page's HTML (or XHTML).
///
/// [picture] names a picture by its `src` as the page wrote it, for the
/// Markdown image to point at (the caller resolves the name); null leaves
/// the picture out. [link] does the same for a link's `href`. [embed]
/// writes the picture's name and its escaped alt text as the note embeds
/// it: a Markdown image unless the caller says otherwise.
///
/// With [breaksAsParagraphs] a paragraph's lines, cut at its `<br>`s, are
/// paragraphs of their own, for a page that writes each of them so, as an
/// AO3 download does; a capture or a paste keeps them as the line breaks
/// they are. Headings, table cells and list items keep theirs either way.
final class HtmlMarkdown {
  /// A converter with the caller's own ways to name pictures and links.
  const new({
    required this.picture,
    required this.link,
    this.embed = markdownImage,
    this.breaksAsParagraphs = false,
  });

  /// The name a picture's `src` is written under, or null to leave it out.
  final String? Function(String src) picture;

  /// How a picture, named, is written into the note.
  final String Function(String target, String alt) embed;

  /// The target a link's `href` is written under.
  final String Function(String href) link;

  /// Whether the lines of a paragraph, cut at its `<br>`s, are paragraphs.
  final bool breaksAsParagraphs;

  /// The Markdown of the page [source].
  MarkdownWithAnchors convert(String source) {
    final document = html.parse(source);
    final body = document.body ?? document.documentElement;
    final out = MarkdownBlocks();
    if (body != null) {
      final footnotes = HtmlFootnotes(body);
      HtmlBlocks(
          HtmlInline(
            pictures: HtmlPictures(picture: picture, embed: embed),
            link: link,
            footnotes: footnotes,
          ),
          footnotes,
          breaksAsParagraphs: breaksAsParagraphs,
        )
        ..walk(body.nodes, out, const BlockContext())
        // The notes come after the page, once it has cited them.
        ..writeFootnotes(out);
    }
    return (markdown: out.text, anchors: out.anchors);
  }

  /// The largest picture a `srcset` offers — the widest, else the densest;
  /// the first when none says — or null when it offers none.
  static String? largestOfSrcset(String srcset) =>
      HtmlPictures.largestOfSrcset(srcset);
}
