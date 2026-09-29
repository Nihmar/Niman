/// Setting and clearing one frontmatter key, in place.
///
/// The app writes frontmatter in exactly two situations: pinning a note
/// (T-M4-04) and creating one from a template (T-M4-07). Both edit a file
/// the user also edits by hand, so the rule here is that nothing else in
/// the block may move. Parsing the YAML and re-emitting it would reflow
/// quoting, key order, comments and indentation — correct YAML, and a
/// diff the person who wrote the file did not ask for.
///
/// So the edits are made on lines: the key's line is replaced, added
/// before the closing fence, or removed with whatever it carried. What
/// the app cannot express this way, it does not try to.
///
/// Which lines an entry covers is the YAML parser's answer whenever the
/// block parses: a quoted key (`"due date":`), a literal block with a blank
/// line inside, a quoted value that goes on at column 0 — the node spans
/// say where each one ends, where a guess from indentation did not (a
/// quoted key was never found and got a duplicate; the rest of a value
/// was left behind and broke the block). Only a block YAML refuses falls
/// back to reading lines.
library;

import 'package:niman/src/frontmatter/yaml_scalar.dart';
import 'package:yaml/yaml.dart';

/// [text] with the top-level frontmatter [key] set to [value].
///
/// A note with no frontmatter block gains one. A block that already
/// declares [key] has that entry replaced — all the lines its value takes
/// go with it, and the key keeps the spelling it was written with.
/// Otherwise the entry is appended just before the closing fence, so the
/// keys that were there keep their order; a new key YAML would misread
/// (`due: date`) is quoted.
///
/// [value] is written as-is: it is a YAML scalar the caller has already
/// shaped (`true`, `2026-03-01`, `"a title"`).
String setFrontmatterKey(String text, String key, String value) {
  final eol = _eolOf(text);
  final block = _blockRange(text);
  if (block == null) {
    // A note that had no block gets one, and keeps its body a blank line
    // below — the shape every note written by hand has.
    final body = text.trimLeft();
    return '---$eol${yamlKey(key)}: $value$eol---$eol$eol$body';
  }
  // Splitting on \n leaves the \r of a CRLF file at the end of each line,
  // so the inserted one needs its own to match its neighbours.
  String entry(String writtenKey) =>
      eol == '\r\n' ? '$writtenKey: $value\r' : '$writtenKey: $value';
  final lines = text.split('\n');
  final found = _entryRange(lines, block, key);
  if (found == null) {
    lines.insert(block.end, entry(yamlKey(key)));
  } else {
    lines.replaceRange(found.start, found.end, [entry(found.writtenKey)]);
  }
  return lines.join('\n');
}

/// [text] with the top-level frontmatter [key] removed, along with its
/// continuation lines.
///
/// A block left with no entries at all is removed too, fences included:
/// an empty `---`/`---` pair at the top of a note is noise, and the file
/// reads as if the key had never been set.
String removeFrontmatterKey(String text, String key) {
  final block = _blockRange(text);
  if (block == null) return text;
  final lines = text.split('\n');
  final found = _entryRange(lines, block, key);
  if (found == null) return text;
  lines.removeRange(found.start, found.end);
  final left = block.end - (found.end - found.start);
  final empty = !lines
      .sublist(block.start + 1, left)
      .any((line) => line.trim().isNotEmpty);
  if (empty) {
    // Drop the fences and the blank line the body was separated by.
    var bodyStart = left + 1;
    if (bodyStart < lines.length && lines[bodyStart].trim().isEmpty) {
      bodyStart++;
    }
    lines.removeRange(block.start, bodyStart);
  }
  return lines.join('\n');
}

/// The line range of the frontmatter block: `start` is the opening `---`
/// and `end` the closing fence, both indices into the split lines. Null
/// when [text] has no block.
({int start, int end})? _blockRange(String text) {
  final lines = text.split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') return null;
  for (var i = 1; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (trimmed == '---' || trimmed == '...') return (start: 0, end: i);
  }
  return null;
}

/// One top-level entry of a block: its half-open line range in the note's
/// split lines, the key as it is written (quotes included), and the key
/// as YAML reads it.
typedef _Entry = ({int start, int end, String writtenKey, String key});

