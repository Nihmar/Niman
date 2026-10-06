/// Inline nodes written as HTML, the way `cmark-gfm`'s HTML renderer
/// writes them (`html.c`, `houdini_href_e.c`, the tag filter).
library;

import 'dart:convert';

import 'package:niman/src/markdown/inline/inline_node.dart';

/// Writes inline nodes as HTML.
abstract final class InlineHtml {
  /// [nodes] as HTML into [out]; a footnote reference written by
  /// [footnote], or as its text when there is none.
  static void write(
    StringBuffer out,
    List<InlineNode> nodes, {
    String Function(FootnoteRefNode node)? footnote,
  }) {
    for (final node in nodes) {
      switch (node) {
        case TextNode(:final text):
          out.write(escape(text));
        case CodeNode(:final code):
          out
            ..write('<code>')
            ..write(escape(code))
            ..write('</code>');
        case EmphasisNode(:final children):
          _wrap(out, 'em', children, footnote);
        case StrongNode(:final children):
          _wrap(out, 'strong', children, footnote);
        case StrikethroughNode(:final children):
          _wrap(out, 'del', children, footnote);
        case LinkNode(:final destination, :final title, :final children):
          out
            ..write('<a href="')
            ..write(escapeHref(destination))
            ..write('"');
          if (title != null) {
            out
              ..write(' title="')
              ..write(escape(title))
              ..write('"');
          }
          out.write('>');
          write(out, children, footnote: footnote);
          out.write('</a>');
        case ImageNode(:final destination, :final title, :final children):
          out
            ..write('<img src="')
            ..write(escapeHref(destination))
            ..write('" alt="')
            ..write(escape(plain(children)))
            ..write('"');
          if (title != null) {
            out
              ..write(' title="')
              ..write(escape(title))
              ..write('"');
          }
          out.write(' />');
        case HtmlNode(:final html):
          out.write(filterTags(html));
        case SoftBreakNode():
          out.write('\n');
        case HardBreakNode():
          out.write('<br />\n');
        case FootnoteRefNode():
          out.write(
            footnote == null ? escape('[^${node.label}]') : footnote(node),
          );
      }
    }
  }

  static void _wrap(
    StringBuffer out,
    String tag,
    List<InlineNode> children,
    String Function(FootnoteRefNode node)? footnote,
  ) {
    out.write('<$tag>');
    write(out, children, footnote: footnote);
    out.write('</$tag>');
  }

  /// [nodes] as an image's description: their text, a line break a space.
  static String plain(List<InlineNode> nodes) {
    final out = StringBuffer();
    void walk(List<InlineNode> nodes) {
      for (final node in nodes) {
        switch (node) {
          case TextNode(:final text):
            out.write(text);
          case CodeNode(:final code):
            out.write(code);
          case HtmlNode(:final html):
            out.write(html);
          case SoftBreakNode() || HardBreakNode():
            out.write(' ');
          case FootnoteRefNode(:final label):
            out.write('[^$label]');
          case InlineContainer(:final children):
            walk(children);
        }
      }
    }

    walk(nodes);
    return out.toString();
  }

  /// [text] with `&`, `<`, `>` and `"` escaped.
  static String escape(String text) {
    if (!_needsEscape.hasMatch(text)) return text;
    final out = StringBuffer();
    for (final char in text.codeUnits) {
      switch (char) {
        case 0x26:
          out.write('&amp;');
        case 0x3C:
          out.write('&lt;');
        case 0x3E:
          out.write('&gt;');
        case 0x22:
          out.write('&quot;');
        default:
          out.writeCharCode(char);
      }
    }
    return out.toString();
  }

  /// [url] as an `href`: what is safe in one as it is, `&` and `'` as
  /// HTML, anything else percent-encoded as UTF-8 — an existing `%` kept.
  static String escapeHref(String url) {
    final out = StringBuffer();
    for (final byte in utf8.encode(url)) {
      if (_hrefSafe(byte)) {
        out.writeCharCode(byte);
      } else if (byte == 0x26) {
        out.write('&amp;');
      } else if (byte == 0x27) {
        out.write('&#x27;');
      } else {
        out
          ..write('%')
          ..write(byte.toRadixString(16).toUpperCase().padLeft(2, '0'));
      }
    }
    return out.toString();
  }

  static bool _hrefSafe(int byte) =>
      (byte >= 0x30 && byte <= 0x39) ||
      (byte >= 0x41 && byte <= 0x5A) ||
      (byte >= 0x61 && byte <= 0x7A) ||
      r'-_.!~*();/?:@=+$,%#'.codeUnits.contains(byte);

  /// [html] with GFM's tag filter applied: the `<` of a tag that would
  /// change how the page around it parses — `title`, `textarea`, `style`,
  /// `xmp`, `iframe`, `noembed`, `noframes`, `script`, `plaintext` —
  /// written as `&lt;`.
  static String filterTags(String html) =>
      html.replaceAllMapped(_filtered, (match) => '&lt;${match.group(1)}');

  static final RegExp _needsEscape = RegExp('[&<>"]');

  static final RegExp _filtered = RegExp(
    '<(/?(?:title|textarea|style|xmp|iframe|noembed|noframes|script|'
    r'plaintext)(?=[\s/>]))',
    caseSensitive: false,
  );
}
