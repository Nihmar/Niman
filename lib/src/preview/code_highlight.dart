import 'package:flutter/painting.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:highlight/highlight.dart' show Node, highlight;

/// flutter_highlight-backed code highlighter for the preview.
///
/// [theme] is a flutter_highlight theme map (e.g. `atomOneLightTheme` /
/// `atomOneDarkTheme`); [language] is the fence's info string.
final class PreviewCodeHighlighter implements SyntaxHighlighter {
  /// Creates a highlighter for [language] with [theme].
  const PreviewCodeHighlighter({
    required this.language,
    required this.theme,
  });

  /// The fence's language tag (empty = plain text).
  final String language;

  /// The flutter_highlight theme map for this highlighter.
  final Map<String, TextStyle> theme;

  @override
  TextSpan format(String code) {
    final trimmed = code.replaceAll(RegExp(r'\n$'), '');
    final language = this.language.toLowerCase();
    final nodes =
        language.isEmpty
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
      if (node.value != null) {
        current.add(
          node.className == null
              ? TextSpan(text: node.value)
              : TextSpan(text: node.value, style: theme[node.className!]),
        );
      } else if (node.children != null) {
        final children = <TextSpan>[];
        current.add(
          TextSpan(children: children, style: theme[node.className!]),
        );
        stack.add(current);
        current = children;
        node.children!.forEach(traverse);
        current = stack.removeLast();
      }
    }

    nodes.forEach(traverse);
    return spans;
  }
}
