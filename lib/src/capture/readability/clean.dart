/// The article made ready to read (`_prepArticle`): its styles, forms,
/// frames, sharing buttons and empty paragraphs gone, its `h1`s made `h2`s
/// — the title is shown apart — and a table of one cell made its content.
///
/// Ported from mozilla/readability (Readability.js 0.6.0, commit 04fd32f),
/// Apache-2.0.
library;

import 'package:html/dom.dart';
import 'package:niman/src/capture/readability/clean_conditionally.dart';
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/lazy_images.dart';
import 'package:niman/src/capture/readability/patterns.dart';
import 'package:niman/src/capture/readability/prep.dart';
import 'package:niman/src/capture/readability/run.dart';
import 'package:niman/src/capture/readability/text_metrics.dart';
import 'package:niman/src/capture/readability/traversal.dart';

/// The cleaning.
extension ReadabilityClean on ReadabilityRun {
  /// Cleans [articleContent].
  void prepArticle(Element articleContent) {
    cleanStyles(articleContent);
    // Data tables first, so what is in them is not removed: they are often
    // set apart from the content they belong with.
    markDataTables(articleContent);
    fixLazyImages(articleContent);

    cleanConditionally(articleContent, 'form');
    cleanConditionally(articleContent, 'fieldset');
    clean(articleContent, 'object');
    clean(articleContent, 'embed');
    clean(articleContent, 'footer');
    clean(articleContent, 'link');
    clean(articleContent, 'aside');

    // Sharing buttons with little text, under the top candidates — never
    // the candidates themselves.
    final shareElementThreshold = const ReadabilityOptions().charThreshold;
    for (final topCandidate in articleContent.children.toList()) {
      cleanMatchedNodes(
        topCandidate,
        (node, matchString) =>
            ReadabilityPatterns.shareElements.hasMatch(matchString) &&
            node.text.length < shareElementThreshold,
      );
    }

    clean(articleContent, 'iframe');
    clean(articleContent, 'input');
    clean(articleContent, 'textarea');
    clean(articleContent, 'select');
    clean(articleContent, 'button');
    cleanHeaders(articleContent);

    // Last, as what was removed so far changes what these see.
    cleanConditionally(articleContent, 'table');
    cleanConditionally(articleContent, 'ul');
    cleanConditionally(articleContent, 'div');

    // The h1 is the title, shown apart.
    for (final h1 in elementsWithTag(articleContent, const ['h1'])) {
      setTag(h1, 'h2');
    }

    // Paragraphs with nothing in them; only video frames are left by now.
    removeNodes(
      elementsWithTag(articleContent, const ['p']),
      (paragraph) =>
          elementsWithTag(paragraph, const [
            'img',
            'embed',
            'object',
            'iframe',
          ]).isEmpty &&
          innerText(paragraph, normalizeSpaces: false).isEmpty,
    );

    for (final br in elementsWithTag(articleContent, const ['br'])) {
      final next = nextNode(nextSiblingOf(br));
      if (next != null && tagNameOf(next) == 'P') removeNode(br);
    }

    // A table of one cell is its content.
    for (final table in elementsWithTag(articleContent, const ['table'])) {
      final tbody = hasSingleTagInsideElement(table, 'TBODY')
          ? firstElementChildOf(table)!
          : table;
      if (!hasSingleTagInsideElement(tbody, 'TR')) continue;
      final row = firstElementChildOf(tbody)!;
      if (!hasSingleTagInsideElement(row, 'TD')) continue;
      final cell = setTag(
        firstElementChildOf(row)!,
        firstElementChildOf(row)!.nodes.every(isPhrasingContent) ? 'P' : 'DIV',
      );
      final parent = table.parentNode;
      if (parent != null) replaceChild(parent, cell, table);
    }
  }

  /// Removes `style` and the presentational attributes from [element] and
  /// everything under it, an `svg` left as it is (`_cleanStyles`).
  void cleanStyles(Element element) {
    if ((element.localName ?? '').toLowerCase() == 'svg') return;
    presentationalAttributes.forEach(element.attributes.remove);
    if (deprecatedSizeAttributeElems.contains(tagNameOf(element))) {
      element.attributes
        ..remove('width')
        ..remove('height');
    }
    element.children.toList().forEach(cleanStyles);
  }

  /// Removes every [tag] under [element] — but a frame, an object or an
  /// embed from a video host (`_clean`).
  void clean(Element element, String tag) {
    final isEmbed = const ['object', 'embed', 'iframe'].contains(tag);
    // Upstream also looks inside an `object` for a video host, behind a
    // test of `tagName` against "object" that an HTML document's upper
    // case never passes: left out.
    removeNodes(
      elementsWithTag(element, [tag]),
      (node) =>
          !isEmbed || !node.attributes.values.any(allowedVideoRegex.hasMatch),
    );
  }

  /// Removes the nodes under [element] that [filter] accepts, given their
  /// class and id (`_cleanMatchedNodes`).
  void cleanMatchedNodes(
    Element element,
    bool Function(Element node, String matchString) filter,
  ) {
    final endOfSearchMarkerNode = getNextNode(element, ignoreSelfAndKids: true);
    var next = getNextNode(element);
    while (next != null && next != endOfSearchMarkerNode) {
      next = filter(next, '${classNameOf(next)} ${next.id}')
          ? removeAndGetNext(next)
          : getNextNode(next);
    }
  }

  /// Removes the `h1`s and `h2`s whose class weighs against them
  /// (`_cleanHeaders`).
  void cleanHeaders(Element element) => removeNodes(
    elementsWithTag(element, const ['h1', 'h2']),
    (node) => classWeight(node) < 0,
  );
}
