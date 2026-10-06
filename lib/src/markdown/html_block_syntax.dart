/// The HTML blocks a line of Markdown opens and closes (CommonMark's seven
/// kinds, read off the line's text).
library;

import 'package:niman/src/markdown/inline/inline_scanners.dart';
import 'package:niman/src/markdown/line_state.dart';

/// Where an HTML block starts and where it ends.
abstract final class HtmlBlockSyntax {
  /// The HTML block a line opens — its kind, and for a raw-text tag the tag
  /// that closes it — or null.
  static (HtmlBlockKind, String?)? open(String text) {
    final trimmed = text.trimLeft();
    if (!trimmed.startsWith('<')) return null;
    final lower = trimmed.toLowerCase();
    for (final tag in _rawTextTags) {
      if (lower.startsWith('<$tag') &&
          (lower.length == tag.length + 1 ||
              _isSpaceOrEnd(lower.codeUnitAt(tag.length + 1)) ||
              lower.codeUnitAt(tag.length + 1) == 0x3E)) {
        return (HtmlBlockKind.rawText, tag);
      }
    }
    if (trimmed.startsWith('<!--')) return (HtmlBlockKind.comment, null);
    if (trimmed.startsWith('<?')) {
      return (HtmlBlockKind.processingInstruction, null);
    }
    if (trimmed.startsWith('<![CDATA[')) return (HtmlBlockKind.cdata, null);
    if (trimmed.length > 2 &&
        trimmed.startsWith('<!') &&
        _isAsciiLetter(trimmed.codeUnitAt(2))) {
      return (HtmlBlockKind.declaration, null);
    }
    final name = _tagName(trimmed);
    if (name != null && _blockTags.contains(name) && _endsName(trimmed)) {
      return (HtmlBlockKind.blockTag, null);
    }
    if (name != null && _isCompleteTag(trimmed, name)) {
      return (HtmlBlockKind.completeTag, null);
    }
    return null;
  }

  /// Whether the tag name at the start of [trimmed] is followed by what a
  /// kind-6 tag allows: white space, the line's end, `>` or `/>` — not
  /// `<div:…`.
  static bool _endsName(String trimmed) {
    var at = 1;
    if (at < trimmed.length && trimmed.codeUnitAt(at) == 0x2F) at++;
    while (at < trimmed.length &&
        (_isAsciiLetter(trimmed.codeUnitAt(at)) ||
            _isDigit(trimmed.codeUnitAt(at)))) {
      at++;
    }
    if (at >= trimmed.length) return true;
    final char = trimmed.codeUnitAt(at);
    return _isSpaceOrEnd(char) ||
        char == 0x3E ||
        (char == 0x2F &&
            at + 1 < trimmed.length &&
            trimmed.codeUnitAt(at + 1) == 0x3E);
  }

  /// Whether the HTML block [state] opens on [text] also ends there: its end
  /// marker after the opening one, for the kinds that end on a marker.
  static bool closesOnItsOwnLine(String text, LineState state) {
    final trimmed = text.trimLeft();
    final (from, marker) = switch (state.html!) {
      HtmlBlockKind.rawText => (1, '</${state.htmlClosing}>'),
      HtmlBlockKind.comment => (4, '-->'),
      HtmlBlockKind.processingInstruction => (2, '?>'),
      HtmlBlockKind.declaration => (2, '>'),
      HtmlBlockKind.cdata => (9, ']]>'),
      HtmlBlockKind.blockTag || HtmlBlockKind.completeTag => (0, ''),
    };
    if (marker.isEmpty) return false;
    final rest = from > trimmed.length ? '' : trimmed.substring(from);
    return state.html == HtmlBlockKind.rawText
        ? rest.toLowerCase().contains(marker)
        : rest.contains(marker);
  }

  /// Whether [text] closes the HTML block [state] opened.
  static bool closes(String text, LineState state) {
    switch (state.html!) {
      case HtmlBlockKind.rawText:
        return text.toLowerCase().contains('</${state.htmlClosing}>');
      case HtmlBlockKind.comment:
        return text.contains('-->');
      case HtmlBlockKind.processingInstruction:
        return text.contains('?>');
      case HtmlBlockKind.declaration:
        return text.contains('>');
      case HtmlBlockKind.cdata:
        return text.contains(']]>');
      case HtmlBlockKind.blockTag:
      case HtmlBlockKind.completeTag:
        return text.trim().isEmpty;
    }
  }

  /// The tag name a line starts with, lowercased, or null.
  static String? _tagName(String trimmed) {
    var at = 1;
    if (at < trimmed.length && trimmed.codeUnitAt(at) == 0x2F) at++;
    final start = at;
    while (at < trimmed.length) {
      final char = trimmed.codeUnitAt(at);
      if (!_isAsciiLetter(char) && !_isDigit(char)) break;
      at++;
    }
    if (at == start) return null;
    return trimmed.substring(start, at).toLowerCase();
  }

  /// Whether the line is one complete open or closing tag, [name] not a
  /// raw-text one, and nothing after it but white space: a tag as the
  /// spec writes one (`InlineScanners.tag`, the inline parser's own rule)
  /// — `<http://a.b>`, an autolink, is none, nor `<a h*#ref="hi">`.
  static bool _isCompleteTag(String trimmed, String name) {
    if (_rawTextTags.contains(name)) return false;
    final end = InlineScanners.tag(trimmed, 0);
    return end != null && trimmed.substring(end).trim().isEmpty;
  }

  static bool _isSpaceOrEnd(int char) =>
      char == 0x20 || char == 0x09 || char == 0x0A;

  static bool _isDigit(int char) => char >= 0x30 && char <= 0x39;

  static bool _isAsciiLetter(int char) =>
      (char >= 0x41 && char <= 0x5A) || (char >= 0x61 && char <= 0x7A);

  /// The tags whose content runs to their own closing tag.
  static const Set<String> _rawTextTags = <String>{
    'pre',
    'script',
    'style',
    'textarea',
  };

  /// The block-level tags of HTML block type 6, from the CommonMark spec.
  static const Set<String> _blockTags = <String>{
    'address',
    'article',
    'aside',
    'base',
    'basefont',
    'blockquote',
    'body',
    'caption',
    'center',
    'col',
    'colgroup',
    'dd',
    'details',
    'dialog',
    'dir',
    'div',
    'dl',
    'dt',
    'fieldset',
    'figcaption',
    'figure',
    'footer',
    'form',
    'frame',
    'frameset',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'head',
    'header',
    'hr',
    'html',
    'iframe',
    'legend',
    'li',
    'link',
    'main',
    'menu',
    'menuitem',
    'nav',
    'noframes',
    'ol',
    'optgroup',
    'option',
    'p',
    'param',
    'search',
    'section',
    'summary',
    'table',
    'tbody',
    'td',
    'tfoot',
    'th',
    'thead',
    'title',
    'tr',
    'track',
    'ul',
  };
}
