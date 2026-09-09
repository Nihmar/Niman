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
library;

/// [text] with the top-level frontmatter [key] set to [value].
///
/// A note with no frontmatter block gains one. A block that already
/// declares [key] has that entry replaced — its continuation lines (an
/// indented block list, a folded scalar) go with it. Otherwise the entry
/// is appended just before the closing fence, so the keys that were there
/// keep their order.
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
    return '---$eol$key: $value$eol---$eol$eol$body';
  }
  // Splitting on \n leaves the \r of a CRLF file at the end of each line,
  // so the inserted one needs its own to match its neighbours.
  final entry = eol == '\r\n' ? '$key: $value\r' : '$key: $value';
  final lines = text.split('\n');
  final found = _entryRange(lines, block, key);
  if (found == null) {
    lines.insert(block.end, entry);
  } else {
    lines.replaceRange(found.start, found.end, [entry]);
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

/// The half-open line range of the top-level entry for [key] inside
/// [block], continuation lines included, or null when the key is absent.
///
/// Top-level only: a key nested under another one is that key's business,
/// and replacing it would move a value the caller never named.
({int start, int end})? _entryRange(
  List<String> lines,
  ({int start, int end}) block,
  String key,
) {
  final wanted = key.trim().toLowerCase();
  for (var i = block.start + 1; i < block.end; i++) {
    final line = lines[i];
    if (line.startsWith(' ') || line.startsWith('\t')) continue;
    final colon = line.indexOf(':');
    if (colon <= 0) continue;
    if (line.substring(0, colon).trim().toLowerCase() != wanted) continue;
    // Everything indented (or a `- ` item) under it belongs to this entry.
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
    return (start: i, end: end);
  }
  return null;
}

/// The line ending [text] is written with: CRLF when it uses any, else
/// LF. A note edited on Windows should not gain a lone LF line.
String _eolOf(String text) => text.contains('\r\n') ? '\r\n' : '\n';
