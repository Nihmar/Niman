/// What Readability measures of a node: its text, how much of it is links,
/// whether it is white space, phrasing content, a single picture.
///
/// Ported from mozilla/readability (Readability.js 0.6.0, commit 04fd32f),
/// Apache-2.0.
library;

import 'package:html/dom.dart';
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/patterns.dart';

/// [node]'s text, trimmed, its runs of white space made one space unless
/// [normalizeSpaces] is false (`_getInnerText`).
///
/// ponytail: the text is gathered again on every call, as upstream's
/// `textContent` is; caching it per pass is the fix if a page is slow.
String innerText(Node node, {bool normalizeSpaces = true}) {
  final text = (node.text ?? '').trim();
  return normalizeSpaces
      ? text.replaceAll(ReadabilityPatterns.normalize, ' ')
      : text;
}

/// How many times [separator] is in [node]'s text (`_getCharCount`).
int charCount(Node node, [String separator = ',']) =>
    innerText(node).split(separator).length - 1;

/// The share of [element]'s text that is in links; a link within the page
/// counts for 0.3 (`_getLinkDensity`).
double linkDensity(Element element) {
  final textLength = innerText(element).length;
  if (textLength == 0) return 0;
  var linkLength = 0.0;
  for (final link in elementsWithTag(element, const ['a'])) {
    final href = attributeOf(link, 'href');
    final coefficient =
        href != null && ReadabilityPatterns.hashUrl.hasMatch(href) ? 0.3 : 1;
    linkLength += innerText(link).length * coefficient;
  }
  return linkLength / textLength;
}

/// The share of [element]'s text in elements of [tags] (`_getTextDensity`).
double textDensity(Element element, List<String> tags) {
  final textLength = innerText(element).length;
  if (textLength == 0) return 0;
  var childrenLength = 0;
  for (final child in elementsWithTag(element, tags)) {
    childrenLength += innerText(child).length;
  }
  return childrenLength / textLength;
}

/// How much of [textB]'s words are [textA]'s too: 1 the same text, 0 none
/// of it (`_textSimilarity`).
double textSimilarity(String textA, String textB) {
  List<String> tokens(String text) => text
      .toLowerCase()
      .split(ReadabilityPatterns.tokenize)
      .where((token) => token.isNotEmpty)
      .toList();
  final tokensA = tokens(textA);
  final tokensB = tokens(textB);
  if (tokensA.isEmpty || tokensB.isEmpty) return 0;
  final uniqTokensB = tokensB.where((token) => !tokensA.contains(token));
  final distanceB = uniqTokensB.join(' ').length / tokensB.join(' ').length;
  return 1 - distanceB;
}

/// Whether [node] is white space: a blank text, or a `br`.
bool isWhitespace(Node node) =>
    (node is Text && node.data.trim().isEmpty) || tagNameOf(node) == 'BR';

/// Whether [node] is phrasing content: text, a phrasing tag, or a link, a
/// `del` or an `ins` holding only phrasing content.
bool isPhrasingContent(Node node) {
  if (node is Text) return true;
  final tag = tagNameOf(node);
  if (phrasingElems.contains(tag)) return true;
  return (tag == 'A' || tag == 'DEL' || tag == 'INS') &&
      node.nodes.every(isPhrasingContent);
}

/// Whether [element] has a block element anywhere under it.
bool hasChildBlockElement(Node element) => element.nodes.any(
  (node) => divToPElems.contains(tagNameOf(node)) || hasChildBlockElement(node),
);

/// Whether [element] holds one element, a [tag], and no text but white
/// space.
bool hasSingleTagInsideElement(Element element, String tag) {
  final children = element.children;
  if (children.length != 1 || tagNameOf(children.first) != tag) return false;
  return !element.nodes.any(
    (node) =>
        node is Text && ReadabilityPatterns.hasContent.hasMatch(node.data),
  );
}

/// Whether [node] is an element with no text, and no children but `br`s
/// and `hr`s.
bool isElementWithoutContent(Node node) {
  if (node is! Element || node.text.trim().isNotEmpty) return false;
  final children = node.children.length;
  return children == 0 ||
      children ==
          elementsWithTag(node, const ['br']).length +
              elementsWithTag(node, const ['hr']).length;
}

/// Whether [node] is probably drawn: not hidden by its style, by `hidden`,
/// or by `aria-hidden` — a Wikimedia formula's fallback picture aside.
bool isProbablyVisible(Element node) {
  if (inlineStyleOf(node, 'display') == 'none') return false;
  if (inlineStyleOf(node, 'visibility') == 'hidden') return false;
  if (node.attributes.containsKey('hidden')) return false;
  return attributeOf(node, 'aria-hidden') != 'true' ||
      classNameOf(node).contains('fallback-image');
}

/// Whether [node] is a picture, or holds only one, alone all the way down.
bool isSingleImage(Element? node) {
  var at = node;
  while (at != null) {
    if (tagNameOf(at) == 'IMG') return true;
    if (at.children.length != 1 || at.text.trim().isNotEmpty) return false;
    at = at.children.first;
  }
  return false;
}
