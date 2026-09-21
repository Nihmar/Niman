import 'package:flutter/painting.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:highlight/highlight.dart' show Node, highlight;

/// flutter_highlight-backed code highlighter, one fence at a time.
///
/// [theme] is a flutter_highlight theme map (the read view's theme carries
/// `atomOneLightTheme` / `atomOneDarkTheme` by brightness); [language] is the
/// fence's info string.
///
/// The read view is where this is used in production: the preview's
/// `syntaxHighlighter` hook was never wired (only a test passed one), so a code
/// block in the old preview was a single monospace colour.
final class CodeHighlighter implements SyntaxHighlighter {
  /// Creates a highlighter for [language] with [theme].
  const new({required this.language, required this.theme});

  /// The fence's language tag (empty = plain text).
  final String language;

  /// The flutter_highlight theme map for this highlighter.
  final Map<String, TextStyle> theme;

  @override
  TextSpan format(String code) {
    final trimmed = code.replaceAll(RegExp(r'\n$'), '');
    final language = this.language.toLowerCase();
    final nodes = language.isEmpty
        ? <Node>[]
        : highlight.parse(trimmed, language: language).nodes ?? <Node>[];
    final root = theme['root'];
    return TextSpan(
      style: TextStyle(
        fontFamily: 'monospace',
        color: root?.color,
        backgroundColor: root?.backgroundColor,
      ),
      children: nodes.isEmpty
          ? <TextSpan>[TextSpan(text: code)]
          : _convert(nodes),
    );
  }

  /// The highlight tree to styled inline spans (same walk as
  /// flutter_highlight's `HighlightView`, without the widget wrapper).
  List<TextSpan> _convert(List<Node> nodes) {
    final spans = <TextSpan>[];
    var current = spans;
    final stack = <List<TextSpan>>[];
    void traverse(Node node) {
      // Children first, and that order is the whole bug this used to have: the
      // grammar wraps tokens in nodes that carry **both** an empty `value` and
      // the children that hold the class names (`value="" class=null` around
      // `value=null class=keyword`), so testing `value != null` first dropped
      // every token under a wrapper — and a code block came out one colour. It
      // went unnoticed because the highlighter was never wired into the preview
      // (only a test passed one, and it asserts nothing about colour) and
      // because the read view did not use it at all until it did.
      final children = node.children;
      if (children != null) {
        final nested = <TextSpan>[];
        current.add(TextSpan(children: nested, style: theme[node.className]));
        stack.add(current);
        current = nested;
        children.forEach(traverse);
        current = stack.removeLast();
        return;
      }
      final value = node.value;
      if (value == null) return;
      current.add(TextSpan(text: value, style: theme[node.className]));
    }

    nodes.forEach(traverse);
    return spans;
  }
}
