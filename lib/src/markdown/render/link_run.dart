/// Where each link of a source line is (#971).
///
/// The tokenizer gives a link as one token. The styler gives it as its
/// opening marker, its text and its closing marker, and flattens the markers
/// of two links that touch into one token: in `[[a]][[b]]` the `]]` that ends
/// the first and the `[[` that starts the second are the one token `]][[`. So
/// neither "the tokens that touch" nor "one token" says where a link stops;
/// its own syntax does, and this reads it.
library;

import 'package:niman/src/editor/highlighting.dart';

/// One link of a line: its `kind` and the offsets it covers.
typedef LinkRun = ({TokenKind kind, int start, int end});

/// The links of a line of [text] whose [tokens] are given, in order.
///
/// A link made of markers (the styler's) is read from its opening marker to
/// the marker that closes it: `]]` for a wikilink, `>` for an angled
/// autolink, and for a Markdown link the `]` that ends its text with what
/// follows it, `(href "title")` or `[label]`. A token that is not a marker is
/// a whole link by itself: what the tokenizer gives, and a bare address.
List<LinkRun> linkRuns(List<Token> tokens, String text) {
  final out = <LinkRun>[];
  var at = 0;
  while (at < tokens.length) {
    final token = tokens[at];
    final kind = token.kind;
    if (kind != TokenKind.wikilink && kind != TokenKind.link) {
      at++;
      continue;
    }
    if (!token.marker) {
      out.add((kind: kind, start: token.start, end: token.end));
      at++;
      continue;
    }
    // The tokens that touch, of this kind: the links written without a gap.
    var last = at;
    while (last + 1 < tokens.length &&
        tokens[last + 1].kind == kind &&
        tokens[last + 1].start == tokens[last].end) {
      last++;
    }
    final group = tokens.sublist(at, last + 1);
    final end = group.last.end;
    var start = token.start;
    while (start < end) {
      final run = _runAt(group, text, kind, start, end);
      out.add(run);
      start = run.end;
    }
    at = last + 1;
  }
  return out;
}

/// The link that starts at [start], within the [group] of tokens that ends
/// at [end].
LinkRun _runAt(
  List<Token> group,
  String text,
  TokenKind kind,
  int start,
  int end,
) {
  Token tokenAt(int offset) =>
      group.firstWhere((t) => offset >= t.start && offset < t.end);

  // What is left of the group may begin with a token that is a link of its
  // own: a bare address after a link.
  final first = tokenAt(start);
  if (!first.marker) return (kind: kind, start: start, end: first.end);

  /// The first [char] at or after [from] that is syntax rather than text.
  int closer(int from, String char) {
    for (var i = text.indexOf(char, from); i >= 0 && i < end;) {
      if (tokenAt(i).marker) return i;
      i = text.indexOf(char, i + 1);
    }
    return -1;
  }

  int clamp(int offset) => offset < 0 || offset > end ? end : offset;
  if (kind == TokenKind.wikilink) {
    final close = closer(start + 2, ']');
    return (kind: kind, start: start, end: clamp(close < 0 ? -1 : close + 2));
  }
  if (text.startsWith('<', start)) {
    final close = closer(start + 1, '>');
    return (kind: kind, start: start, end: clamp(close < 0 ? -1 : close + 1));
  }
  final close = closer(start + 1, ']');
  if (close < 0) return (kind: kind, start: start, end: end);
  // A footnote's `]` is all of its closing.
  if (text.startsWith('[^', start)) {
    return (kind: kind, start: start, end: close + 1);
  }
  return (kind: kind, start: start, end: clamp(_afterText(text, close, end)));
}

/// Where the link whose text ends with the `]` at [close] ends, before
/// [limit]: after its `(href "title")`, after its `[label]`, or right after
/// the `]` when it has neither.
int _afterText(String text, int close, int limit) {
  var i = close + 1;
  if (i >= limit) return i;
  switch (text[i]) {
    case '[':
      for (i++; i < limit; i++) {
        if (text[i] == r'\') {
          i++;
        } else if (text[i] == ']') {
          return i + 1;
        }
      }
      return limit;
    case '(':
      var depth = 1;
      String? quote;
      for (i++; i < limit; i++) {
        final c = text[i];
        if (c == r'\') {
          i++;
        } else if (quote != null) {
          if (c == quote) quote = null;
        } else if ((c == '"' || c == "'") && text[i - 1] == ' ') {
          quote = c;
        } else if (c == '<' && text[i - 1] == '(') {
          // An angled destination holds anything, parentheses included.
          final angled = text.indexOf('>', i);
          if (angled < 0 || angled >= limit) return limit;
          i = angled;
        } else if (c == '(') {
          depth++;
        } else if (c == ')' && --depth == 0) {
          return i + 1;
        }
      }
      return limit;
  }
  return i;
}
