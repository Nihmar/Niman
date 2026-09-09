/// The frontmatter reader: the leading `---`…`---` block, parsed as YAML
/// (T-M4-01).
///
/// M3 shipped a hand-rolled `key: value` reader that understood four keys
/// and one list syntax. This one parses the block with the `yaml` package,
/// so a note written in any other Markdown editor reads here the way it
/// reads there: block lists, nested maps, quoting, comments and typed
/// scalars all mean what YAML says they mean.
///
/// Every key is kept ([Frontmatter.fields]) — that is what makes arbitrary
/// keys indexable and filterable (T-M4-02/03). The known ones — `title`,
/// `tags`, `date`, `pinned`, `aliases`, plus Copist's own `type` — are
/// also read out into typed getters, because the app acts on them.
///
/// Tolerant by construction: a block whose YAML does not parse yields a
/// [Frontmatter] with no fields and an [Frontmatter.error] message rather
/// than an exception, so one bad note can never take down a scan — and the
/// editor has something to show the person who typed it.
library;

import 'package:copist/src/editor/highlighting.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// One note's parsed frontmatter block.
@immutable
final class Frontmatter {
  /// Creates a frontmatter value.
  const new({
    required this.fields,
    required this.tags,
    required this.aliases,
    this.title,
    this.type,
    this.date,
    this.pinned = false,
    this.error,
  });

  /// The frontmatter of a block that does not parse: no fields, and
  /// [message] to show.
  factory malformed(String message) => Frontmatter(
    fields: const {},
    tags: const [],
    aliases: const [],
    error: message,
  );

  /// Every key in the block, lowercased, mapped to its values as text.
  ///
  /// A scalar has one value; a list has one per item; a nested map is
  /// flattened onto dotted keys (`author.name`). Keys are lowercased so
  /// `Title` and `title` are the same field — YAML is case-sensitive, but
  /// a person typing frontmatter is not.
  final Map<String, List<String>> fields;

  /// The `title:` value, or null when absent or empty. It overrides the
  /// filename as the note's display name and as the FTS title.
  final String? title;

  /// The `tags:` values, normalized ([normalizeTag]) and deduplicated.
  final List<String> tags;

  /// The `aliases:` values (trimmed, deduplicated) — extra names the link
  /// resolver answers to.
  final List<String> aliases;

  /// The `type:` value: the note kind, or null for a plain note.
  final String? type;

  /// The `date:` value when it reads as a date, else null.
  final DateTime? date;

  /// Whether `pinned:` is true.
  final bool pinned;

  /// Why the block did not parse, or null when it did.
  final String? error;

  /// The first value of [key] (lowercased), or null when the key is
  /// absent or empty.
  String? first(String key) {
    final values = fields[key.toLowerCase()];
    return (values == null || values.isEmpty) ? null : values.first;
  }
}

/// Parses the leading frontmatter block of [text], or returns null when
/// there is none.
///
/// The block must start at the very first line with `---` (trimmed) and
/// close with a line that is `---` or `...` (trimmed) — the same rule the
/// editor tokenizer applies ([TokenKind.frontmatter]), so the editor, the
/// preview and the indexer agree on what is frontmatter. An unclosed
/// block is not frontmatter at all: it is a horizontal rule and the text
/// under it.
///
/// A block that is not a YAML mapping (a bare list, a lone scalar) reads
/// as malformed — frontmatter is a set of keys by definition.
Frontmatter? parseFrontmatter(String text) {
  final block = frontmatterBlock(text);
  if (block == null) return null;
  return parseFrontmatterBlock(block.text);
}

/// The leading frontmatter block of [text]: its YAML source and the line
/// range it occupies, or null when there is none.
///
/// `startLine` is the `---` opener and `endLine` the closing `---`/`...`,
/// both zero-based — what an editor needs to point at the block.
/// Scanned rather than split: the editor asks this question after every
/// keystroke, and splitting a novel-length note into lines to look at its
/// first few is a cost per keystroke that grows with the note. The scan
/// reads only as far as the closing fence.
({String text, int startLine, int endLine})? frontmatterBlock(String text) {
  var lineStart = 0;
  var line = 0;
  while (lineStart <= text.length) {
    final newline = text.indexOf('\n', lineStart);
    final lineEnd = newline < 0 ? text.length : newline;
    final trimmed = text.substring(lineStart, lineEnd).trim();
    if (line == 0) {
      // Only a leading `---` opens a block; anything else is body.
      if (trimmed != '---') return null;
    } else if (trimmed == '---' || trimmed == '...') {
      // The block's YAML is everything between the fences.
      return (
        text: text.substring(text.indexOf('\n') + 1, lineStart).trimRight(),
        startLine: 0,
        endLine: line,
      );
    }
    if (newline < 0) break;
    lineStart = newline + 1;
    line++;
  }
  // The block never closed: not frontmatter, just a rule and some text.
  return null;
}

/// Parses the YAML [source] of a frontmatter block (without the `---`
/// fences) into a [Frontmatter].
Frontmatter parseFrontmatterBlock(String source) {
  if (source.trim().isEmpty) {
    return const Frontmatter(fields: {}, tags: [], aliases: []);
  }
  Object? doc;
  try {
    doc = loadYaml(source);
  } on YamlException catch (e) {
    return Frontmatter.malformed(e.message);
  } on Object catch (e) {
    return Frontmatter.malformed('$e');
  }
  if (doc == null) {
    return const Frontmatter(fields: {}, tags: [], aliases: []);
  }
  if (doc is! Map) {
    return Frontmatter.malformed(
      'Frontmatter must be a set of key: value pairs.',
    );
  }

  final fields = <String, List<String>>{};
  _flattenInto(fields, '', doc);
  _splitCommas(fields, 'tags');
  _splitCommas(fields, 'aliases');

  final rawTags = fields['tags'] ?? const <String>[];
  return Frontmatter(
    fields: fields,
    title: _nonEmpty(_firstOf(fields, 'title')),
    tags: _dedupe([for (final tag in rawTags) normalizeTag(tag)]),
    aliases: _dedupe(fields['aliases'] ?? const <String>[]),
    type: _nonEmpty(_firstOf(fields, 'type')),
    date: _asDate(doc['date']),
    pinned: _asBool(doc['pinned']),
  );
}

