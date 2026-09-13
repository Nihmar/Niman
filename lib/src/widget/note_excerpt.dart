/// Note excerpts for the home-screen note widget (issue 6).
///
/// RemoteViews cannot render Markdown, so a pinned note is flattened to
/// text: prose for normal notes, `☐`/`☑` rows for `type: list` notes.
/// Pure Dart, no I/O: callers read the note off the UI isolate and pass
/// the content in.
library;

import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/ui/kinds/list_parser.dart';
import 'package:path/path.dart' as p;

/// Max excerpt chars for a normal note.
const int widgetExcerptMaxChars = 2000;

/// Max checklist rows for a list note.
const int widgetChecklistMaxItems = 20;

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

/// The checklist text of a list note: one `☐`/`☑` row per item in
/// document order, depth-indented, capped to [maxItems].
({String text, bool truncated}) checklistExcerpt(
  String content, {
  int maxItems = widgetChecklistMaxItems,
}) {
  final items = parseListItems(content);
  final kept = items.length <= maxItems ? items : items.sublist(0, maxItems);
  final rows = [
    for (final item in kept)
      '${'  ' * item.depth}${item.checked ? '☑' : '☐'} ${item.text}'
          .trimRight(),
  ];
  return (text: rows.join('\n'), truncated: items.length > kept.length);
}
