/// The inline Markdown of a page's elements: emphasis, code, links,
/// pictures, with every character of its text escaped.
library;

import 'package:html/dom.dart';
import 'package:niman/src/markdown/from_html/html_pictures.dart';
import 'package:niman/src/markdown/text_escape.dart';

/// Writes the inline content of a page as Markdown.
final class HtmlInline {
  /// An inline writer that names pictures with [pictures] and links with
  /// [link].
  const new({required this.pictures, required this.link});

  /// The page's pictures.
  final HtmlPictures pictures;

  /// The target a link's `href` is written under.
  final String Function(String href) link;

  /// The inline Markdown of [nodes].
  String of(List<Node> nodes) {
    final out = StringBuffer();
    for (final node in nodes) {
      _write(node, out);
    }
    return out
        .toString()
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(_hardBreak, '\\\n');
  }

  /// A hard break with the blank space around it: the next line does not
  /// open with the source's newline and indent, collapsed to a space.
  static final RegExp _hardBreak = RegExp(r' ?\\\n ?');

  void _write(Node node, StringBuffer out) {
    if (node is Text) {
      out.write(escapeMarkdownText(_collapse(node.text)));
      return;
    }
    if (node is! Element) return;
    String inner() => of(node.nodes);
    switch (node.localName) {
      case 'em' || 'i' || 'cite' || 'dfn' || 'var':
        _wrapped(out, inner(), '*');
      case 'strong' || 'b':
        _wrapped(out, inner(), '**');
      case 's' || 'del' || 'strike':
        _wrapped(out, inner(), '~~');
      case 'code' || 'kbd' || 'samp' || 'tt':
        final code = _collapse(node.text);
        if (code.trim().isEmpty) return;
        final fence = code.contains('`') ? '``' : '`';
        out.write('$fence${code.contains('`') ? ' $code ' : code}$fence');
      case 'br':
        out.write('\\\n');
      case 'a':
        final text = inner();
        final href = node.attributes['href'];
        if (href == null || href.isEmpty || text.trim().isEmpty) {
          out.write(text);
          return;
        }
        out.write('[$text](<${link(href)}>)');
      case 'img' || 'image' || 'svg':
        final math = HtmlPictures.mathOf(node);
        if (math != null) {
          out.write(math);
          return;
        }
        final picture = pictures.of(node);
        if (picture != null) out.write(picture);
      case 'script' || 'style' || 'head':
        return;
      default:
        out.write(inner());
    }
  }

  /// [text] between [marker]s, the blank space at its ends kept outside:
  /// `* word*` is no emphasis.
  static void _wrapped(StringBuffer out, String text, String marker) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      out.write(text);
      return;
    }
    if (text.startsWith(' ')) out.write(' ');
    out.write('$marker$trimmed$marker');
    if (text.endsWith(' ')) out.write(' ');
  }

  /// Runs of blank space as one space, as a browser shows them.
  static String _collapse(String text) => text.replaceAll(_blank, ' ');

  static final RegExp _blank = RegExp(r'\s+');
}
