/// The document made ready to be read: its styles and scripts gone, chains
/// of `br` made paragraphs, `font` made `span`, and the pictures a
/// `noscript` holds put in place of their placeholders.
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

/// Removes each of [nodes] still in the tree that [filter] accepts, from
/// the last to the first (`_removeNodes`).
void removeNodes(List<Element> nodes, [bool Function(Element node)? filter]) {
  for (var i = nodes.length - 1; i >= 0; i--) {
    final node = nodes[i];
    if (node.parentNode == null) continue;
    if (filter == null || filter(node)) removeNode(node);
  }
}

/// Readying the document.
extension ReadabilityPrep on ReadabilityRun {
  /// Removes the styles, makes paragraphs of `br` chains, and `span`s of
  /// `font`s (`_prepDocument`).
  void prepDocument() {
    removeNodes(elementsWithTag(doc, const ['style']));
    final body = doc.body;
    if (body != null) replaceBrs(body);
    for (final font in elementsWithTag(doc, const ['font'])) {
      setTag(font, 'SPAN');
    }
  }

  /// Replaces two or more `br`s in a row with a `p`: white space between
  /// them is ignored, and the phrasing content after them goes in the `p`
  /// (`_replaceBrs`). `<div>foo<br>bar<br> <br><br>abc</div>` becomes
  /// `<div>foo<br>bar<p>abc</p></div>`.
  void replaceBrs(Element element) {
    for (final br in elementsWithTag(element, const ['br'])) {
      var next = nextSiblingOf(br);
      // Whether a chain was found: its brs but the first are removed, and
      // the first becomes the p.
      var replaced = false;
      while ((next = nextNode(next)) != null && tagNameOf(next) == 'BR') {
        replaced = true;
        final brSibling = nextSiblingOf(next!);
        removeNode(next);
        next = brSibling;
      }
      if (!replaced) continue;
      final p = Element.tag('p');
      replaceChild(br.parentNode!, p, br);
      next = nextSiblingOf(p);
      while (next != null) {
        // Another chain of brs ends this p.
        if (tagNameOf(next) == 'BR') {
          final nextElem = nextNode(nextSiblingOf(next));
          if (nextElem != null && tagNameOf(nextElem) == 'BR') break;
        }
        if (!isPhrasingContent(next)) break;
        final sibling = nextSiblingOf(next);
        appendChild(p, next);
        next = sibling;
      }
      while (p.nodes.isNotEmpty && isWhitespace(p.nodes.last)) {
        removeNode(p.nodes.last);
      }
      final parent = p.parentNode;
      if (parent is Element && tagNameOf(parent) == 'P') setTag(parent, 'DIV');
    }
  }

  /// Puts the picture a `noscript` holds in place of the placeholder before
  /// it, keeping the placeholder's own picture attributes; first removes
  /// the `img`s with no picture at all (`_unwrapNoscriptImages`).
  void unwrapNoscriptImages() {
    for (final img in elementsWithTag(doc, const ['img'])) {
      final hasPicture = img.attributes.entries.any((attribute) {
        final name = attribute.key.toString();
        return name == 'src' ||
            name == 'srcset' ||
            name == 'data-src' ||
            name == 'data-srcset' ||
            ReadabilityPatterns.imageExtension.hasMatch(attribute.value);
      });
      if (!hasPicture) removeNode(img);
    }

    for (final noscript in elementsWithTag(doc, const ['noscript'])) {
      if (!isSingleImage(noscript)) continue;
      final tmp = Element.tag('div')..innerHtml = noscript.innerHtml;
      final prevElement = previousElementSiblingOf(noscript);
      if (prevElement == null || !isSingleImage(prevElement)) continue;
      final prevImg = tagNameOf(prevElement) == 'IMG'
          ? prevElement
          : elementsWithTag(prevElement, const ['img']).first;
      final images = elementsWithTag(tmp, const ['img']);
      if (images.isEmpty) continue;
      final newImg = images.first;
      for (final attribute in prevImg.attributes.entries.toList()) {
        final value = attribute.value;
        if (value.isEmpty) continue;
        final name = attribute.key.toString();
        if (name == 'src' ||
            name == 'srcset' ||
            ReadabilityPatterns.imageExtension.hasMatch(value)) {
          if (newImg.attributes[name] == value) continue;
          final attrName = newImg.attributes.containsKey(name)
              ? 'data-old-$name'
              : name;
          newImg.attributes[attrName] = value;
        }
      }
      final replacement = firstElementChildOf(tmp);
      if (replacement != null) {
        replaceChild(noscript.parentNode!, replacement, prevElement);
      }
    }
  }

  /// Removes the scripts and the `noscript`s (`_removeScripts`).
  void removeScripts() =>
      removeNodes(elementsWithTag(doc, const ['script', 'noscript']));
}
