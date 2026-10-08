/// What a page says about itself: its title, its byline, its description,
/// its site's name and its date — from JSON-LD, from its `meta` tags, from
/// its `title` and headings.
///
/// Ported from mozilla/readability (Readability.js 0.6.0, commit 04fd32f),
/// Apache-2.0.
library;

import 'dart:convert';

import 'package:html/dom.dart';
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/patterns.dart';
import 'package:niman/src/capture/readability/run.dart';
import 'package:niman/src/capture/readability/text_metrics.dart';

/// The page's metadata, each field null when the page has none.
final class PageMetadata {
  /// Metadata, filled field by field.
  new({
    this.title,
    this.byline,
    this.excerpt,
    this.siteName,
    this.publishedTime,
  });

  /// The article's title.
  String? title;

  /// Its author.
  String? byline;

  /// Its description.
  String? excerpt;

  /// The site's name.
  String? siteName;

  /// When it was published, as the page writes it.
  String? publishedTime;
}

/// The first of [values] that is a non-empty string, as JavaScript's `||`
/// picks it.
String? _first(List<String?> values) {
  for (final value in values) {
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

final _whiteSpace = RegExp(r'\s+');

int _wordCount(String text) => text.split(_whiteSpace).length;

/// Whether [text] is an absolute URL, as `new URL(text)` accepts it.
bool isUrl(String text) {
  final uri = Uri.tryParse(text.trim());
  return uri != null && uri.hasScheme;
}

/// [text] with the entities a `meta` tag's value keeps decoded: the five
/// named ones and the numeric ones (`_unescapeHtmlEntities`).
String? unescapeHtmlEntities(String? text) {
  if (text == null || text.isEmpty) return text;
  const named = {'lt': '<', 'gt': '>', 'amp': '&', 'quot': '"', 'apos': "'"};
  return text
      .replaceAllMapped(
        RegExp('&(quot|amp|apos|lt|gt);'),
        (match) => named[match[1]]!,
      )
      .replaceAllMapped(
        RegExp('&#(?:x([0-9a-f]+)|([0-9]+));', caseSensitive: false),
        (match) {
          final hex = match[1];
          var code = int.tryParse(
            hex ?? match[2]!,
            radix: hex != null ? 16 : 10,
          );
          // These references are replaced by a conforming HTML parser.
          if (code == null ||
              code == 0 ||
              code > 0x10ffff ||
              (code >= 0xd800 && code <= 0xdfff)) {
            code = 0xfffd;
          }
          return String.fromCharCode(code);
        },
      );
}

/// The document's `title`, as `document.title` reads it: the first `title`
/// element's text, its white space collapsed.
String documentTitle(Document doc) {
  for (final title in elementsWithTag(doc, const ['title'])) {
    if (!isHtmlElement(title)) continue;
    return title.text.replaceAll(RegExp('[ \t\n\f\r]+'), ' ').trim();
  }
  return '';
}

/// The page's metadata, read by a run.
extension ReadabilityMetadata on ReadabilityRun {
  /// The article's title, from the document's: a site's name cut off it,
  /// or the one `h1` when the title is too short or too long
  /// (`_getArticleTitle`).
  String getArticleTitle() {
    final origTitle = documentTitle(doc).trim();
    var curTitle = origTitle;
    var titleHadHierarchicalSeparators = false;
    final separator = RegExp(r' [\|\-\\\/>»] ');
    if (separator.hasMatch(curTitle)) {
      titleHadHierarchicalSeparators = RegExp(r' [\\\/>»] ').hasMatch(curTitle);
      final last = separator.allMatches(origTitle).last;
      curTitle = origTitle.substring(0, last.start);
      // If the resulting title is too short, remove the first part instead.
      if (_wordCount(curTitle) < 3) {
        curTitle = origTitle.replaceFirst(
          RegExp(r'^[^\|\-\\\/>»]*[\|\-\\\/>»]'),
          '',
        );
      }
    } else if (curTitle.contains(': ')) {
      // A heading with this exact text says it is the full title.
      final trimmedTitle = curTitle.trim();
      final match = elementsWithTag(doc, const [
        'h1',
        'h2',
      ]).any((heading) => heading.text.trim() == trimmedTitle);
      if (!match) {
        curTitle = origTitle.substring(origTitle.lastIndexOf(':') + 1);
        if (_wordCount(curTitle) < 3) {
          // Too short: the first colon instead.
          curTitle = origTitle.substring(origTitle.indexOf(':') + 1);
        } else if (_wordCount(origTitle.substring(0, origTitle.indexOf(':'))) >
            5) {
          // Too many words before the colon: something is odd, the
          // original title it is.
          curTitle = origTitle;
        }
      }
    } else if (curTitle.length > 150 || curTitle.length < 15) {
      final hOnes = elementsWithTag(doc, const ['h1']);
      if (hOnes.length == 1) curTitle = innerText(hOnes.first);
    }

    curTitle = curTitle.trim().replaceAll(ReadabilityPatterns.normalize, ' ');
    // Four words or fewer, and either no hierarchical separator in the
    // original or more than one word lost: the original title.
    final curTitleWordCount = _wordCount(curTitle);
    if (curTitleWordCount <= 4 &&
        (!titleHadHierarchicalSeparators ||
            curTitleWordCount !=
                _wordCount(origTitle.replaceAll(RegExp(r'[\|\-\\\/>»]+'), '')) -
                    1)) {
      curTitle = origTitle;
    }
    return curTitle;
  }

  /// The metadata of the page's first schema.org article in JSON-LD
  /// (`_getJSONLD`).
  PageMetadata getJsonLd() {
    for (final script in elementsWithTag(doc, const ['script'])) {
      if (attributeOf(script, 'type') != 'application/ld+json') continue;
      try {
        final found = _jsonLdArticle(script.text);
        if (found != null) return found;
      } on Object {
        // A script upstream's own parsing throws on: the next one is read.
      }
    }
    return PageMetadata();
  }

  /// The metadata [source] holds, or null when it is no article. Throws
  /// where upstream's JavaScript would.
  PageMetadata? _jsonLdArticle(String source) {
    final content = source.replaceAll(RegExp(r'^\s*<!\[CDATA\[|\]\]>\s*$'), '');
    var parsed = jsonDecode(content);
    if (parsed is List) {
      parsed = parsed.firstWhere(
        (it) => _typeMatches(_field(it, '@type')),
        orElse: () => null,
      );
      if (parsed == null) return null;
    }
    if (parsed is! Map) return null;
    final schemaDotOrg = RegExp(r'^https?\:\/\/schema\.org\/?$');
    final context = parsed['@context'];
    final vocab = context is Map ? context['@vocab'] : null;
    if (context == null && parsed.containsKey('@context')) {
      throw const FormatException('null @context');
    }
    final matches =
        (context is String && schemaDotOrg.hasMatch(context)) ||
        (vocab is String && schemaDotOrg.hasMatch(vocab));
    if (!matches) return null;

    Object? article = parsed;
    if (parsed['@type'] == null && parsed['@graph'] is List) {
      article = (parsed['@graph'] as List).firstWhere(
        (it) => _typeMatches(_field(it, '@type') ?? ''),
        orElse: () => null,
      );
    }
    if (article is! Map || !_typeMatches(article['@type'])) return null;

    final metadata = PageMetadata();
    final name = article['name'];
    final headline = article['headline'];
    if (name is String && headline is String && name != headline) {
      // Some sites put their own name in `name` and the article's title in
      // `headline`: the one closer to the HTML title wins, else `name`.
      final title = getArticleTitle();
      final nameMatches = textSimilarity(name, title) > 0.75;
      final headlineMatches = textSimilarity(headline, title) > 0.75;
      metadata.title = headlineMatches && !nameMatches ? headline : name;
    } else if (name is String) {
      metadata.title = name.trim();
    } else if (headline is String) {
      metadata.title = headline.trim();
    }
    final author = article['author'];
    if (author is Map && author['name'] is String) {
      metadata.byline = (author['name'] as String).trim();
    } else if (author is List &&
        author.isNotEmpty &&
        _field(author.first, 'name') is String) {
      metadata.byline = [
        for (final one in author)
          if (one is Map && one['name'] is String)
            (one['name'] as String).trim(),
      ].join(', ');
    }
    final description = article['description'];
    if (description is String) metadata.excerpt = description.trim();
    final publisher = article['publisher'];
    if (publisher is Map && publisher['name'] is String) {
      metadata.siteName = (publisher['name'] as String).trim();
    }
    final published = article['datePublished'];
    if (published is String) metadata.publishedTime = published.trim();
    return metadata;
  }

  /// The page's metadata: JSON-LD's first, then its `meta` tags', then its
  /// title (`_getArticleMetadata`).
  PageMetadata getArticleMetadata(PageMetadata jsonLd) {
    final values = <String, String>{};
    // `property` is a space-separated list of values; `name` is one.
    final propertyPattern = RegExp(
      r'\s*(article|dc|dcterm|og|twitter)\s*:\s*'
      r'(author|creator|description|published_time|title|site_name)\s*',
      caseSensitive: false,
    );
    final namePattern = RegExp(
      r'^\s*(?:(dc|dcterm|og|twitter|parsely|weibo:(article|webpage))\s*[-\.:]\s*)?'
      r'(author|creator|pub-date|description|title|site_name)\s*$',
      caseSensitive: false,
    );
    for (final element in elementsWithTag(doc, const ['meta'])) {
      final elementName = attributeOf(element, 'name');
      final elementProperty = attributeOf(element, 'property');
      final content = attributeOf(element, 'content');
      if (content == null || content.isEmpty) continue;
      var matched = false;
      if (elementProperty != null && elementProperty.isNotEmpty) {
        final match = propertyPattern.firstMatch(elementProperty);
        if (match != null) {
          matched = true;
          final name = match[0]!.toLowerCase().replaceAll(_whiteSpace, '');
          values[name] = content.trim();
        }
      }
      if (!matched &&
          elementName != null &&
          elementName.isNotEmpty &&
          namePattern.hasMatch(elementName)) {
        final name = elementName
            .toLowerCase()
            .replaceAll(_whiteSpace, '')
            .replaceAll('.', ':');
        values[name] = content.trim();
      }
    }

    final title =
        _first([
          jsonLd.title,
          values['dc:title'],
          values['dcterm:title'],
          values['og:title'],
          values['weibo:article:title'],
          values['weibo:webpage:title'],
          values['title'],
          values['twitter:title'],
          values['parsely-title'],
        ]) ??
        getArticleTitle();
    final articleAuthor = values['article:author'];
    return PageMetadata(
      title: unescapeHtmlEntities(title),
      byline: unescapeHtmlEntities(
        _first([
          jsonLd.byline,
          values['dc:creator'],
          values['dcterm:creator'],
          values['author'],
          values['parsely-author'],
          if (articleAuthor != null && !isUrl(articleAuthor)) articleAuthor,
        ]),
      ),
      excerpt: unescapeHtmlEntities(
        _first([
          jsonLd.excerpt,
          values['dc:description'],
          values['dcterm:description'],
          values['og:description'],
          values['weibo:article:description'],
          values['weibo:webpage:description'],
          values['description'],
          values['twitter:description'],
        ]),
      ),
      siteName: unescapeHtmlEntities(
        _first([jsonLd.siteName, values['og:site_name']]),
      ),
      publishedTime: unescapeHtmlEntities(
        _first([
          jsonLd.publishedTime,
          values['article:published_time'],
          values['parsely-pub-date'],
        ]),
      ),
    );
  }

  /// Whether [node] is the byline: `rel="author"`, an `itemprop` with
  /// `author`, or a class or an id that says so — with some text, under 100
  /// characters (`_isValidByline`).
  bool isValidByline(Element node, String matchString) {
    final rel = attributeOf(node, 'rel');
    final itemprop = attributeOf(node, 'itemprop');
    final bylineLength = node.text.trim().length;
    return (rel == 'author' ||
            (itemprop != null && itemprop.contains('author')) ||
            ReadabilityPatterns.byline.hasMatch(matchString)) &&
        bylineLength > 0 &&
        bylineLength < 100;
  }

  /// Whether [node] is an `h1` or an `h2` that says the title again
  /// (`_headerDuplicatesTitle`).
  bool headerDuplicatesTitle(Element node) {
    final tag = tagNameOf(node);
    if (tag != 'H1' && tag != 'H2') return false;
    final heading = innerText(node, normalizeSpaces: false);
    return textSimilarity(articleTitle ?? '', heading) > 0.75;
  }
}

/// [object]'s [key], where JavaScript would read it: undefined on what is
/// not an object, a TypeError on null.
Object? _field(Object? object, String key) {
  if (object == null) throw const FormatException('property of null');
  return object is Map ? object[key] : null;
}

/// Whether a `@type` is an article's: false when it is missing, a
/// TypeError (as upstream's `.match` throws) when it is not a string.
bool _typeMatches(Object? type) {
  if (type == null || type == '') return false;
  if (type is! String) throw const FormatException('@type is not a string');
  return ReadabilityPatterns.jsonLdArticleTypes.hasMatch(type);
}
