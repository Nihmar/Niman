/// Launcher payloads for the home-screen widgets (issue 6).
///
/// The native provider cannot parse todo.txt: Dart serializes the rows it
/// already sorted for the widget to JSON under one `SharedPreferences`
/// key per widget instance, and the provider renders that snapshot. Keys
/// carry the Android widget id, so two instances for two libraries never
/// share a payload.
///
/// Pure Dart, no I/O.
library;

import 'dart:convert';

import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_sections.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/todo/widget_todos.dart';
import 'package:niman/src/widget/note_excerpt.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_theme.dart';

/// The Android `AppWidgetProvider` class of the todo widget.
const String todoWidgetAndroidName = 'TodoWidgetProvider';

/// The Android `AppWidgetProvider` class of the note widget.
const String noteWidgetAndroidName = 'NoteWidgetProvider';

/// The Android `AppWidgetProvider` class of the Study widget (#533).
const String studyWidgetAndroidName = 'StudyWidgetProvider';

/// The application id both providers live under.
const String widgetApplicationId = 'dev.niman.niman';

/// Max JSON chars pushed for one widget instance.
///
/// `SharedPreferences` crosses binder transactions; twenty one-line tasks
/// never approach this, so hitting it means something pathological (a
/// pasted novel on one todo line) and the tail is expendable.
const int widgetPayloadMaxChars = 200000;

/// The provider class name of [provider] (unqualified).
String widgetProviderAndroidName(WidgetProvider provider) {
  return switch (provider) {
    WidgetProvider.todo => todoWidgetAndroidName,
    WidgetProvider.note => noteWidgetAndroidName,
    WidgetProvider.study => studyWidgetAndroidName,
  };
}

/// The fully qualified provider class name of [provider].
String widgetProviderQualifiedName(WidgetProvider provider) {
  return '$widgetApplicationId.${widgetProviderAndroidName(provider)}';
}

/// The `SharedPreferences` key of [androidWidgetId]'s payload.
String widgetPayloadKey(WidgetProvider provider, int androidWidgetId) {
  return '${provider.name}_$androidWidgetId';
}

/// The `kind` of a section header item in the todo payload's `rows`.
///
/// A row item carries no `kind`: a payload from before the sections
/// (#1003) is all rows and renders as one flat list.
const String todoWidgetSectionKind = 'section';

/// The header `tone` that draws the section in the error color (Overdue).
const String todoWidgetErrorTone = 'error';

/// The todo list as JSON: `{"library": path, "rows": [item, ...],
/// "truncated": bool, "total": int, "language": id, "theme": {...}}`.
///
/// `rows` is one flat list in display order (the widget list is a
/// `RemoteViews` collection, one item per position): each non-empty
/// section contributes a header item `{kind: "section", section: id,
/// label, count, tone?}` followed by its rows. `count` is the section's
/// true count, `tone` is `error` for the overdue header. A row is
/// `{text, due, priority, projects, contexts, tags, line, section,
/// showDue}`:
///
/// - `text` is the prose ([taskDisplayText], so `due:`/`rem:` slots and
///   `+`/`@`/`#` markers do not eat widget width);
/// - `due` a `YYYY-MM-DD` date or null, and `showDue` whether the meta
///   line repeats it (false under Today, which already says it);
/// - `projects`/`contexts`/`tags` the `+project`/`@context`/`#tag`
///   markers for the meta line;
/// - `line` the file line the tap toggles;
/// - `section` the id of the section the row sits under.
///
/// [sections] arrive in display order (see `widgetTodoSections`);
/// `library` is the absolute library root the native provider taps back
/// into. Items drop from the end while the payload exceeds [maxChars],
/// setting `truncated` (a header left with no row goes with them).
/// [total] is the open-task count before capping, so the header count
/// stays true when the rows are truncated. [theme] wears the app theme
/// and [language] is the app language id the labels were written in (the
/// background toggle re-pushes in it; absent in old callers: the widget
/// renders its defaults).
String todoWidgetPayload(
  List<WidgetTodoSection> sections, {
  required String libraryPath,
  int? total,
  WidgetTheme? theme,
  String? language,
  int maxChars = widgetPayloadMaxChars,
}) {
  var items = <Map<String, Object?>>[
    for (final section in sections) ..._items(section),
  ];
  var truncated = false;
  String encode() => _encode(
    libraryPath,
    items,
    truncated,
    total ?? items.where(_isRow).length,
    theme,
    language,
  );
  var encoded = encode();
  while (items.isNotEmpty && encoded.length > maxChars) {
    items = items.sublist(0, items.length - 1);
    // A header whose rows were all dropped would head nothing.
    while (items.isNotEmpty && !_isRow(items.last)) {
      items = items.sublist(0, items.length - 1);
    }
    truncated = true;
    encoded = encode();
  }
  return encoded;
}

/// Whether [item] is a task row (not a section header).
bool _isRow(Map<String, Object?> item) {
  return item['kind'] != todoWidgetSectionKind;
}

/// The header item of [section] followed by its rows.
List<Map<String, Object?>> _items(WidgetTodoSection section) {
  return [
    {
      'kind': todoWidgetSectionKind,
      'section': section.id,
      'label': section.label,
      'count': section.count,
      if (section.id == todoDueOverdueSectionId) 'tone': todoWidgetErrorTone,
    },
    for (final entry in section.entries) _row(entry, section.id),
  ];
}

/// One payload row for [entry] under the section [sectionId].
Map<String, Object?> _row(TodoEntry entry, String sectionId) {
  final task = entry.task;
  return {
    'text': taskDisplayText(task.description),
    'due': task.due == null ? null : formatTodoDate(task.due!),
    'priority': task.priority,
    'projects': task.projects,
    'contexts': task.contexts,
    'tags': task.hashtags,
    'line': entry.lineIndex,
    'section': sectionId,
    // The Today section already says "today": its rows drop the date.
    'showDue': sectionId != todoDueTodaySectionId,
  };
}

/// Encodes [items] with the [libraryPath], [truncated] and [total] fields.
String _encode(
  String libraryPath,
  List<Map<String, Object?>> items,
  bool truncated,
  int total,
  WidgetTheme? theme,
  String? language,
) {
  return jsonEncode({
    'library': libraryPath,
    'rows': items,
    'truncated': truncated,
    'total': total,
    'language': ?language,
    if (theme != null) 'theme': widgetThemeToMap(theme),
  });
}

/// A pinned note as JSON: `{"library", "note", "title", "kind", "rows",
/// "body", "truncated", "total"}`.
///
/// `library` is the absolute root and `note` the library-relative path
/// the native provider taps back into; `kind` is `note` (prose excerpt
/// in `body`), `list` (checklist items in `rows`) or `missing` (the note
/// is gone; `body` empty). `total` is the item count before capping
/// (the row count when absent), so a capped list stays honest. [theme]
/// wears the app theme (absent in old callers: the widget renders its
/// defaults).
String noteWidgetPayload({
  required String libraryPath,
  required String notePath,
  required String title,
  required String kind,
  required bool truncated,
  String body = '',
  List<ChecklistRow> rows = const [],
  int? total,
  WidgetTheme? theme,
}) {
  return jsonEncode({
    'library': libraryPath,
    'note': notePath,
    'title': title,
    'kind': kind,
    'rows': [for (final row in rows) row.toMap()],
    'body': body,
    'truncated': truncated,
    'total': total ?? rows.length,
    if (theme != null) 'theme': widgetThemeToMap(theme),
  });
}
