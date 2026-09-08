/// User text → safe FTS5 / tag queries (design.md: search/query.dart).
///
/// User input is **never** a raw FTS expression: every token is quoted
/// (internal quotes doubled), so quotes, hyphens, parentheses, wildcards
/// and FTS operators in the input are literals, not syntax. Only the last
/// token gets the `*` prefix-match suffix (the type-as-you-grow case).
library;

import 'package:copist/src/frontmatter/parser.dart';

/// Builds an FTS5 MATCH expression from [userText], or null when there is
/// no query (empty or whitespace-only input).
///
/// Rules (T-M3-04): split on whitespace; quote each token, doubling
/// internal quotes; append `*` to the last (non-empty) token only. Tokens
/// that are only quote characters are dropped — a plain `"` is not a
/// searchable term and would produce a malformed phrase.
String? buildFtsQuery(String userText) {
  final tokens = userText
      .trim()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return null;
  final out = <String>[];
  for (var i = 0; i < tokens.length; i++) {
    final quoted = tokens[i].replaceAll('"', '""');
    // Quote-only tokens cannot name a term — drop them rather than emit a
    // malformed phrase.
    final hasTerm = quoted.contains(RegExp('[^"]'));
    if (!hasTerm) continue;
    out.add(i == tokens.length - 1 ? '"$quoted"*' : '"$quoted"');
  }
  if (out.isEmpty) return null;
  return out.join(' ');
}

/// The normalized tag when [userText] is exactly one `#tag` token — the
/// tag-search mode — or null (word search). `#work` → `work`;
/// `#work extra` → null (mixed input stays a word search).
String? tagQuery(String userText) {
  final t = userText.trim();
  if (t.isEmpty || !t.startsWith('#')) return null;
  final tokens = t.split(RegExp(r'\s+')).where((x) => x.isNotEmpty);
  if (tokens.length != 1) return null;
  final tag = normalizeTag(tokens.single);
  return tag.isEmpty ? null : tag;
}
