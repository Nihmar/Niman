/// Note excerpts for the home-screen note widget (issue 6).
///
/// RemoteViews cannot render Markdown, so a pinned note is flattened:
/// prose text for normal notes, structured rows for `type: list` notes
/// (the widget renders one row view per item).
/// Pure Dart, no I/O: callers read the note off the UI isolate and pass
/// the content in.
library;

import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/ui/kinds/list_parser.dart';
import 'package:path/path.dart' as p;

/// Max excerpt chars for a normal note.
const int widgetExcerptMaxChars = 2000;

/// Max checklist rows for a list note.
///
/// The widget rows are a scrollable `RemoteCollection`, so the cap is a
/// payload-size guard (the note file may be novel-length), not a
/// visibility one.
const int widgetChecklistMaxItems = 100;

/// One checklist row of a list note payload: the item's prose, box state
/// and position (the line is the file line the background ops flip).
final class ChecklistRow {
  /// Creates a row.
  const new({
    required this.text,
    required this.checked,
    required this.line,
    required this.depth,
  });

  /// The item text after the task box.
  final String text;

  /// Whether the box is checked.
  final bool checked;

  /// The item's line in the note text (the flip target).
  final int line;

  /// The nesting level (0 = top), for row indentation.
  final int depth;

  /// The JSON shape the payload carries.
  Map<String, Object?> toMap() {
    return {'text': text, 'checked': checked, 'line': line, 'depth': depth};
  }
}

/// The widget title for [notePath] (`Todo.md` → `Todo`).
String noteWidgetTitle(String notePath) {
  final base = p.basenameWithoutExtension(notePath);
  return base.isEmpty ? notePath : base;
}

/// Whether [content] is a list note (`type: list` frontmatter).
bool isListNoteContent(String content) {
  return frontmatterTypeOf(content) == 'list';
}

/// The body lines of [content] without its frontmatter block.
List<String> noteBodyLines(String content) {
  final lines = content.split('\n');
  return lines.sublist(frontmatterLineCount(lines));
}

/// The plain-text excerpt of a normal note, trimmed and capped to
/// [maxChars], with a flag telling the widget to hint at more.
({String text, bool truncated}) noteExcerpt(
  String content, {
  int maxChars = widgetExcerptMaxChars,
}) {
  final body = noteBodyLines(content).join('\n').trim();
  if (body.length <= maxChars) return (text: body, truncated: false);
  return (text: '${body.substring(0, maxChars).trimRight()}…', truncated: true);
}

/// The checklist rows of a list note: one [ChecklistRow] per item in
/// document order, capped to [maxItems], with the true item count
/// (`total`) so the widget can stay honest when the rows are capped.
({List<ChecklistRow> rows, bool truncated, int total}) checklistRows(
  String content, {
  int maxItems = widgetChecklistMaxItems,
}) {
  final items = parseListItems(content);
  final kept = items.length <= maxItems ? items : items.sublist(0, maxItems);
  return (
    rows: [
      for (final item in kept)
        ChecklistRow(
          text: item.text,
          checked: item.checked,
          line: item.line,
          depth: item.depth,
        ),
    ],
    truncated: items.length > kept.length,
    total: items.length,
  );
}
