/// Grabbing the article (`_grabArticle`): the walk, the scores, the top
/// candidate and the siblings that belong with it, cleaned — retried with
/// fewer flags while the text found is too short, and the longest attempt
/// taken when none is long enough.
///
/// Ported from mozilla/readability (Readability.js 0.6.0, commit 04fd32f),
/// Apache-2.0.
library;

import 'package:html/dom.dart';
import 'package:niman/src/capture/readability/clean.dart';
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/grab_score.dart';
import 'package:niman/src/capture/readability/grab_walk.dart';
import 'package:niman/src/capture/readability/patterns.dart';
import 'package:niman/src/capture/readability/run.dart';
import 'package:niman/src/capture/readability/text_metrics.dart';
import 'package:niman/src/capture/readability/traversal.dart';

/// The grabbing.
extension ReadabilityGrab on ReadabilityRun {
  /// The article, in a `div` of its own; null when the body is missing or
  /// no attempt found any text.
  Element? grabArticle() {
    final page = doc.body;
    if (page == null) return null;
    // Upstream keeps the body's HTML and sets it back for each retry; a
    // copy of its tree does the same here.
    final pageCache = page.clone(true);
    final attempts = <({Element articleContent, int textLength})>[];

    while (true) {
      final candidates = scoreParagraphs(prepareNodes());
      final top = chooseTopCandidate(candidates, page);
      final topCandidate = top.node;
      final parentOfTopCandidate = topCandidate.parentNode!;
      // Upstream calls this with no page, which it takes for paging.
      var articleContent = Element.tag('div')..id = 'readability-content';
      _joinSiblings(articleContent, topCandidate, parentOfTopCandidate);
      prepArticle(articleContent);

      if (top.created) {
        // The made div is in the article already: only named.
        topCandidate
          ..id = 'readability-page-1'
          ..className = 'page';
      } else {
        final div = Element.tag('div')
          ..id = 'readability-page-1'
          ..className = 'page';
        while (articleContent.nodes.isNotEmpty) {
          appendChild(div, articleContent.nodes.first);
        }
        appendChild(articleContent, div);
      }

      // Too little text: the body back as it was, and another try with one
      // flag fewer; with none left, the longest attempt.
      final textLength = innerText(articleContent).length;
      if (textLength < options.charThreshold) {
        page.nodes.clear();
        page.nodes.addAll(pageCache.clone(true).nodes.toList());
        attempts.add((articleContent: articleContent, textLength: textLength));
        if (flagIsActive(ReadabilityRun.flagStripUnlikelys)) {
          removeFlag(ReadabilityRun.flagStripUnlikelys);
          continue;
        }
        if (flagIsActive(ReadabilityRun.flagWeightClasses)) {
          removeFlag(ReadabilityRun.flagWeightClasses);
          continue;
        }
        if (flagIsActive(ReadabilityRun.flagCleanConditionally)) {
          removeFlag(ReadabilityRun.flagCleanConditionally);
          continue;
        }
        attempts.sort((a, b) => b.textLength - a.textLength);
        if (attempts.first.textLength == 0) return null;
        articleContent = attempts.first.articleContent;
      }

      // The text's direction, from the top candidate's ancestors.
      for (final ancestor in [
        parentOfTopCandidate,
        topCandidate,
        ...getNodeAncestors(parentOfTopCandidate),
      ]) {
        if (ancestor is! Element) continue;
        final dir = attributeOf(ancestor, 'dir');
        if (dir != null && dir.isNotEmpty) {
          articleDir = dir;
          break;
        }
      }
      return articleContent;
    }
  }

  /// Moves [topCandidate] and the siblings that look like more of it —
  /// preambles, content split by ads — into [articleContent].
  void _joinSiblings(
    Element articleContent,
    Element topCandidate,
    Node parentOfTopCandidate,
  ) {
    final topScore = scoreOf(topCandidate)!.contentScore;
    final siblingScoreThreshold = topScore * 0.2 > 10 ? topScore * 0.2 : 10.0;
    final topClass = classNameOf(topCandidate);
    var siblings = parentOfTopCandidate.children;
    for (var s = 0, sl = siblings.length; s < sl; s++) {
      var sibling = siblings[s];
      var append = false;
      if (sibling == topCandidate) {
        append = true;
      } else {
        // A bonus for a sibling with the top candidate's class.
        final contentBonus = classNameOf(sibling) == topClass && topClass != ''
            ? topScore * 0.2
            : 0.0;
        final siblingScore = scoreOf(sibling);
        if (siblingScore != null &&
            siblingScore.contentScore + contentBonus >= siblingScoreThreshold) {
          append = true;
        } else if (tagNameOf(sibling) == 'P') {
          final density = linkDensity(sibling);
          final nodeContent = innerText(sibling);
          final nodeLength = nodeContent.length;
          if (nodeLength > 80 && density < 0.25) {
            append = true;
          } else if (nodeLength < 80 &&
              nodeLength > 0 &&
              density == 0 &&
              nodeContent.contains(RegExp(r'\.( |$)'))) {
            append = true;
          }
        }
      }
      if (!append) continue;
      // Not a common block (a form, a td): a div, so it is not filtered
      // out later by accident.
      if (!alterToDivExceptions.contains(tagNameOf(sibling))) {
        sibling = setTag(sibling, 'DIV');
      }
      appendChild(articleContent, sibling);
      // The sibling left the list: its index is visited again.
      siblings = parentOfTopCandidate.children;
      s -= 1;
      sl -= 1;
    }
  }
}
