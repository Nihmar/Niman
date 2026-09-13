/// Keeps the todo widgets showing the open library's todos (issue 6).
///
/// The shell calls [refreshTodoWidgets] whenever the todo snapshot moves;
/// the native providers only render the last payload pushed, so a library
/// with no todo widgets configured costs one cheap registry read and no
/// launcher traffic.
library;

import 'package:niman/src/library/session.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/todo/widget_todos.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_payload.dart';
import 'package:niman/src/widget/widget_updater.dart';

/// Pushes [snapshot]'s open todos to every todo widget configured for the
/// session's library.
///
/// No-ops without an open library, without todo widgets, or before the
/// first snapshot loads (that load notifies too, so it pushes through
/// the same path).
Future<void> refreshTodoWidgets({
  required LibrarySession session,
  required TodoSnapshot? snapshot,
  WidgetUpdater? updater,
}) async {
  final root = session.root;
  if (root == null || snapshot == null) return;
  final ids = <int>[
    for (final config in await session.widgetConfigsFor(root))
      if (config.provider == WidgetProvider.todo.name) config.androidWidgetId,
  ];
  if (ids.isEmpty) return;
  final payload = todoWidgetPayload(
    sortTodosForWidget(snapshot),
    libraryPath: root,
  );
  final push = updater ?? WidgetUpdater();
  for (final id in ids) {
    await push.push(
      provider: WidgetProvider.todo,
      androidWidgetId: id,
      payload: payload,
    );
  }
}
