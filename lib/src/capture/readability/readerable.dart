/// Whether a page probably has an article, decided without reading it all
/// (`isProbablyReaderable`): enough long paragraphs that are drawn and not
/// in a menu, a footer or a list.
///
/// Ported from mozilla/readability (Readability-readerable.js 0.6.0, commit
/// 04fd32f), Apache-2.0.
library;

import 'dart:math' as math;

import 'package:html/dom.dart';
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/traversal.dart';

// NOTE: These two regular expressions are duplicated from patterns.dart, as
// upstream duplicates them in Readability.js.
final _unlikelyCandidates = RegExp(
  '-ad-|ai2html|banner|breadcrumbs|combx|comment|community|cover-wrap|'
  'disqus|extra|footer|gdpr|header|legends|menu|related|remark|replies|'
  'rss|shoutbox|sidebar|skyscraper|social|sponsor|supplemental|ad-break|'
  'agegate|pagination|pager|popup|yom-remote',
  caseSensitive: false,
);
final _okMaybeItsACandidate = RegExp(
  'and|article|body|column|content|main|shadow',
  caseSensitive: false,
);

/// Whether [node] is drawn: upstream's own test, which — unlike the
/// reader's — does not look at `visibility`.
bool _isNodeVisible(Element node) =>
    inlineStyleOf(node, 'display') != 'none' &&
    !node.attributes.containsKey('hidden') &&
    (attributeOf(node, 'aria-hidden') != 'true' ||
        classNameOf(node).contains('fallback-image'));

/// Whether [doc] probably has an article: its drawn `p`, `pre` and
/// `article` elements — and `div`s holding `br`s — of at least
/// [minContentLength] characters add up to over [minScore].
bool isProbablyReaderable(
  Document doc, {
  int minContentLength = 140,
  double minScore = 20,
}) {
  final nodes = <Element>{
    ...elementsWithTag(doc, const ['p', 'pre', 'article']),
    // Some articles are a div of sentences and brs.
    for (final br in elementsWithTag(doc, const ['br']))
      if (tagNameOf(br.parentNode) == 'DIV') br.parentNode! as Element,
  };
  var score = 0.0;
  for (final node in nodes) {
    if (!_isNodeVisible(node)) continue;
    final matchString = '${classNameOf(node)} ${node.id}';
    if (_unlikelyCandidates.hasMatch(matchString) &&
        !_okMaybeItsACandidate.hasMatch(matchString)) {
      continue;
    }
    if (tagNameOf(node) == 'P' && hasAncestorTag(node, 'li', maxDepth: -1)) {
      continue;
    }
    final textContentLength = node.text.trim().length;
    if (textContentLength < minContentLength) continue;
    score += math.sqrt(textContentLength - minContentLength);
    if (score > minScore) return true;
  }
  return false;
}
