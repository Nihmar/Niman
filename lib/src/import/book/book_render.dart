/// What the notes of a converted book say (#1138, #1294), whatever the book
/// was: the pieces an EPUB's conversion (`epub_convert_render.dart`) and an
/// HTML book's (`html_book_render.dart`) write alike.
///
/// - **A note's lines**, the blank lines and the chapters' rules at its edges
///   left off ([noteBody]).
/// - **A link into the book** points at the note it lands in, relative to
///   the note it is written in, and at its heading when it lands on one
///   (`02%20Part/01%20Arrival.md#The%20Storm`) ([bookLinkTo]).
/// - **The contents**, as the links `index.md` lists ([bookContents]).
/// - **The frontmatter** a book's notes carry, in one style
///   ([bookFrontmatter]).
///
/// Every destination is percent-encoded segment by segment ([bookHref]), the
/// one rule `percentDecoded` reads back.
library;

import 'package:niman/src/frontmatter/yaml_scalar.dart';
import 'package:niman/src/import/book/book_plan.dart';
import 'package:path/path.dart' as p;

/// [note]'s lines, without the blank lines and the chapters' rules at its
/// edges; empty when it holds no text.
String noteBody(BookPlan plan, BookPlannedNote note) {
  var start = note.start;
  var end = note.end;
  bool edge(String line) => line.trim().isEmpty || line.trim() == '---';
  while (start < end && edge(plan.lines[start])) {
    start++;
  }
  while (end > start && edge(plan.lines[end - 1])) {
    end--;
  }
  return plan.lines.sublist(start, end).join('\n');
}

/// Where line [line] of the book goes, written in [note]: the note that
/// holds it among [written], and — when it lands past that note's first line
/// — the heading [headingAt] names for it (the heading on the line itself
/// when null). Null when no note holds it.
String? bookLinkTo(
  BookPlan plan,
  BookPlannedNote note,
  List<BookPlannedNote> written,
  int line, {
  String? Function(int line)? headingAt,
}) {
  final target = plan.noteAt(line, written);
  if (target == null) return null;
  final heading = line > target.start
      ? (headingAt ?? (line) => markdownHeading(plan.lines[line]))(line)
      : null;
  final anchor = heading == null ? '' : '#${bookEncoded(heading)}';
  if (identical(target, note) || target.path == note.path) {
    return anchor.isEmpty ? bookHref(p.posix.basename(note.path)) : anchor;
  }
  return '${bookHref(target.path, from: noteFolderOf(note.path))}$anchor';
}

/// The text of [line] when it is an ATX heading, or null when it is not.
String? markdownHeading(String line) =>
    _heading.firstMatch(line)?.group(1)?.trim();

/// [path] relative to the folder [from] (both `/`-separated, relative to the
/// same folder), each segment percent-encoded: a link's target.
String bookHref(String path, {String from = ''}) {
  final relative = from.isEmpty ? path : p.posix.relative(path, from: from);
  return relative.split('/').map(bookEncoded).join('/');
}

/// [text] as a part of a link's destination: everything but letters, digits
/// and `-_.!~*'` escaped — the parentheses too, which [Uri.encodeComponent]
/// leaves and which would end a destination written bare, as `index.md`'s
/// are. The one rule of every destination a conversion writes (the notes'
/// own are between `<…>`, and need no more), read back by `percentDecoded`.
String bookEncoded(String text) =>
    Uri.encodeComponent(text).replaceAll('(', '%28').replaceAll(')', '%29');

/// [text] as a link's words: the brackets that would end them escaped.
String bookLinkText(String text) =>
    text.replaceAllMapped(RegExp(r'[\[\]\\]'), (m) => '\\${m.group(0)}');

/// [fields], in order, as the lines of a frontmatter block (without its
/// `---` rules): a text as one scalar, a number as it is, a list as a block
/// list of scalars. A blank text and an empty list are left out.
String bookFrontmatter(Iterable<(String, Object?)> fields) {
  final out = StringBuffer();
  for (final (key, value) in fields) {
    switch (value) {
      case final String text when text.trim().isNotEmpty:
        out.writeln('$key: ${yamlString(text)}');
      case final int number:
        out.writeln('$key: $number');
      case final List<String> items when items.isNotEmpty:
        out.writeln('$key:');
        for (final item in items) {
          out.writeln('  - ${yamlString(item)}');
        }
    }
  }
  return out.toString();
}

/// The contents of [plan] as the links of a list, a line each, indented by
/// depth; the notes of [written] as a flat list when the plan has none.
/// [headingAt] is as for [bookLinkTo].
String bookContents(
  BookPlan plan,
  List<BookPlannedNote> written, {
  String? Function(int line)? headingAt,
}) {
  final out = StringBuffer();
  if (plan.contents.isEmpty) {
    for (final note in written) {
      out.write('- [${bookLinkText(note.title)}](${bookHref(note.path)})\n');
    }
    return out.toString();
  }
  for (final entry in plan.contents) {
    final target = plan.noteAt(entry.line, written);
    if (target == null) continue;
    final heading = entry.line > target.start
        ? (headingAt ?? (line) => markdownHeading(plan.lines[line]))(entry.line)
        : null;
    final anchor = heading == null ? '' : '#${bookEncoded(heading)}';
    final link =
        '[${bookLinkText(entry.title)}](${bookHref(target.path)}$anchor)';
    out.write('${'  ' * entry.depth}- $link\n');
  }
  return out.toString();
}

final RegExp _heading = RegExp(r'^#{1,6}\s+(.+?)\s*#*\s*$');
