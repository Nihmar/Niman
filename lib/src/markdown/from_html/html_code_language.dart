/// The language a page tags a code block with.
library;

import 'package:html/dom.dart';

/// Reads the language of a `<pre>`.
abstract final class HtmlCodeLanguage {
  /// The language [pre] names, for its fence's info string, or an empty
  /// string when it names none.
  ///
  /// The `language-x` or `lang-x` class — HTML5's, Markdown renderers',
  /// highlight.js', and Niman's own export's (`hljs language-x`) — on the
  /// `<code>` inside it or on the `<pre>`; Pandoc's `sourceCode x`; a
  /// `data-lang` attribute.
  static String of(Element pre) {
    for (final element in [pre.querySelector('code'), pre]) {
      if (element == null) continue;
      final language = _of(element);
      if (language.isNotEmpty) return language;
    }
    return '';
  }

  static String _of(Element element) {
    final classes = element.classes.toList();
    for (final name in classes) {
      final match = _prefixed.firstMatch(name);
      if (match != null && _fit(match[1]!)) return match[1]!;
    }
    if (classes.contains('sourceCode')) {
      for (final name in classes) {
        if (!_pandoc.contains(name) && _fit(name)) return name;
      }
    }
    for (final name in const ['data-lang', 'data-language']) {
      final written = (element.attributes[name] ?? '').trim();
      if (_fit(written)) return written;
    }
    return '';
  }

  /// Whether [name] can be an info string: one word, none of the names a
  /// highlighter gives to text with no language.
  static bool _fit(String name) =>
      _word.hasMatch(name) && !_none.contains(name.toLowerCase());

  static final RegExp _prefixed = RegExp(r'^(?:language|lang)-(.+)$');

  static final RegExp _word = RegExp(r'^[\w+#.-]+$');

  static const Set<String> _none = {'none', 'nohighlight', 'plaintext', 'text'};

  static const Set<String> _pandoc = {
    'sourceCode',
    'numberSource',
    'numberLines',
    'lineAnchors',
  };
}
