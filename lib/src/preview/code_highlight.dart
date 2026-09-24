import 'package:flutter/painting.dart';
import 'package:highlight/highlight.dart' show Node, highlight;

/// A run of a code line's text and how it is coloured, its offsets the
/// line's own.
typedef CodeRun = ({int start, int end, TextStyle style});

/// flutter_highlight-backed code highlighter, one fence at a time.
///
/// [theme] is a flutter_highlight theme map (the read view's theme carries
/// `atomOneLightTheme` / `atomOneDarkTheme` by brightness); [language] is the
/// fence's info string.
///
final class CodeHighlighter {
  /// Creates a highlighter for [language] with [theme].
  const new({required this.language, required this.theme});

  /// The fence's language tag (empty = plain text).
  final String language;

  /// The flutter_highlight theme map for this highlighter.
  final Map<String, TextStyle> theme;

  /// [code] as one span of coloured runs.
  TextSpan format(String code) {
    final trimmed = code.replaceAll(RegExp(r'\n$'), '');
    final language = this.language.toLowerCase();
    final nodes = language.isEmpty
        ? <Node>[]
        : highlight.parse(trimmed, language: language).nodes ?? <Node>[];
    final root = theme['root'];
    return TextSpan(
      // The root's colour and not its background: the code block's box is
      // the background, and the theme's painted a band of its own behind
      // every row of text, which `live`'s rows do not have.
      style: TextStyle(fontFamily: 'monospace', color: root?.color),
      children: nodes.isEmpty
          ? <TextSpan>[TextSpan(text: code)]
          : _convert(nodes),
    );
  }

  /// [code]'s colours line by line: for each of its lines, the runs that
  /// cover it, their offsets the line's own, each styled as [format] styles
  /// it — the root's colour where the grammar says nothing.
  ///
  /// What `live` colours a code block's rows with: the block is highlighted
  /// whole, as the read view highlights it, so a string or a comment that
  /// runs over several lines is coloured on all of them.
  List<List<CodeRun>> lines(String code) {
    final out = <List<CodeRun>>[<CodeRun>[]];
    final root = TextStyle(color: theme['root']?.color);
    var column = 0;
    void add(String text, TextStyle style) {
      var from = 0;
      while (true) {
        final at = text.indexOf('\n', from);
        final end = at < 0 ? text.length : at;
        if (end > from) {
          out.last.add((start: column, end: column + end - from, style: style));
          column += end - from;
        }
        if (at < 0) return;
        out.add(<CodeRun>[]);
        column = 0;
        from = at + 1;
      }
    }

    void walk(InlineSpan span, TextStyle style) {
      if (span is! TextSpan) return;
      final own = span.style == null ? style : style.merge(span.style);
      final text = span.text;
      if (text != null) add(text, own);
      for (final child in span.children ?? const <InlineSpan>[]) {
        walk(child, own);
      }
    }

    final formatted = format(code);
    for (final child in formatted.children ?? const <InlineSpan>[]) {
      walk(child, root);
    }
    return out;
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
