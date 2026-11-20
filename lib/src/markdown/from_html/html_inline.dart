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
  String of(List<Node> nodes) => _run(nodes, paragraphs: false);

  /// The paragraphs of [nodes]: one, trimmed, or — with [splitAtBreaks] —
  /// the pieces between its `<br>`s, each its own paragraph. A piece with
  /// nothing in it is none, so two breaks in a row make no empty one.
  List<String> paragraphsOf(
    List<Node> nodes, {
    required bool splitAtBreaks,
  }) => [
    for (final piece in _run(nodes, paragraphs: splitAtBreaks).split(_split))
      if (piece.trim().isNotEmpty) piece.trim(),
  ];

  String _run(List<Node> nodes, {required bool paragraphs}) {
    final out = StringBuffer();
    for (final node in nodes) {
      _write(node, out, paragraphs);
    }
    return out
        .toString()
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(_hardBreak, '\\\n');
  }

  /// A hard break with the blank space around it: the next line does not
  /// open with the source's newline and indent, collapsed to a space.
  static final RegExp _hardBreak = RegExp(r' ?\\\n ?');

  /// What a `<br>` writes where the lines are paragraphs: a control
  /// character a page's text cannot carry, cut at when the run is done.
  static const String _split = '\u0001';

  void _write(Node node, StringBuffer out, bool paragraphs) {
    if (node is Text) {
      out.write(
        escapeMarkdownText(_collapse(node.text.replaceAll(_split, ''))),
      );
      return;
    }
    if (node is! Element) return;
    String inner() => _run(node.nodes, paragraphs: paragraphs);
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
        out.write(paragraphs ? _split : '\\\n');
      case 'a':
        final text = inner();
        final href = node.attributes['href'];
        if (href == null || href.isEmpty || text.trim().isEmpty) {
          out.write(text);
          return;
        }
        final target = link(href);
        // A break that cuts the link in paragraphs makes a link of each.
        out.write(
          text
              .split(_split)
              .map(
                (piece) => piece.trim().isEmpty ? piece : '[$piece](<$target>)',
              )
              .join(_split),
        );
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
  /// `* word*` is no emphasis. A break that cuts the text in paragraphs
  /// cuts the emphasis with it, each piece wrapped.
  static void _wrapped(StringBuffer out, String text, String marker) {
    final pieces = text.split(_split);
    for (var i = 0; i < pieces.length; i++) {
      if (i > 0) out.write(_split);
      _wrapPiece(out, pieces[i], marker);
    }
  }

  static void _wrapPiece(StringBuffer out, String text, String marker) {
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
