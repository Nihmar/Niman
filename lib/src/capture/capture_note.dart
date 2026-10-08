/// The note a captured page becomes (#531): its frontmatter — `source`,
/// `captured`, `author`, `tags` — its title as the heading, and its article
/// in Markdown, the pictures embedded as the library embeds its own.
///
/// A page with no article read keeps its title, its description and its
/// picture, under a quoted notice that sends the reader to the link.
library;

import 'package:niman/src/capture/page_reading.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/frontmatter/typed_fields.dart';
import 'package:niman/src/frontmatter/yaml_scalar.dart';
import 'package:niman/src/links/attachment_embed.dart';
import 'package:niman/src/markdown/from_html/html_markdown.dart';
import 'package:niman/src/markdown/text_escape.dart';

/// A note to make: its name and its text.
typedef CapturedNote = ({String name, String text});

/// The pictures [page]'s note would show, as their absolute addresses: the
/// article's, or the page's own picture when there is no article.
List<String> picturesOf(PageReading page) {
  final article = page.article;
  if (article == null) return [?page.image];
  final found = <String>[];
  HtmlMarkdown(
    picture: (src) {
      found.add(src);
      return null;
    },
    link: (href) => href,
  ).convert(article.contentHtml);
  return found;
}

/// The note of [page], captured on [captured], with [tags].
///
/// [pictures] maps a picture's address to the library-relative path it was
/// downloaded to; a picture not in it keeps its address. [linkType] is how
/// the library embeds a picture. [unreadableNotice] is the notice a page
/// with no article gets, as Markdown in the app's language, its link to the
/// page in it.
CapturedNote captureNote(
  PageReading page, {
  required DateTime captured,
  required String unreadableNotice,
  Map<String, String> pictures = const {},
  List<String> tags = const [],
  LinkType linkType = LinkType.wikilink,
}) {
  String embed(String src, String alt) {
    final local = pictures[src];
    if (local == null) return markdownImage(src, alt);
    return attachmentEmbed(relativePath: local, label: alt, linkType: linkType);
  }

  final out = StringBuffer()
    ..write(_frontmatter(page, captured, tags))
    ..write('\n# ${escapeMarkdownText(page.title)}\n');
  final article = page.article;
  if (article != null) {
    final body = HtmlMarkdown(
      picture: (src) => src,
      link: (href) => _absolute(page.url, href),
      embed: embed,
    ).convert(article.contentHtml).markdown;
    final text = _withoutTitle(body, escapeMarkdownText(page.title));
    if (text.isNotEmpty) out.write('\n$text\n');
  } else {
    final description = page.description;
    if (description != null) {
      final text = escapeMarkdownLineStart(escapeMarkdownText(description));
      out.write('\n$text\n');
    }
    final image = page.image;
    if (image != null) out.write('\n${embed(image, '')}\n');
    out.write('\n> ${unreadableNotice.replaceAll('\n', '\n> ')}\n');
  }
  return (name: page.title, text: out.toString());
}

/// The frontmatter block.
String _frontmatter(PageReading page, DateTime captured, List<String> tags) {
  String two(int n) => n.toString().padLeft(2, '0');
  final day = '${captured.year}-${two(captured.month)}-${two(captured.day)}';
  final byline = page.byline;
  return [
    '---',
    'source: ${yamlString(page.url.toString())}',
    'captured: $day',
    if (byline != null) 'author: ${yamlString(byline)}',
    if (tags.isNotEmpty)
      'tags: ${frontmatterFieldYaml(FrontmatterFieldType.list, tags)}',
    '---',
    '',
  ].join('\n');
}

/// [href] as a link out of the note: a place in the page becomes the
/// page's address with it, as a note has no such place.
String _absolute(Uri page, String href) => href.startsWith('#')
    ? page.replace(fragment: href.substring(1)).toString()
    : href;

/// [body] without a first heading that only says [title] again: the note's
/// own heading says it. Readability drops such a heading by its words, and
/// finds none in a script without spaces — Japanese, Chinese.
String _withoutTitle(String body, String title) {
  final match = RegExp(r'^#{1,6} (.*)\n*').firstMatch(body);
  if (match == null || match[1]!.trim() != title.trim()) return body;
  return body.substring(match.end);
}
