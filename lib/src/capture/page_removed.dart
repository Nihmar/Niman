/// What a capture leaves out of a page (#531), for the desktop dialog's
/// "Removed": its scripts and styles, its menu, a cookie banner, and the
/// words around the article — the footer, the related posts.
///
/// Counted outside the Readability port, over the page as it was parsed,
/// so the port stays exactly what upstream's test pages check.
library;

import 'package:html/dom.dart';
import 'package:niman/src/capture/readability/dom.dart';

/// What was left out.
typedef PageRemoved = ({
  int scripts,
  int styles,
  bool menu,
  bool banner,
  int wordsAround,
});

/// Nothing left out: a page read without an article.
const PageRemoved nothingRemoved = (
  scripts: 0,
  styles: 0,
  menu: false,
  banner: false,
  wordsAround: 0,
);

final _words = RegExp(r'\S+');
final _banner = RegExp('cookie|consent|gdpr', caseSensitive: false);

/// The words in [text].
int wordCount(String text) => _words.allMatches(text).length;

/// What of [document] — read before Readability changes it — is not in
/// an article of [articleWords] words.
PageRemoved removedFrom(Document document, {required int articleWords}) {
  final elements = allElements(document);
  bool any(bool Function(Element element) test) => elements.any(test);
  final body = document.body;
  // A page's words, its scripts' and styles' left out.
  var pageWords = 0;
  void count(Node node) {
    for (final child in node.nodes) {
      if (child is Text) {
        pageWords += wordCount(child.data);
      } else if (child is Element &&
          child.localName != 'script' &&
          child.localName != 'style' &&
          child.localName != 'noscript') {
        count(child);
      }
    }
  }

  if (body != null) count(body);
  return (
    scripts: elements.where((e) => e.localName == 'script').length,
    styles: elements
        .where(
          (e) =>
              e.localName == 'style' ||
              (e.localName == 'link' &&
                  attributeOf(e, 'rel')?.toLowerCase() == 'stylesheet'),
        )
        .length,
    menu: any(
      (e) => e.localName == 'nav' || attributeOf(e, 'role') == 'navigation',
    ),
    banner: any(
      (e) =>
          (e.localName == 'div' ||
              e.localName == 'section' ||
              e.localName == 'aside') &&
          _banner.hasMatch('${e.className} ${e.id}'),
    ),
    wordsAround: pageWords > articleWords ? pageWords - articleWords : 0,
  );
}
