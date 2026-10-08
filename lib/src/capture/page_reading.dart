/// What a captured page was read to (#531): its article, found by the
/// Readability port, or — when there is too little text — what the page
/// says about itself, for a note that sends the reader to the link.
///
/// Too little text means no article, an article under
/// [minimumArticleCharacters], or a page whose charset could not be
/// decoded; the capture then runs the page in a browser and reads it again.
library;

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/metadata.dart';
import 'package:niman/src/capture/readability/post_process.dart';
import 'package:niman/src/capture/readability/readability.dart';

/// The characters an article needs for the page to count as read:
/// Readability's own threshold.
///
/// ponytail: characters of any script count alike, so a short Japanese or
/// Chinese article — 300 characters say what 900 say in English — counts
/// as too little text and gets the unreadable note; weighing CJK characters
/// three times is the upgrade if captures of such pages come out empty.
const int minimumArticleCharacters = 500;

/// A page read.
final class PageReading {
  /// What [url] was read to.
  const new({
    required this.url,
    required this.title,
    this.article,
    this.byline,
    this.description,
    this.siteName,
    this.publishedTime,
    this.image,
  });

  /// Where the page was read from, after its redirects.
  final Uri url;

  /// Its title: the article's, the page's, else its address.
  final String title;

  /// Its article; null when there was too little text.
  final ReadabilityArticle? article;

  /// Its author.
  final String? byline;

  /// What it says it is about.
  final String? description;

  /// Its site's name.
  final String? siteName;

  /// When it was published, as the page writes it.
  final String? publishedTime;

  /// Its picture (`og:image`), absolute.
  final String? image;

  /// Whether an article was found.
  bool get readable => article != null;
}

/// Reads the page [text] downloaded from [url]; null [text] is a page whose
/// charset could not be decoded.
PageReading readPage(String? text, Uri url) {
  final fallbackTitle = url.host.isEmpty ? url.toString() : url.host;
  if (text == null) return PageReading(url: url, title: fallbackTitle);
  final document = html.parse(text);
  // What the page says of itself, before Readability changes the tree.
  final image = _meta(document, const ['og:image', 'twitter:image']);
  final description = _meta(document, const [
    'og:description',
    'description',
    'twitter:description',
  ]);
  final title = documentTitle(document);
  final article = readArticle(document, documentUri: url);
  final found =
      article != null &&
      article.textContent.trim().length >= minimumArticleCharacters;
  return PageReading(
    url: url,
    title: _firstOf([article?.title, title]) ?? fallbackTitle,
    article: found ? article : null,
    byline: _firstOf([article?.byline]),
    description: _firstOf([article?.excerpt, description]),
    siteName: _firstOf([article?.siteName]),
    publishedTime: _firstOf([article?.publishedTime]),
    image: image == null ? null : resolveUrl(url, image),
  );
}

String? _firstOf(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

/// The `content` of the first of [keys] the page's `meta` tags name, by
/// `property` or `name`.
String? _meta(Document document, List<String> keys) {
  for (final key in keys) {
    for (final meta in elementsWithTag(document, const ['meta'])) {
      final name = attributeOf(meta, 'property') ?? attributeOf(meta, 'name');
      final content = attributeOf(meta, 'content')?.trim();
      if (name?.toLowerCase() != key || content == null || content.isEmpty) {
        continue;
      }
      return content;
    }
  }
  return null;
}
