/// Text that must reach a note as the words it is, never as syntax: a
/// book's text (#280), a passage quoted from a PDF or a book (#284).
///
/// Every character Markdown or the app's own extensions would read is
/// escaped — `#tag`, `$math$`, `[[link]]`, `==mark==`, `*`, `|`… — and a
/// line that would open a list keeps its first character escaped.
library;

/// [text] with every character Markdown or the app's extensions would
/// read as syntax escaped.
String escapeMarkdownText(String text) =>
    text.replaceAllMapped(_syntax, (match) => '\\${match.group(0)}');

final RegExp _syntax = RegExp(r'[\\`*_\[\]<>#$|~=^&!]');

/// [text], where a line opening a block would open a list, a quote or a
/// heading: its first character escaped. (A quote and a heading are
/// already, their `>` and `#` escaped by [escapeMarkdownText].)
String escapeMarkdownLineStart(String text) {
  final ordered = _orderedStart.firstMatch(text);
  if (ordered != null) {
    return '${ordered.group(1)}\\${ordered.group(2)}'
        '${text.substring(ordered.end)}';
  }
  if (text.startsWith('-') || text.startsWith('+')) return '\\$text';
  return text;
}

final RegExp _orderedStart = RegExp(r'^(\d{1,9})([.)])');
