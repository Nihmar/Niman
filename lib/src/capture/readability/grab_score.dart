/// The second pass of grabbing the article: each paragraph is scored by
/// its commas and its length, the score shared out to its ancestors, and
/// the best of them chosen — or a better ancestor of it.
///
/// Ported from mozilla/readability (Readability.js 0.6.0, commit 04fd32f),
/// Apache-2.0.
library;

import 'dart:math' as math;

import 'package:html/dom.dart';
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/patterns.dart';
import 'package:niman/src/capture/readability/run.dart';
import 'package:niman/src/capture/readability/text_metrics.dart';
import 'package:niman/src/capture/readability/traversal.dart';

/// The candidate chosen: the article's root, and whether it had to be made
/// out of the whole body.
typedef TopCandidate = ({Element node, bool created});

/// The scoring.
extension ReadabilityGrabScore on ReadabilityRun {
  /// Scores [elementsToScore] into their ancestors, and gives the
  /// candidates scored.
  List<Element> scoreParagraphs(List<Element> elementsToScore) {
    final candidates = <Element>[];
    for (final elementToScore in elementsToScore) {
      if (elementToScore.parentNode is! Element) continue;
      // Under 25 characters, a paragraph does not count.
      final text = innerText(elementToScore);
      if (text.length < 25) continue;
      final ancestors = getNodeAncestors(elementToScore, 5);
      if (ancestors.isEmpty) continue;

      // One for the paragraph, one per comma, one per 100 characters up to
      // three.
      final contentScore =
          1 +
          text.split(ReadabilityPatterns.commas).length +
          math.min(text.length ~/ 100, 3);

      for (final (level, ancestor) in ancestors.indexed) {
        if (ancestor is! Element || ancestor.parentNode is! Element) continue;
        var score = scoreOf(ancestor);
        if (score == null) {
          score = initializeNode(ancestor);
          candidates.add(ancestor);
        }
        // The parent gets it all, the grandparent half, the rest a third
        // of it per level.
        final scoreDivider = switch (level) {
          0 => 1,
          1 => 2,
          _ => level * 3,
        };
        score.contentScore += contentScore / scoreDivider;
      }
    }
    return candidates;
  }

  /// The best of [candidates], their scores scaled by their link density;
  /// the body when there is none, its content moved into a new `div` of
  /// [page].
  TopCandidate chooseTopCandidate(List<Element> candidates, Element page) {
    final topCandidates = <Element>[];
    for (final candidate in candidates) {
      // Good content has few links, and keeps most of its score.
      final score = scoreOf(candidate)!
        ..contentScore *= 1 - linkDensity(candidate);
      for (var t = 0; t < options.nbTopCandidates; t++) {
        if (t >= topCandidates.length ||
            score.contentScore > scoreOf(topCandidates[t])!.contentScore) {
          topCandidates.insert(t, candidate);
          if (topCandidates.length > options.nbTopCandidates) {
            topCandidates.removeLast();
          }
          break;
        }
      }
    }

    var topCandidate = topCandidates.firstOrNull;
    if (topCandidate == null || tagNameOf(topCandidate) == 'BODY') {
      // The whole page, text directly in the body included, in a div of
      // its own.
      final created = Element.tag('div');
      while (page.nodes.isNotEmpty) {
        appendChild(created, page.nodes.first);
      }
      appendChild(page, created);
      initializeNode(created);
      return (node: created, created: true);
    }

    topCandidate = _sharedAncestor(topCandidate, topCandidates);
    if (scoreOf(topCandidate) == null) initializeNode(topCandidate);
    topCandidate = _betterParent(topCandidate);

    // An only child stands for its parent, so the siblings joined next are
    // the parent's.
    var parent = topCandidate.parentNode;
    while (parent is Element &&
        tagNameOf(parent) != 'BODY' &&
        parent.children.length == 1) {
      topCandidate = parent;
      parent = topCandidate.parentNode;
    }
    if (scoreOf(topCandidate!) == null) initializeNode(topCandidate);
    return (node: topCandidate, created: false);
  }

  /// An ancestor of [topCandidate] that holds at least three of the other
  /// [topCandidates] scored close to it, else [topCandidate].
  Element _sharedAncestor(Element topCandidate, List<Element> topCandidates) {
    const minimumTopCandidates = 3;
    final topScore = scoreOf(topCandidate)!.contentScore;
    final alternativeCandidateAncestors = [
      for (final other in topCandidates.skip(1))
        if (scoreOf(other)!.contentScore / topScore >= 0.75)
          getNodeAncestors(other),
    ];
    if (alternativeCandidateAncestors.length < minimumTopCandidates) {
      return topCandidate;
    }
    var parent = topCandidate.parentNode;
    while (parent is Element && tagNameOf(parent) != 'BODY') {
      var listsContainingThisAncestor = 0;
      for (final ancestors in alternativeCandidateAncestors) {
        if (listsContainingThisAncestor >= minimumTopCandidates) break;
        if (ancestors.contains(parent)) listsContainingThisAncestor++;
      }
      if (listsContainingThisAncestor >= minimumTopCandidates) return parent;
      parent = parent.parentNode;
    }
    return topCandidate;
  }

  /// A parent of [topCandidate] whose score rises over its own on the way
  /// up — more content to unify in — before the scores fall under a third.
  Element _betterParent(Element topCandidate) {
    var parent = topCandidate.parentNode;
    var lastScore = scoreOf(topCandidate)!.contentScore;
    final scoreThreshold = lastScore / 3;
    while (parent is Element && tagNameOf(parent) != 'BODY') {
      final parentScore = scoreOf(parent)?.contentScore;
      if (parentScore == null) {
        parent = parent.parentNode;
        continue;
      }
      if (parentScore < scoreThreshold) break;
      if (parentScore > lastScore) return parent;
      lastScore = parentScore;
      parent = parent.parentNode;
    }
    return topCandidate;
  }
}