/// How many leading entries of [lines] the frontmatter block occupies —
/// fences included — or 0 when there is no block.
///
/// The line-list form of [frontmatterBlock], for callers that already
/// hold a file split into lines. Same rule, in one place: a `todo.txt`
/// and a note have to agree on what frontmatter is.
int frontmatterLineCount(List<String> lines) {
  if (lines.isEmpty || lines.first.trim() != '---') return 0;
  for (var i = 1; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (trimmed == '---' || trimmed == '...') return i + 1;
  }
  // Never closed: a horizontal rule and some text, not frontmatter.
  return 0;
}

/// Why the leading frontmatter block of [text] does not parse, or null
/// when it parses (or when there is no block).
///
/// The editor's question, asked after every edit: it only wants to know
/// whether to warn, so it does not build the fields.
String? frontmatterErrorIn(String text) => parseFrontmatter(text)?.error;

/// The `type:` value of the leading frontmatter block, or null when the
/// note has no frontmatter block, no `type` key or an empty value.
///
/// A deliberate shortcut past [parseFrontmatter]: it scans for one key and
/// stops, so deciding whether a note needs a kind GUI costs a few lines of
/// text rather than a YAML parse. Every note open takes this path; only
/// the indexer pays for the full parse. Same block rules as
/// [parseFrontmatter] — the value counts only when the block is closed.
String? frontmatterTypeOf(String text) {
  final block = frontmatterBlock(text);
  if (block == null) return null;
  for (final line in block.text.split('\n')) {
    final trimmed = line.trim();
    final colon = trimmed.indexOf(':');
    if (colon <= 0) continue;
    if (trimmed.substring(0, colon).trim().toLowerCase() != 'type') continue;
    final type = _unquote(trimmed.substring(colon + 1).trim());
    return type.isEmpty ? null : type;
  }
  return null;
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

/// Writes [value] into [out] under [prefix]-scoped keys.
///
/// Maps recurse onto dotted keys, lists contribute one text value each
/// (nested lists flatten — a list of lists is still a set of values for
/// the key), and scalars contribute one. A key with no usable value at
/// all is left out rather than stored empty.
void _flattenInto(Map<String, List<String>> out, String prefix, Object? value) {
  if (value is Map) {
    for (final entry in value.entries) {
      final name = entry.key.toString().trim().toLowerCase();
      if (name.isEmpty) continue;
      _flattenInto(out, prefix.isEmpty ? name : '$prefix.$name', entry.value);
    }
    return;
  }
  if (prefix.isEmpty) return;
  if (value is List) {
    for (final item in value) {
      _flattenInto(out, prefix, item);
    }
    return;
  }
  final text = _scalarText(value);
  if (text.isEmpty) return;
  (out[prefix] ??= <String>[]).add(text);
}

/// Splits a single comma-bearing scalar under [key] into its parts.
///
/// `tags: work, personal` is one YAML string, not a list — but it is what
/// people write, and the M3 reader accepted it. Applied only to the two
/// keys whose values are names (`tags`, `aliases`): a `title` or a
/// `summary` with a comma in it is a sentence, not a list.
void _splitCommas(Map<String, List<String>> fields, String key) {
  final values = fields[key];
  if (values == null || values.length != 1) return;
  if (!values.single.contains(',')) return;
  final parts = [
    for (final part in values.single.split(','))
      if (part.trim().isNotEmpty) part.trim(),
  ];
  if (parts.isEmpty) {
    fields.remove(key);
  } else {
    fields[key] = parts;
  }
}

/// One YAML scalar as the text the index stores.
///
/// Dates are written back in ISO form (a bare `2026-03-01` stays
/// `2026-03-01`, a timestamp keeps its time) so what is stored reads the
/// way it was typed; everything else is its `toString`.
String _scalarText(Object? value) {
  if (value == null) return '';
  if (value is DateTime) return _isoText(value);
  return value.toString().trim();
}

String _isoText(DateTime value) {
  final iso = value.toIso8601String();
  final midnight =
      value.hour == 0 &&
      value.minute == 0 &&
      value.second == 0 &&
      value.millisecond == 0 &&
      value.microsecond == 0;
  return midnight ? iso.substring(0, 10) : iso;
}

/// [raw] as a date: a YAML timestamp as-is, a string through
/// [DateTime.tryParse], anything else null.
DateTime? _asDate(Object? raw) {
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw.trim());
  return null;
}

/// [raw] as a bool: a YAML bool as-is; `true`/`yes`/`on` as text (YAML 1.1
/// spellings the 1.2 parser reads as strings) count too.
bool _asBool(Object? raw) {
  if (raw is bool) return raw;
  if (raw is String) {
    return const {'true', 'yes', 'on'}.contains(raw.trim().toLowerCase());
  }
  return false;
}

String? _firstOf(Map<String, List<String>> fields, String key) {
  final values = fields[key];
  return (values == null || values.isEmpty) ? null : values.first;
}

String? _nonEmpty(String? value) =>
    (value == null || value.isEmpty) ? null : value;

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
