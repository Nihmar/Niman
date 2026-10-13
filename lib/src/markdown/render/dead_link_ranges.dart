/// Which links of a source line name nothing (#847): the ranges the editor
/// draws in the muted colour.
///
/// A link comes as a run of tokens of one kind — its markers and its text —
/// and is dead as a whole or not at all. The run's text is read as it was
/// written and asked of the note's [DeadLinks]; nothing here resolves a link.
library;

import 'package:flutter/painting.dart' show TextRange;
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/links/dead_links.dart';
import 'package:niman/src/links/parser.dart' show parseWikiRef;

/// The ranges of [styled] (local to the line) holding a link that [dead]
/// says names nothing.
///
/// [hrefOf] gives the target of a reference link (`[text][label]`) whose own
/// source spells none, by where its first token starts; an inline link is
/// read out of its own text.
List<TextRange> deadLinkRanges(
  StyledLine styled,
  DeadLinks dead, {
  String? Function(int tokenStart)? hrefOf,
}) {
  if (dead.isEmpty) return const <TextRange>[];
  final tokens = styled.tokens;
  final text = styled.text;
  List<TextRange>? out;
  for (var at = 0; at < tokens.length; at++) {
    final token = tokens[at];
    if (token.kind != TokenKind.wikilink && token.kind != TokenKind.link) {
      continue;
    }
    // A link comes as its markers and its text, one token each: the link is
    // the run of them.
    var end = at;
    while (end + 1 < tokens.length &&
        tokens[end + 1].kind == token.kind &&
        tokens[end + 1].start == tokens[end].end) {
      end++;
    }
    final raw = text.substring(token.start, tokens[end].end);
    if (_isDead(token.kind, raw, token.start, dead, hrefOf)) {
      (out ??= <TextRange>[]).add(
        TextRange(start: token.start, end: tokens[end].end),
      );
    }
    at = end;
  }
  return out ?? const <TextRange>[];
}

bool _isDead(
  TokenKind kind,
  String raw,
  int start,
  DeadLinks dead,
  String? Function(int tokenStart)? hrefOf,
) {
  if (kind == TokenKind.wikilink) {
    if (!raw.startsWith('[[') || !raw.endsWith(']]') || raw.length < 4) {
      return false;
    }
    return dead.wikiIsDead(parseWikiRef(raw.substring(2, raw.length - 2)));
  }
  final close = raw.indexOf(']');
  if (close < 0) return false;
  // An inline link spells `](href)`; a reference link's target is the
  // parse's, not the text's.
  final String? href;
  if (raw.contains('](') && raw.endsWith(')')) {
    var written = raw.substring(close + 2, raw.length - 1).trim();
    // A title after the destination (`](a.md "the title")` is not part of it,
    // unless the destination is angled and may hold spaces.
    if (!written.startsWith('<')) {
      final space = written.indexOf(RegExp(r'\s'));
      if (space > 0) written = written.substring(0, space);
    }
    href = written;
  } else {
    href = hrefOf?.call(start);
  }
  return href != null && dead.hrefIsDead(href);
}
