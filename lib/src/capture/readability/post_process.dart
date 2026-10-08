/// The article's last touches (`_postProcessContent`): its links and
/// pictures made absolute — they leave the page — its nested `div`s
/// flattened, and its classes dropped.
///
/// Ported from mozilla/readability (Readability.js 0.6.0, commit 04fd32f),
/// Apache-2.0.
library;

import 'package:html/dom.dart';
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/patterns.dart';
import 'package:niman/src/capture/readability/run.dart';
import 'package:niman/src/capture/readability/text_metrics.dart';
import 'package:niman/src/capture/readability/traversal.dart';

/// [reference] resolved against [base] as `new URL(reference, base).href`
/// reads it, or null when it cannot be.
String? resolveUrl(Uri base, String reference) {
  try {
    final resolved = base.resolve(reference.trim());
    // A browser writes the root of an http URL as a slash.
    if ((resolved.isScheme('http') || resolved.isScheme('https')) &&
        resolved.path.isEmpty) {
      return resolved.replace(path: '/').toString();
    }
    return resolved.toString();
  } on FormatException {
    return null;
  }
}

/// The finishing.
extension ReadabilityPostProcess on ReadabilityRun {
  /// The document's base URL: its first `base` with an `href`, resolved
  /// against where the document was read from.
  Uri? get baseUri {
    for (final base in elementsWithTag(doc, const ['base'])) {
      final href = attributeOf(base, 'href');
      if (href == null) continue;
      final resolved = documentUri == null
          ? Uri.tryParse(href)
          : Uri.tryParse(resolveUrl(documentUri!, href) ?? '');
      if (resolved != null && resolved.hasScheme) return resolved;
      break;
    }
    return documentUri;
  }

  /// Finishes [articleContent].
  void postProcessContent(Element articleContent) {
    fixRelativeUris(articleContent);
    simplifyNestedElements(articleContent);
    if (!options.keepClasses) cleanClasses(articleContent);
  }

  /// Makes the links and the pictures under [articleContent] absolute; a
  /// `javascript:` link, dead without the page's scripts, becomes its text
  /// (`_fixRelativeUris`).
  void fixRelativeUris(Element articleContent) {
    final base = baseUri;
    String toAbsoluteUri(String uri) {
      // A link to a place in the page stays, when the page is its base.
      if (base == null || (base == documentUri && uri.startsWith('#'))) {
        return uri;
      }
      return resolveUrl(base, uri) ?? uri;
    }

    for (final link in elementsWithTag(articleContent, const ['a'])) {
      final href = attributeOf(link, 'href');
      if (href == null || href.isEmpty) continue;
      if (!href.startsWith('javascript:')) {
        link.attributes['href'] = toAbsoluteUri(href);
        continue;
      }
      final parent = link.parentNode;
      if (parent == null) continue;
      if (link.nodes.length == 1 && link.nodes.first is Text) {
        replaceChild(parent, Text(link.text), link);
      } else {
        // Several children: all of them kept, in a span.
        final container = Element.tag('span');
        while (link.nodes.isNotEmpty) {
          appendChild(container, link.nodes.first);
        }
        replaceChild(parent, container, link);
      }
    }

    for (final media in elementsWithTag(articleContent, const [
      'img',
      'picture',
      'figure',
      'video',
      'audio',
      'source',
    ])) {
      final src = attributeOf(media, 'src');
      final poster = attributeOf(media, 'poster');
      final srcset = attributeOf(media, 'srcset');
      if (src != null && src.isNotEmpty) {
        media.attributes['src'] = toAbsoluteUri(src);
      }
      if (poster != null && poster.isNotEmpty) {
        media.attributes['poster'] = toAbsoluteUri(poster);
      }
      if (srcset != null && srcset.isNotEmpty) {
        media.attributes['srcset'] = srcset.replaceAllMapped(
          ReadabilityPatterns.srcsetUrl,
          (match) => '${toAbsoluteUri(match[1]!)}${match[2] ?? ''}${match[3]}',
        );
      }
    }
  }

  /// Removes the empty `div`s and `section`s, and puts the only child of
  /// one in its place, its attributes taken along
  /// (`_simplifyNestedElements`).
  void simplifyNestedElements(Element articleContent) {
    Element? node = articleContent;
    while (node != null) {
      final tag = tagNameOf(node);
      if (node.parentNode != null &&
          (tag == 'DIV' || tag == 'SECTION') &&
          !node.id.startsWith('readability')) {
        if (isElementWithoutContent(node)) {
          node = removeAndGetNext(node);
          continue;
        }
        if (hasSingleTagInsideElement(node, 'DIV') ||
            hasSingleTagInsideElement(node, 'SECTION')) {
          final child = node.children.first;
          node.attributes.forEach(
            (name, value) => child.attributes[name] = value,
          );
          replaceChild(node.parentNode!, child, node);
          node = child;
          continue;
        }
      }
      node = getNextNode(node);
    }
  }

  /// Drops every class under [node] but the ones kept
  /// (`_cleanClasses`).
  void cleanClasses(Element node) {
    final className = (attributeOf(node, 'class') ?? '')
        .split(RegExp(r'\s+'))
        .where(classesToPreserve.contains)
        .join(' ');
    if (className.isNotEmpty) {
      node.attributes['class'] = className;
    } else {
      node.attributes.remove('class');
    }
    node.children.forEach(cleanClasses);
  }
}
