/// The footnotes of a page: where its notes are written, and which of its
/// links cite them.
library;

import 'package:html/dom.dart';

/// A page's footnotes, found before the page is written.
///
/// A note is a definition — an `li[id]` in the list a page ends with
/// (`section.footnotes`, `div.footnotes`, `[role=doc-endnotes]`: Niman's own
/// export, Pandoc, Hugo, Python-Markdown…) or an `aside` of its own
/// (`role="doc-footnote"`, `epub:type="footnote"`). A link to one is a
/// reference, whatever tags it — a `<sup>` around the link, a `<sup>` in it,
/// a `role="doc-noteref"` — and is written `[^n]`, numbered in the order the
/// page first cites them. The definitions are written once, at the end, and
/// the links back from them to the text are left out.
final class HtmlFootnotes {
  /// The footnotes of the page under [root].
  new(Element root) {
    final containers = <Element>[];
    for (final element in root.querySelectorAll('*')) {
      if (_isContainer(element)) {
        containers.add(element);
      } else if (_isDefinition(element) && element.id.isNotEmpty) {
        _definitions.putIfAbsent(element.id, () => element);
      }
    }
    for (final container in containers) {
      for (final item in container.querySelectorAll('li[id]')) {
        _definitions.putIfAbsent(item.id, () => item);
      }
    }
    if (_definitions.isEmpty) return;
    final definitions = _definitions.values.toList();
    for (final container in containers) {
      if (definitions.any((note) => _isInside(note, container))) {
        _skipped.add(container);
      }
    }
    _skipped.addAll(definitions);
    for (final definition in definitions) {
      for (final link in definition.querySelectorAll('a')) {
        if (_isBacklink(link)) _backlinks.add(link);
      }
    }
  }

  final Map<String, Element> _definitions = <String, Element>{};

  /// What is not written where it stands: the lists of notes, and the
  /// notes.
  final Set<Element> _skipped = <Element>{};

  final Set<Element> _backlinks = <Element>{};

  /// The notes cited so far, by their ids, in order: a note's number is its
  /// place here from one.
  final List<String> _cited = <String>[];

  final Map<String, int> _numbers = <String, int>{};

  /// Whether [element] is written at the end, not where it stands.
  bool isNote(Element element) => _skipped.contains(element);

  /// Whether [link] leads from a note back to where it is cited.
  bool isBacklink(Element link) => _backlinks.contains(link);

  /// The number of the note [link] cites, citing it if it is the first
  /// time; null when [link] does not point at a note.
  int? cite(Element link) {
    if (_definitions.isEmpty || _backlinks.contains(link)) return null;
    final href = link.attributes['href'] ?? '';
    if (!href.startsWith('#') || href.length < 2) return null;
    final id = _decoded(href.substring(1));
    if (!_definitions.containsKey(id)) return null;
    return _numbers.putIfAbsent(id, () {
      _cited.add(id);
      return _cited.length;
    });
  }

  /// The notes, as `[^n]: text` lines in number order, [textOf] giving a
  /// note's words. The notes the page cites come first, in the order it
  /// does, then those it never cites — a note is not lost for want of a
  /// link this reads — and a note may cite another, which [textOf] finds.
  List<String> definitions(String Function(Element note) textOf) {
    final out = <String>[];
    var written = 0;
    void drain() {
      while (written < _cited.length) {
        final text = textOf(_definitions[_cited[written]]!);
        written++;
        out.add(text.isEmpty ? '[^$written]:' : '[^$written]: $text');
      }
    }

    drain();
    for (final id in _definitions.keys) {
      if (_numbers.containsKey(id)) continue;
      _numbers[id] = _cited.length + 1;
      _cited.add(id);
      drain();
    }
    return out;
  }

  static bool _isInside(Node node, Element container) {
    for (Node? up = node.parent; up != null; up = up.parent) {
      if (up == container) return true;
    }
    return false;
  }

  static String _decoded(String id) {
    try {
      return Uri.decodeComponent(id);
    } on FormatException {
      return id;
    }
  }

  static bool _isContainer(Element element) {
    if (!_containerTags.contains(element.localName)) return false;
    final classes = element.classes;
    return classes.contains('footnotes') ||
        classes.contains('footnote') ||
        classes.contains('endnotes') ||
        _roles(element).any(_containerRoles.contains) ||
        _types(element).any(_containerTypes.contains);
  }

  static bool _isDefinition(Element element) =>
      _roles(element).any(_noteRoles.contains) ||
      _types(element).any(_noteTypes.contains);

  static bool _isBacklink(Element link) {
    if (_roles(link).contains('doc-backlink') ||
        link.attributes.containsKey('data-footnote-backref') ||
        _backClass.hasMatch(link.className)) {
      return true;
    }
    final text = link.text.replaceAll('︎', '').trim();
    return _backMarks.contains(text);
  }

  static Iterable<String> _roles(Element element) =>
      (element.attributes['role'] ?? '').split(_blank);

  static Iterable<String> _types(Element element) =>
      (element.attributes['epub:type'] ?? '').split(_blank);

  static final RegExp _blank = RegExp(r'\s+');

  static final RegExp _backClass = RegExp(
    'footnote-?back|backref|reversefootnote',
  );

  static const Set<String> _containerTags = {
    'section',
    'div',
    'aside',
    'ol',
    'ul',
  };

  static const Set<String> _containerRoles = {'doc-endnotes', 'doc-footnotes'};

  static const Set<String> _containerTypes = {'footnotes', 'endnotes'};

  static const Set<String> _noteRoles = {'doc-footnote', 'doc-endnote'};

  static const Set<String> _noteTypes = {'footnote', 'endnote'};

  static const Set<String> _backMarks = {'↩', '↑', '⏎', '⤶', '⮌'};
}
