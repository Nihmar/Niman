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
import 'package:niman/src/markdown/render/link_run.dart';

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
  final text = styled.text;
  List<TextRange>? out;
  // A link comes as its markers and its text, one token each: the link is
  // the run of them, up to the marker that closes it (#971).
  for (final (:kind, :start, :end) in linkRuns(styled.tokens, text)) {
    if (_isDead(kind, text.substring(start, end), start, dead, hrefOf)) {
      (out ??= <TextRange>[]).add(TextRange(start: start, end: end));
    }
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
  // An inline link spells `](href)`; a reference link's target is the
  // parse's, not the text's.
  final href = inlineHrefOf(raw) ?? hrefOf?.call(start);
  return href != null && dead.hrefIsDead(href);
}

/// The destination a Markdown link spells between its parentheses — `[t](a.md
/// "the title")` is `a.md` — or null for a link that spells none (a
/// reference link, `[t][label]`).
///
/// A title after the destination is not part of it, unless the destination is
/// angled (`<a b.md>`) and may hold spaces.
String? inlineHrefOf(String raw) {
  if (!raw.endsWith(')')) return null;
  // The `]` that closes the text is the one that balances the opening `[`:
  // an image or a bracket inside the text (`[![a](i.png)](b.md)`) holds
  // `](` of its own, and `\]` is a letter, not a bracket.
  var depth = 0;
  var close = -1;
  for (var i = 0; i < raw.length - 1 && close < 0; i++) {
    switch (raw[i]) {
      case r'\':
        i++;
      case '[':
        depth++;
      case ']':
        if (--depth == 0 && raw[i + 1] == '(') close = i;
    }
  }
  if (close < 0) return null;
  var written = raw.substring(close + 2, raw.length - 1).trim();
  if (!written.startsWith('<')) {
    final space = written.indexOf(RegExp(r'\s'));
    if (space > 0) written = written.substring(0, space);
  }
  return written;
}
