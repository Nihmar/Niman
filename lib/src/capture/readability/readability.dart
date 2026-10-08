/// The article in a web page, found by a port of Mozilla's Readability.js —
/// Firefox's Reader View — over `package:html`.
///
/// Ported from mozilla/readability (Readability.js 0.6.0, commit 04fd32f),
/// Apache-2.0; its licence ships with the app. The port keeps upstream's
/// algorithm and its names, so a diff against a new release reads line by
/// line; `test/fixtures/readability/` holds upstream's own test pages, and
/// the port is held to their expected output.
library;

import 'package:html/dom.dart';
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/grab.dart';
import 'package:niman/src/capture/readability/metadata.dart';
import 'package:niman/src/capture/readability/post_process.dart';
import 'package:niman/src/capture/readability/prep.dart';
import 'package:niman/src/capture/readability/run.dart';

export 'package:niman/src/capture/readability/readerable.dart'
    show isProbablyReaderable;
export 'package:niman/src/capture/readability/run.dart' show ReadabilityOptions;

/// The article found.
final class ReadabilityArticle {
  /// An article.
  const new({
    required this.title,
    required this.content,
    required this.textContent,
    this.byline,
    this.dir,
    this.lang,
    this.excerpt,
    this.siteName,
    this.publishedTime,
  });

  /// Its title.
  final String? title;

  /// Its author.
  final String? byline;

  /// Its text direction.
  final String? dir;

  /// Its language.
  final String? lang;

  /// Its content: a `div` around one `div#readability-page-1.page`, links
  /// and pictures absolute.
  final Element content;

  /// Its text.
  final String textContent;

  /// Its description, or its first paragraph.
  final String? excerpt;

  /// Its site's name.
  final String? siteName;

  /// When it was published, as the page writes it.
  final String? publishedTime;

  /// The content's HTML, as upstream's default serializer gives it.
  String get contentHtml => content.innerHtml;
}

/// Finds the article in [doc], read from [documentUri]; null when there is
/// none. [doc] is changed in the reading: pass a copy to keep it.
///
/// Throws a [StateError] when [doc] has more elements than
/// [ReadabilityOptions.maxElemsToParse] allows.
ReadabilityArticle? readArticle(
  Document doc, {
  Uri? documentUri,
  ReadabilityOptions options = const ReadabilityOptions(),
}) {
  final run = ReadabilityRun(doc, documentUri: documentUri, options: options);
  if (options.maxElemsToParse > 0) {
    final numTags = allElements(doc).length;
    if (numTags > options.maxElemsToParse) {
      throw StateError('Aborting parsing document; $numTags elements found');
    }
  }

  parseNoscripts(doc);
  run.unwrapNoscriptImages();
  // JSON-LD before the scripts that carry it go.
  final jsonLd = options.disableJsonLd ? PageMetadata() : run.getJsonLd();
  run
    ..removeScripts()
    ..prepDocument();

  final metadata = run.getArticleMetadata(jsonLd);
  run
    ..metadataByline = _orNull(metadata.byline)
    ..articleTitle = metadata.title;

  final articleContent = run.grabArticle();
  if (articleContent == null) return null;
  run.postProcessContent(articleContent);

  // No description: the first paragraph says what the article is.
  var excerpt = metadata.excerpt;
  if (excerpt == null || excerpt.isEmpty) {
    final paragraphs = elementsWithTag(articleContent, const ['p']);
    if (paragraphs.isNotEmpty) excerpt = paragraphs.first.text.trim();
  }

  return ReadabilityArticle(
    title: run.articleTitle,
    byline: _orNull(metadata.byline) ?? run.articleByline,
    dir: run.articleDir,
    lang: run.articleLang,
    content: articleContent,
    textContent: articleContent.text,
    excerpt: excerpt,
    siteName: metadata.siteName,
    publishedTime: metadata.publishedTime,
  );
}

String? _orNull(String? text) => text == null || text.isEmpty ? null : text;
