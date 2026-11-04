import 'package:flutter/material.dart';

/// A search hit's snippet or excerpt, two lines at most: `<mark>…</mark>`
/// spans get the accent color + bold, everything else is plain body text.
final class SearchSnippet extends StatelessWidget {
  /// Creates the rendering of [snippet].
  const new(this.snippet, {super.key});

  /// The `snippet()`/excerpt string, with its matches in `<mark>` tags.
  final String snippet;

  @override
  Widget build(BuildContext context) => Text.rich(
    _highlight(Theme.of(context), snippet),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );
}

/// Renders a `snippet()`/excerpt string: `<mark>…</mark>` spans get the
/// accent color + bold, everything else is plain body text.
TextSpan _highlight(ThemeData theme, String snippet) {
  final style = theme.textTheme.bodyMedium ?? const TextStyle();
  final markStyle = style.copyWith(
    color: theme.colorScheme.primary,
    fontWeight: FontWeight.bold,
  );
  final spans = <TextSpan>[];
  var pos = 0;
  const open = '<mark>';
  const close = '</mark>';
  while (pos < snippet.length) {
    final start = snippet.indexOf(open, pos);
    if (start < 0) {
      spans.add(TextSpan(text: snippet.substring(pos), style: style));
      break;
    }
    if (start > pos) {
      spans.add(TextSpan(text: snippet.substring(pos, start), style: style));
    }
    final end = snippet.indexOf(close, start + open.length);
    if (end < 0) {
      spans.add(
        TextSpan(
          text: snippet.substring(start + open.length),
          style: markStyle,
        ),
      );
      break;
    }
    spans.add(
      TextSpan(
        text: snippet.substring(start + open.length, end),
        style: markStyle,
      ),
    );
    pos = end + close.length;
  }
  return TextSpan(children: spans);
}
