/// Background widget ops for the home-screen widgets (round 2, R2/R4).
///
/// The widget taps fire `home_widget` background intents carrying a
/// `niman://` URI; this callback routes each to its op — todo toggle,
/// note-row flip — which edit the file and re-push the payload. No
/// activity comes to the foreground, and it works with the app closed.
/// No Drift, no UI: the background isolate owns plain file I/O through
/// [TodoStore] and the note file.
///
/// Known limitation: a todo toggle here does not reconcile reminders; a
/// `rem:` tag on the completed task is cancelled on the next app open
/// or resume, like every other external todo.txt edit.
library;

import 'package:home_widget/home_widget.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/todo/widget_todos.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_note_ops.dart';
import 'package:niman/src/widget/widget_payload.dart';
import 'package:niman/src/widget/widget_updater.dart';

/// The background entrypoint: register with
/// `HomeWidget.registerInteractivityCallback` at app start (Android).
///
/// Routes the carrying URI to its op by host; anything else is dropped.
@pragma('vm:entry-point')
Future<void> widgetToggleCallback(Uri? uri) async {
  switch (uri?.host) {
    case 'todo-toggle':
      await toggleWidgetTodo(uri);
    case 'note-row-toggle':
      await toggleWidgetNoteRow(uri);
  }
}

/// Parses a `niman://todo-toggle?id=&library=&line=` URI, or null when
/// it carries nothing toggleable.
({int id, String library, int line})? parseToggleUri(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme != 'niman' || uri.host != 'todo-toggle') return null;
  final params = uri.queryParameters;
  final id = int.tryParse(params['id'] ?? '');
  final line = int.tryParse(params['line'] ?? '');
  final library = params['library'];
  if (id == null ||
      id < 0 ||
      line == null ||
      line < 0 ||
      library == null ||
      library.isEmpty) {
    return null;
  }
  return (id: id, library: library, line: line);
}

/// Completes the toggled line and re-pushes its widget.
///
/// True when the toggle landed; false (quiet) on a stale tap — a line
/// edited since the push, an unknown id, garbage in — the next refresh
/// converges the widget anyway. [storeFactory] and [updater] are
/// injected in tests.
Future<bool> toggleWidgetTodo(
  Uri? uri, {
  TodoStore Function({required String root})? storeFactory,
  WidgetUpdater? updater,
}) async {
  final target = parseToggleUri(uri);
  if (target == null) {
    const AppLogger(name: 'widgets').warning('toggle without a target');
    return false;
  }
  try {
    final store = (storeFactory ?? TodoStore.new)(root: target.library);
    final snapshot = await store.checkAt(target.line, DateTime.now());
    final payload = todoWidgetPayload(
      sortTodosForWidget(snapshot),
      libraryPath: target.library,
    );
    final push = updater ?? WidgetUpdater();
    await push.push(
      provider: WidgetProvider.todo,
      androidWidgetId: target.id,
      payload: payload,
    );
    return true;
  } on Object catch (error) {
    // A line that moved or vanished since the push (RangeError and
    // friends): the widget converges on the next refresh.
    const AppLogger(name: 'widgets').warning('toggle failed ($error)');
    return false;
  }
}

/// Registers the background toggle (call once at app start, Android).
Future<void> registerWidgetToggle() {
  return HomeWidget.registerInteractivityCallback(widgetToggleCallback)
      .then((_) {});
}
