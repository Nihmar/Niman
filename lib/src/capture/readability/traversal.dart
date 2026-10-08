/// How Readability walks the tree: depth first over elements, a node's
/// ancestors, and the next node that is not white space.
///
/// Ported from mozilla/readability (Readability.js 0.6.0, commit 04fd32f),
/// Apache-2.0.
library;

import 'package:html/dom.dart';
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/patterns.dart';

/// The next node from [node] on that is an element or has text — [node]
/// itself when it is one (`_nextNode`).
Node? nextNode(Node? node) {
  var next = node;
  while (next != null &&
      next is! Element &&
      ReadabilityPatterns.whitespace.hasMatch(next.text ?? '')) {
    next = nextSiblingOf(next);
  }
  return next;
}

/// The element after [node] in a depth-first walk: its first child unless
/// [ignoreSelfAndKids], else its next sibling, else its nearest ancestor's
/// next sibling (`_getNextNode`).
Element? getNextNode(Node node, {bool ignoreSelfAndKids = false}) {
  if (!ignoreSelfAndKids) {
    final child = firstElementChildOf(node);
    if (child != null) return child;
  }
  final sibling = nextElementSiblingOf(node);
  if (sibling != null) return sibling;
  Node? up = node;
  do {
    up = up!.parentNode;
  } while (up != null && nextElementSiblingOf(up) == null);
  return up == null ? null : nextElementSiblingOf(up);
}

/// Removes [node] and gives the element the walk goes on to.
Element? removeAndGetNext(Node node) {
  final next = getNextNode(node, ignoreSelfAndKids: true);
  removeNode(node);
  return next;
}

/// [node]'s ancestors, nearest first, the document included; at most
/// [maxDepth] of them unless it is 0.
List<Node> getNodeAncestors(Node node, [int maxDepth = 0]) {
  final ancestors = <Node>[];
  var i = 0;
  Node? at = node;
  while (at!.parentNode != null) {
    ancestors.add(at.parentNode!);
    if (maxDepth > 0 && ++i == maxDepth) break;
    at = at.parentNode;
  }
  return ancestors;
}

/// Whether an ancestor of [node] within [maxDepth] levels (no limit when it
/// is negative) is a [tagName] that [filter] accepts.
bool hasAncestorTag(
  Node node,
  String tagName, {
  int maxDepth = 3,
  bool Function(Element)? filter,
}) {
  final tag = tagName.toUpperCase();
  var depth = 0;
  Node? at = node;
  while (at!.parentNode != null) {
    if (maxDepth > 0 && depth > maxDepth) return false;
    final parent = at.parentNode!;
    if (tagNameOf(parent) == tag &&
        (filter == null || filter(parent as Element))) {
      return true;
    }
    at = parent;
    depth++;
  }
  return false;
}