/// The top-level entry for [key] inside [block], every line of its value
/// included, or null when the key is absent.
///
/// The key as YAML reads it is compared, so `"due date":` is the entry for
/// `due date`; an exact match wins, then one that differs only in case.
/// Top-level only: a key nested under another one is that key's business,
/// and replacing it would move a value the caller never named.
_Entry? _entryRange(
  List<String> lines,
  ({int start, int end}) block,
  String key,
) {
  final entries = _entriesByYaml(lines, block) ?? _entriesByLines(lines, block);
  final wanted = key.trim();
  for (final entry in entries) {
    if (entry.key == wanted) return entry;
  }
  final folded = wanted.toLowerCase();
  for (final entry in entries) {
    if (entry.key.toLowerCase() == folded) return entry;
  }
  return null;
}

/// The block's top-level entries as the YAML parser places them, or null
/// when the block does not parse (or is not a mapping), which is the line
/// reading's case.
List<_Entry>? _entriesByYaml(List<String> lines, ({int start, int end}) block) {
  final first = block.start + 1;
  final YamlNode doc;
  try {
    doc = loadYamlNode(lines.sublist(first, block.end).join('\n'));
  } on FormatException {
    return null;
  }
  if (doc is! YamlMap) return doc.value == null ? const [] : null;
  return [
    for (final MapEntry(key: keyNode, value: valueNode) in doc.nodes.entries)
      if (keyNode is YamlNode)
        (
          start: first + keyNode.span.start.line,
          end:
              first +
              _endLine(
                keyNode.span.start.line,
                valueNode.span.end.line,
                valueNode.span.end.column,
              ),
          writtenKey: keyNode.span.text,
          key: '${keyNode.value}'.trim(),
        ),
  ];
}

/// The line after a value that ends at [endLine]:[endColumn], for an entry
/// that starts on [startLine]: a span that stops at the start of a line (a
/// block list takes its last line break) ends before that line.
int _endLine(int startLine, int endLine, int endColumn) =>
    endColumn == 0 && endLine > startLine ? endLine : endLine + 1;

/// The block's top-level entries read line by line — for a block the YAML
/// parser refuses, which is still edited rather than left stuck: a key
/// starts a line at column 0, and every indented line (or `- ` item)
/// under it belongs to it.
List<_Entry> _entriesByLines(List<String> lines, ({int start, int end}) block) {
  final entries = <_Entry>[];
  for (var i = block.start + 1; i < block.end; i++) {
    final line = lines[i];
    if (line.startsWith(' ') || line.startsWith('\t')) continue;
    final written = _writtenKeyOf(line);
    if (written == null) continue;
    var end = i + 1;
    while (end < block.end) {
      final next = lines[end];
      final isContinuation =
          next.startsWith(' ') ||
          next.startsWith('\t') ||
          next.trimLeft().startsWith('- ');
      if (!isContinuation) break;
      end++;
    }
    entries.add((
      start: i,
      end: end,
      writtenKey: written,
      key: _keyValueOf(written),
    ));
  }
  return entries;
}

/// The key a mapping line starts with, as written — a quoted key through
/// its closing quote, a plain one up to the `:` that ends it — or null
/// when the line is no `key:` line (a comment, a stray scalar).
String? _writtenKeyOf(String line) {
  final quote = line.isEmpty ? '' : line[0];
  var end = 0;
  if (quote == '"' || quote == "'") {
    end = 1;
    while (end < line.length) {
      final char = line[end];
      if (quote == '"' && char == r'\') {
        end += 2;
        continue;
      }
      if (char == quote) {
        // A doubled single quote is one quote inside the key.
        if (quote == "'" && end + 1 < line.length && line[end + 1] == "'") {
          end += 2;
          continue;
        }
        break;
      }
      end++;
    }
    if (end >= line.length) return null;
    final colon = line.indexOf(':', end + 1);
    if (colon < 0 || line.substring(end + 1, colon).trim().isNotEmpty) {
      return null;
    }
    return line.substring(0, end + 1);
  }
  final colon = RegExp(r':(?=\s|$)').firstMatch(line)?.start;
  if (colon == null || colon == 0 || line.startsWith('#')) return null;
  return line.substring(0, colon).trimRight();
}

/// [written], a key as written, as YAML reads it: a quoted key unquoted.
String _keyValueOf(String written) {
  if (!written.startsWith('"') && !written.startsWith("'")) return written;
  try {
    final value = loadYaml(written);
    if (value is String) return value.trim();
  } on FormatException {
    // Kept as written: it can still match itself.
  }
  return written;
}

/// The line ending [text] is written with: CRLF when it uses any, else
/// LF. A note edited on Windows should not gain a lone LF line.
String _eolOf(String text) => text.contains('\r\n') ? '\r\n' : '\n';
