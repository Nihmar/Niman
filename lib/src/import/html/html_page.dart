/// An HTML file read (#1293): its text decoded, its title and what it says
/// of itself, and the part of it that becomes the note.
///
/// Pure: bytes in, a [HtmlPage] out, nothing on disk. The note is written
/// from it by `html_note.dart`.
library;

import 'dart:typed_data';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:niman/src/capture/fetch/page_charset.dart';
import 'package:niman/src/capture/page_reading.dart'
    show minimumArticleCharacters;
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/metadata.dart' show documentTitle;
import 'package:niman/src/capture/readability/readability.dart';
import 'package:niman/src/import/html/html_convert_failures.dart';
import 'package:path/path.dart' as p;

/// How much of a page becomes the note.
enum HtmlExtent {
  /// What Readability picks as the article, as a web capture does; the
  /// whole body when it finds none (or too little text to be one).
  article,

  /// The whole `<body>`, Readability left out: a book's pages (#1294),
  /// where nothing is a menu to drop.
  body,
}

/// A page read: what is converted and what the note says of it.
final class HtmlPage {
  /// A page read.
  const new({
    required this.title,
    required this.html,
    required this.isArticle,
    this.source,
    this.author,
    this.language,
    this.baseUrl,
  });

  /// Its title; never empty.
  final String title;

  /// The HTML that becomes the note: the article's, or the body's.
  final String html;

  /// Whether [html] is the article Readability found, not the whole body.
  final bool isArticle;

  /// The address the page says it is at (`<link rel="canonical">`, else
  /// `og:url`), absolute http or https; null when it says none.
  final String? source;

  /// Who wrote it (`<meta name="author">`, else a `rel="author"` link's
  /// text).
  final String? author;

  /// Its language, as `<html lang>` writes it.
  final String? language;

  /// The address its relative links and pictures are relative to when the
  /// page names one (`<base href>`, absolute http or https); null when
  /// they are relative to the file.
  final Uri? baseUrl;
}

/// The page in [bytes], a file called [fileName] (its title when the page
/// has none).
///
/// Throws [HtmlRefused] when the page is in a charset that is not decoded:
/// guessing it would write the note's words as mojibake.
HtmlPage readHtmlPage(
  Uint8List bytes, {
  required String fileName,
  HtmlExtent extent = HtmlExtent.article,
}) {
  final text = decodePage(bytes);
  if (text == null) {
    throw HtmlRefused(
      HtmlRefusal.unsupportedCharset,
      'charset ${charsetOfMeta(bytes) ?? '?'}',
    );
  }
  final document = html.parse(text);
  // What the page says of itself, before Readability changes the tree.
  final pageTitle = _clean(documentTitle(document));
  final ogTitle = _clean(_meta(document, const ['og:title']));
  final h1 = elementsWithTag(document, const ['h1']);
  final firstH1 = h1.isEmpty ? null : _clean(h1.first.text);
  final source = _canonical(document);
  final author =
      _clean(_meta(document, const ['author'])) ?? _relAuthor(document);
  final language = _clean(document.documentElement?.attributes['lang']);
  final baseUrl = _baseUrl(document);

  ReadabilityArticle? article;
  if (extent == HtmlExtent.article) {
    article = _article(document);
  }
  // Readability changed the tree it read: the body is read from a fresh one.
  final String content;
  if (article != null) {
    content = article.contentHtml;
  } else if (extent == HtmlExtent.article) {
    content = html.parse(text).body?.innerHtml ?? '';
  } else {
    content = document.body?.innerHtml ?? '';
  }
  return HtmlPage(
    title:
        _clean(article?.title) ??
        pageTitle ??
        ogTitle ??
        firstH1 ??
        p.basenameWithoutExtension(fileName),
    html: content,
    isArticle: article != null,
    source: source,
    author: author,
    language: language,
    baseUrl: baseUrl,
  );
}

/// The article of [document], or null when Readability finds none, finds
/// too little text for one, or gives up on a page that large.
ReadabilityArticle? _article(Document document) {
  try {
    // Classes kept: the converter reads `language-js` and the like.
    final article = readArticle(
      document,
      options: const ReadabilityOptions(keepClasses: true),
    );
    if (article == null ||
        article.textContent.trim().length < minimumArticleCharacters) {
      return null;
    }
    return article;
  } on Object {
    // Readability gave up on the page: its body is read whole.
    return null;
  }
}

/// [text] with its whitespace runs made one space; null when nothing is
/// left.
String? _clean(String? text) {
  final cleaned = text?.replaceAll(RegExp(r'\s+'), ' ').trim();
  return cleaned == null || cleaned.isEmpty ? null : cleaned;
}

/// The `content` of the first `meta` of [document] named, by `name` or
/// `property`, one of [keys] (lower case).
String? _meta(Document document, List<String> keys) {
  for (final key in keys) {
    for (final meta in elementsWithTag(document, const ['meta'])) {
      final name = meta.attributes['name'] ?? meta.attributes['property'];
      final content = meta.attributes['content']?.trim();
      if (name?.trim().toLowerCase() == key &&
          content != null &&
          content.isNotEmpty) {
        return content;
      }
    }
  }
  return null;
}

/// The page's canonical address: its `<link rel="canonical">`, else its
/// `og:url`, when that is an absolute http or https one.
String? _canonical(Document document) {
  for (final link in elementsWithTag(document, const ['link'])) {
    if (!_rel(link).contains('canonical')) continue;
    final url = _webAddress(link.attributes['href']);
    if (url != null) return url;
  }
  return _webAddress(_meta(document, const ['og:url']));
}

/// The text of the first element marked `rel="author"`.
String? _relAuthor(Document document) {
  for (final element in allElements(document)) {
    if (!_rel(element).contains('author')) continue;
    final text = _clean(element.text);
    if (text != null) return text;
  }
  return null;
}

List<String> _rel(Element element) =>
    (element.attributes['rel'] ?? '').toLowerCase().split(RegExp(r'\s+'));

/// The first `<base href>` of [document] that is an absolute web address.
Uri? _baseUrl(Document document) {
  for (final base in elementsWithTag(document, const ['base'])) {
    final href = base.attributes['href'];
    if (href == null) continue;
    final url = _webAddress(href);
    return url == null ? null : Uri.parse(url);
  }
  return null;
}

/// [text] when it is an absolute http or https address with a host.
String? _webAddress(String? text) {
  final uri = Uri.tryParse(text?.trim() ?? '');
  if (uri == null ||
      !(uri.isScheme('http') || uri.isScheme('https')) ||
      uri.host.isEmpty) {
    return null;
  }
  return uri.toString();
}
