/// The first pass of grabbing the article: a walk over the whole document
/// that removes what is hidden, the byline, the heading that repeats the
/// title and what is probably not the article, and turns the `div`s used
/// as paragraphs into `p`s — gathering the elements to score.
///
/// Ported from mozilla/readability (Readability.js 0.6.0, commit 04fd32f),
/// Apache-2.0.
library;

import 'package:html/dom.dart';
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/metadata.dart';
import 'package:niman/src/capture/readability/patterns.dart';
import 'package:niman/src/capture/readability/run.dart';
import 'package:niman/src/capture/readability/text_metrics.dart';
import 'package:niman/src/capture/readability/traversal.dart';

/// The walk.
extension ReadabilityGrabWalk on ReadabilityRun {
  /// Walks the document, and gives the elements to score.
  List<Element> prepareNodes() {
    final elementsToScore = <Element>[];
    final stripUnlikelyCandidates = flagIsActive(
      ReadabilityRun.flagStripUnlikelys,
    );
    var shouldRemoveTitleHeader = true;
    var node = doc.documentElement;

    while (node != null) {
      final tag = tagNameOf(node);
      if (tag == 'HTML') articleLang = attributeOf(node, 'lang');
      final matchString = '${classNameOf(node)} ${node.id}';

      if (!isProbablyVisible(node)) {
        node = removeAndGetNext(node);
        continue;
      }

      // Not seen by the reader: a modal dialog.
      if (attributeOf(node, 'aria-modal') == 'true' &&
          attributeOf(node, 'role') == 'dialog') {
        node = removeAndGetNext(node);
        continue;
      }

      // The byline, while there is none: kept, and removed from the page.
      if (articleByline == null &&
          metadataByline == null &&
          isValidByline(node, matchString)) {
        // A child with itemprop="name" names the author more exactly.
        final endOfSearchMarkerNode = getNextNode(
          node,
          ignoreSelfAndKids: true,
        );
        var next = getNextNode(node);
        Element? itemPropNameNode;
        while (next != null && next != endOfSearchMarkerNode) {
          final itemprop = attributeOf(next, 'itemprop');
          if (itemprop != null && itemprop.contains('name')) {
            itemPropNameNode = next;
            break;
          }
          next = getNextNode(next);
        }
        articleByline = (itemPropNameNode ?? node).text.trim();
        node = removeAndGetNext(node);
        continue;
      }

      if (shouldRemoveTitleHeader && headerDuplicatesTitle(node)) {
        shouldRemoveTitleHeader = false;
        node = removeAndGetNext(node);
        continue;
      }

      if (stripUnlikelyCandidates) {
        if (ReadabilityPatterns.unlikelyCandidates.hasMatch(matchString) &&
            !ReadabilityPatterns.okMaybeItsACandidate.hasMatch(matchString) &&
            !hasAncestorTag(node, 'table') &&
            !hasAncestorTag(node, 'code') &&
            tag != 'BODY' &&
            tag != 'A') {
          node = removeAndGetNext(node);
          continue;
        }
        if (unlikelyRoles.contains(attributeOf(node, 'role'))) {
          node = removeAndGetNext(node);
          continue;
        }
      }

      // Blocks and headings with nothing in them: no text, picture, video
      // or frame.
      if ((tag == 'DIV' ||
              tag == 'SECTION' ||
              tag == 'HEADER' ||
              tag == 'H1' ||
              tag == 'H2' ||
              tag == 'H3' ||
              tag == 'H4' ||
              tag == 'H5' ||
              tag == 'H6') &&
          isElementWithoutContent(node)) {
        node = removeAndGetNext(node);
        continue;
      }

      if (defaultTagsToScore.contains(tag)) elementsToScore.add(node);

      // A div with no block child is a paragraph.
      if (tag == 'DIV') {
        node = _divToParagraphs(node, elementsToScore);
      }
      node = getNextNode(node);
    }
    return elementsToScore;
  }

  /// Puts [div]'s phrasing content in paragraphs, then makes [div] itself a
  /// `p` when it is one: the node the walk goes on from.
  Element _divToParagraphs(Element div, List<Element> elementsToScore) {
    Element? p;
    var childNode = div.firstChild;
    while (childNode != null) {
      final nextSibling = nextSiblingOf(childNode);
      if (isPhrasingContent(childNode)) {
        if (p != null) {
          appendChild(p, childNode);
        } else if (!isWhitespace(childNode)) {
          p = Element.tag('p');
          replaceChild(div, p, childNode);
          appendChild(p, childNode);
        }
      } else if (p != null) {
        while (p.nodes.isNotEmpty && isWhitespace(p.nodes.last)) {
          removeNode(p.nodes.last);
        }
        p = null;
      }
      childNode = nextSibling;
    }

    // A div holding one p and no text is the p: sites wrap each paragraph
    // in a div, which confuses the scores.
    if (hasSingleTagInsideElement(div, 'P') && linkDensity(div) < 0.25) {
      final newNode = div.children.first;
      replaceChild(div.parentNode!, newNode, div);
      elementsToScore.add(newNode);
      return newNode;
    }
    if (!hasChildBlockElement(div)) {
      final paragraph = setTag(div, 'P');
      elementsToScore.add(paragraph);
      return paragraph;
    }
    return div;
  }
}
