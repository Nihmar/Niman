/// The DOM the port walks: `package:html`'s, with what Readability.js reads
/// of a browser's DOM and `package:html` 0.15.7 lacks or does otherwise.
///
/// Ported from mozilla/readability (Readability.js 0.6.0, commit 04fd32f),
/// Apache-2.0.
///
/// - `tagName` is upper case for HTML elements and as written for SVG and
///   MathML ones, as a browser has it ([tagNameOf]).
/// - `remove()` in `package:html` leaves the node's `parentNode` pointing at
///   the parent it left, and Readability skips nodes by that pointer:
///   [removeNode] clears it, and every move goes through it.
/// - Siblings of any node, not only of elements ([nextSiblingOf]).
/// - A tag cannot be renamed (`localName` is final): [setNodeTag] makes the
///   new element, as Readability.js itself does outside its own parser.
/// - A `noscript` is always parsed as text, as by a browser that runs
///   scripts; upstream's tests parse it as markup, and its pictures are
///   unwrapped from it: [parseNoscripts].
library;

import 'dart:collection';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

/// The HTML namespace, which `package:html` keeps to itself.
const String _htmlNamespace = 'http://www.w3.org/1999/xhtml';

/// The `tagName` a browser gives [node]: `DIV` for an HTML `div`, `svg` for
/// an SVG one, and null for what is not an element.
String? tagNameOf(Node? node) {
  if (node is! Element) return null;
  final name = node.localName ?? '';
  return node.namespaceUri == _htmlNamespace ? name.toUpperCase() : name;
}

/// Whether [node] is an element in the HTML namespace.
bool isHtmlElement(Node? node) =>
    node is Element && node.namespaceUri == _htmlNamespace;

/// The `className` Readability reads: an HTML element's `class`, and nothing
/// for an SVG one, whose `className` is not a string in a browser.
String classNameOf(Element element) =>
    isHtmlElement(element) ? element.className : '';

/// The attribute [name] of [element], or null.
String? attributeOf(Element element, String name) => element.attributes[name];

/// Takes [node] out of its parent, its parent pointer cleared.
void removeNode(Node node) {
  final parent = node.parentNode;
  if (parent == null) return;
  parent.nodes.remove(node);
  node.parentNode = null;
}

/// Appends [child] to [parent], taking it out of where it was.
void appendChild(Node parent, Node child) {
  removeNode(child);
  parent.nodes.add(child);
}

/// Puts [replacement] where [old] is in [parent], taking it out of where it
/// was — a sibling of [old] included.
void replaceChild(Node parent, Node replacement, Node old) {
  removeNode(replacement);
  final index = parent.nodes.indexOf(old);
  if (index < 0) return;
  parent.nodes[index] = replacement;
}

/// The node after [node] among its parent's, or null.
Node? nextSiblingOf(Node node) {
  final parent = node.parentNode;
  if (parent == null) return null;
  final siblings = parent.nodes;
  final index = siblings.indexOf(node);
  return index + 1 < siblings.length ? siblings[index + 1] : null;
}

/// The first child element of [node], or null.
Element? firstElementChildOf(Node node) {
  for (final child in node.nodes) {
    if (child is Element) return child;
  }
  return null;
}

/// The next element among [node]'s siblings, or null.
Element? nextElementSiblingOf(Node node) {
  final parent = node.parentNode;
  if (parent == null) return null;
  final siblings = parent.nodes;
  // ponytail: a linear search per step, so a walk over a parent with n
  // children is O(n²); an index per pass if the perf test asks for it.
  for (var i = siblings.indexOf(node) + 1; i < siblings.length; i++) {
    final sibling = siblings[i];
    if (sibling is Element) return sibling;
  }
  return null;
}

/// The previous element among [node]'s siblings, or null.
Element? previousElementSiblingOf(Node node) {
  final parent = node.parentNode;
  if (parent == null) return null;
  final siblings = parent.nodes;
  for (var i = siblings.indexOf(node) - 1; i >= 0; i--) {
    final sibling = siblings[i];
    if (sibling is Element) return sibling;
  }
  return null;
}

/// The elements under [root] whose tag is one of [tags] (lower case), in
/// document order, [root] itself left out — `querySelectorAll` of a list of
/// type selectors, and `getElementsByTagName`.
List<Element> elementsWithTag(Node root, List<String> tags) {
  final found = <Element>[];
  void walk(Node node) {
    for (final child in node.nodes) {
      if (child is! Element) continue;
      // An HTML element's name is lower case already; an SVG one's matches
      // as written, as a type selector matches it.
      if (tags.contains(child.localName)) found.add(child);
      walk(child);
    }
  }

  walk(root);
  return found;
}

/// Every element under [root], in document order.
List<Element> allElements(Node root) {
  final found = <Element>[];
  void walk(Node node) {
    for (final child in node.nodes) {
      if (child is! Element) continue;
      found.add(child);
      walk(child);
    }
  }

  walk(root);
  return found;
}

/// Gives [node] the tag [tag]: a new element, [node]'s children and
/// attributes moved to it, in [node]'s place. [onMoved] carries what the
/// caller keeps per node over to the new one.
Element setNodeTag(
  Element node,
  String tag, {
  void Function(Element from, Element to)? onMoved,
}) {
  final replacement = Element.tag(tag.toLowerCase());
  while (node.nodes.isNotEmpty) {
    appendChild(replacement, node.nodes.first);
  }
  final parent = node.parentNode;
  if (parent != null) replaceChild(parent, replacement, node);
  onMoved?.call(node, replacement);
  replacement.attributes = LinkedHashMap<Object, String>.of(node.attributes);
  return replacement;
}

/// The value of [property] in [element]'s inline `style`, as
/// `element.style[property]` reads it: the last declaration's, without
/// `!important`; null when there is none.
String? inlineStyleOf(Element element, String property) {
  final style = element.attributes['style'];
  if (style == null) return null;
  String? value;
  for (final declaration in style.split(';')) {
    final colon = declaration.indexOf(':');
    if (colon < 0) continue;
    final name = declaration.substring(0, colon).trim().toLowerCase();
    if (name != property) continue;
    value = declaration
        .substring(colon + 1)
        .replaceFirst(RegExp(r'!\s*important\s*$', caseSensitive: false), '')
        .trim()
        .toLowerCase();
  }
  return value;
}

/// Parses the text of each `noscript` under [root] as the markup it is, as
/// a browser that runs no scripts does.
void parseNoscripts(Node root) {
  for (final noscript in elementsWithTag(root, const ['noscript'])) {
    if (noscript.nodes.length != 1 || noscript.nodes.first is! Text) continue;
    final markup = (noscript.nodes.first as Text).data;
    noscript.nodes
      ..clear()
      ..addAll(html.parseFragment(markup).nodes.toList());
  }
}
