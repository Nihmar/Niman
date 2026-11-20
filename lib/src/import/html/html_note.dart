/// The note an imported HTML page becomes (#1293): its frontmatter —
/// `source`, `imported`, `author` — its title as the heading, and its
/// content in Markdown, the pictures embedded as the library embeds its
/// own and the links into the page pointing at its headings.
///
/// Pure: the pictures are kept first (`html_picture_store.dart`) and
/// handed in as a map from each `src` to where it went.
library;

import 'package:niman/src/capture/capture_note.dart' show withoutTitleHeading;
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/frontmatter/yaml_scalar.dart';
import 'package:niman/src/import/html/html_anchor_links.dart';
import 'package:niman/src/import/html/html_page.dart';
import 'package:niman/src/import/html/html_picture_source.dart';
import 'package:niman/src/import/html/html_unlinked.dart';
import 'package:niman/src/links/attachment_embed.dart';
import 'package:niman/src/markdown/from_html/html_markdown.dart';
import 'package:niman/src/markdown/text_escape.dart';

/// The pictures [page]'s note would show, as each `src` is written in the
/// page, in order, each once.
List<String> htmlPictureSrcs(HtmlPage page) {
  final found = <String>{};
  HtmlMarkdown(
    picture: (src) {
      found.add(src);
      return null;
    },
    link: (href) => href,
  ).convert(page.html);
  return found.toList();
}

/// The text of the note of [page], imported on [imported], from the file
/// at [file] (the address its relative pictures are relative to, unless the
/// page names a `<base>`).
///
/// [pictures] maps a picture's `src` to the library-relative path it was
/// kept at. A web picture not in it keeps its address; any other not in it
/// is left out of the note. [folder] is the library-relative folder the
/// note goes in, which a Markdown picture link is written from (#1282);
/// [linkType] is how the library embeds a picture.
String htmlNote(
  HtmlPage page, {
  required DateTime imported,
  required Uri file,
  Map<String, String> pictures = const {},
  LinkType linkType = LinkType.wikilink,
  String folder = '',
}) {
  final base = page.baseUrl ?? file;
  // The note's own name is not known yet (it is the title's), but its
  // folder is, and a Markdown link is written from there.
  final from = folder.isEmpty ? 'note.md' : '$folder/note.md';
  final title = escapeMarkdownText(page.title);
  final converted = HtmlMarkdown(
    picture: (src) {
      if (pictures.containsKey(src)) return src;
      final source = PictureSource.parse(src, base);
      return source?.kind == PictureKind.web ? source!.address : null;
    },
    embed: (target, alt) {
      final kept = pictures[target];
      return kept == null
          ? markdownImage(target, alt)
          : attachmentEmbed(
              relativePath: kept,
              label: alt,
              linkType: linkType,
              note: from,
            );
    },
    link: (href) => isUnlinked(href)
        ? unlinkedTarget
        : href.startsWith('#') && href.length > 1
        ? anchorTarget(href.substring(1))
        : href,
  ).convert(page.html);
  final body = withoutTitleHeading(
    withoutUnlinked(
      resolveAnchorLinks(converted.markdown, converted.anchors, title: title),
    ),
    title,
  );
  final out = StringBuffer(_frontmatter(page, imported))..write('\n# $title\n');
  if (body.isNotEmpty) out.write('\n$body\n');
  return out.toString();
}

String _frontmatter(HtmlPage page, DateTime imported) {
  String two(int n) => n.toString().padLeft(2, '0');
  final day = '${imported.year}-${two(imported.month)}-${two(imported.day)}';
  final source = page.source;
  final author = page.author;
  return [
    '---',
    if (source != null) 'source: ${yamlString(source)}',
    'imported: $day',
    if (author != null) 'author: ${yamlString(author)}',
    '---',
    '',
  ].join('\n');
}
