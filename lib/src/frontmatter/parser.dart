/// Minimal frontmatter reader (M3 plan, decision 1 — M4's T-M4-01 replaces
/// this with the `yaml` package and adds `frontmatter_fields`).
///
/// Reads only the leading `---`…`---` block and only three keys: `title`
/// (a scalar), `tags` and `aliases` (a YAML flow list `[a, b]` or a
/// comma-separated scalar). Nothing else is parsed, and nothing is written
/// to a fields table — the M3 reader feeds the FTS index (`title`), the
/// tag tables and the `note_stems` alias rows.
library;

import 'package:copist/src/editor/highlighting.dart';

/// The three M3 frontmatter values.
final class Frontmatter {
  /// Creates a frontmatter value.
  const Frontmatter({required this.tags, required this.aliases, this.title});

  /// The `title:` value (trimmed, quotes stripped), or null when absent
  /// or empty. The FTS title falls back to the filename when null.
  final String? title;

  /// The `tags:` values, normalized ([normalizeTag]), deduplicated, in
  /// document order.
  final List<String> tags;

  /// The `aliases:` values (trimmed, deduplicated), in document order.
  final List<String> aliases;
}

/// Parses the leading frontmatter block of [text], or returns null when
/// there is none.
///
/// The block must start at the very first line with `---` (trimmed) and
/// close with a line that is `---` or `...` (trimmed) — the same rule the
/// editor tokenizer applies ([TokenKind.frontmatter]), so the editor, the
/// preview and the indexer agree on what is frontmatter.
///
/// Lines are `key: value`; only `title`, `tags` and `aliases` are read.
/// The first `:` splits the key; the value is trimmed, and `tags` /
/// `aliases` accept either `[a, b]` flow lists or comma-separated values.
Frontmatter? parseFrontmatter(String text) {
  final lines = text.split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') return null;
  String? title;
  final tags = <String>[];
  final aliases = <String>[];
  var closed = false;
  for (final line in lines.skip(1)) {
    final trimmed = line.trim();
    if (trimmed == '---' || trimmed == '...') {
      closed = true;
      break;
    }
    final colon = trimmed.indexOf(':');
    if (colon <= 0) continue;
    final key = trimmed.substring(0, colon).trim().toLowerCase();
    final value = trimmed.substring(colon + 1).trim();
    switch (key) {
      case 'title':
        title ??= _unquote(value);
      case 'tags':
        tags.addAll(_listValues(value).map(normalizeTag));
      case 'aliases':
        aliases.addAll(_listValues(value));
      default:
        break;
    }
  }
  if (!closed) return null;
  return Frontmatter(
    title: (title == null || title.isEmpty) ? null : title,
    tags: _dedupe(tags),
    aliases: _dedupe(aliases),
  );
}

/// The normalized tag form: lowercased, no leading `#`, trimmed.
/// `#Inbox/Work` → `inbox/work`.
String normalizeTag(String raw) {
  var t = raw.trim();
  if (t.startsWith('#')) t = t.substring(1);
  return t.toLowerCase();
}

/// The inline `#tags` of [text] (normalized, deduplicated, in order).
///
/// Scans the shared tokenizer's tag tokens, so tags inside code fences,
/// math blocks, inline code and the frontmatter itself are never tags —
/// exactly what the editor paints as tags.
List<String> inlineTags(String text) {
  return inlineTagsOf(HighlightDocument.fromText(text));
}

/// The inline tags of an already-tokenized [doc].
///
/// Same rules as [inlineTags]; indexer callers that tokenize anyway (links
/// + tags from one pass) pass their document in.
List<String> inlineTagsOf(HighlightDocument doc) {
  final out = <String>[];
  for (final line in doc.lines) {
    for (final token in line.tokens) {
      if (token.kind == TokenKind.tag) {
        out.add(normalizeTag(line.text.substring(token.start, token.end)));
      }
    }
  }
  return _dedupe(out);
}

/// Splits a frontmatter list value: `[a, b]` flow style or plain
/// comma-separated; entries trimmed, empty ones dropped.
List<String> _listValues(String value) {
  var v = value.trim();
  if (v.startsWith('[') && v.endsWith(']')) {
    v = v.substring(1, v.length - 1).trim();
  }
  if (v.isEmpty) return const [];
  return [for (final s in v.split(',')) s.trim()];
}

/// Strips one level of matching surrounding quotes.
String _unquote(String s) {
  if (s.length >= 2 &&
      ((s.startsWith('"') && s.endsWith('"')) ||
          (s.startsWith("'") && s.endsWith("'")))) {
    return s.substring(1, s.length - 1);
  }
  return s;
}

List<String> _dedupe(List<String> values) {
  final seen = <String>{};
  return [
    for (final v in values)
      if (v.isNotEmpty && seen.add(v)) v,
  ];
}
