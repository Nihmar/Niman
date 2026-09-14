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
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/widget/note_excerpt.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_theme.dart';

/// The Android `AppWidgetProvider` class of the todo widget.
const String todoWidgetAndroidName = 'TodoWidgetProvider';

/// The Android `AppWidgetProvider` class of the note widget.
const String noteWidgetAndroidName = 'NoteWidgetProvider';

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

/// The todo rows as JSON: `{"library": path, "rows": [{text, due,
/// priority, line}], "truncated": bool, "total": int}`.
///
/// [entries] arrive in widget order (the todo widget sort); `library` is
/// the absolute library root the native provider taps back into; `text`
/// is the prose ([taskDisplayText], so `due:`/`rem:` slots and
/// `+`/`@`/`#` markers do not eat widget width), `due` a `YYYY-MM-DD`
/// date or null, `line` the file line (for future tap-to-toggle). Rows
/// drop from the end while the payload exceeds [maxChars], setting
/// `truncated`. [total] is the open-task count before capping, so the
/// header count stays true when the rows are truncated. [theme] wears
/// the app theme (absent in old callers: the widget renders its
/// defaults).
String todoWidgetPayload(
  List<TodoEntry> entries, {
  required String libraryPath,
  int? total,
  WidgetTheme? theme,
  int maxChars = widgetPayloadMaxChars,
}) {
  var rows = <Map<String, Object?>>[for (final entry in entries) _row(entry)];
  var truncated = false;
  var encoded = _encode(
    libraryPath,
    rows,
    truncated,
    total ?? rows.length,
    theme,
  );
  while (rows.isNotEmpty && encoded.length > maxChars) {
    rows = rows.sublist(0, rows.length - 1);
    truncated = true;
    encoded = _encode(
      libraryPath,
      rows,
      truncated,
      total ?? rows.length,
      theme,
    );
  }
  return encoded;
}

/// One payload row for [entry].
Map<String, Object?> _row(TodoEntry entry) {
  final task = entry.task;
  return {
    'text': taskDisplayText(task.description),
    'due': task.due == null ? null : formatTodoDate(task.due!),
    'priority': task.priority,
    'line': entry.lineIndex,
  };
}

/// Encodes [rows] with the [libraryPath], [truncated] and [total] fields.
String _encode(
  String libraryPath,
  List<Map<String, Object?>> rows,
  bool truncated,
  int total,
  WidgetTheme? theme,
) {
  return jsonEncode({
    'library': libraryPath,
    'rows': rows,
    'truncated': truncated,
    'total': total,
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
