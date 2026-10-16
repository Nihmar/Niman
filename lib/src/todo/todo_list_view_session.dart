import 'dart:async';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/todo/todo_list_view.dart';

const AppLogger _log = AppLogger(name: 'todo');

/// The [TodoListView] of the library [session] (#1003): the folded sections
/// are the device's, kept in the library's settings, so the view reports
/// every change to the session and takes the stored set once the session
/// has read it.
///
/// The view starts with the default (Done folded) and is drawn at once; the
/// stored set follows off the build path and replaces it only if the user
/// has not folded or opened a section in the meantime.
TodoListView todoListViewFor(LibrarySession session) {
  final view = TodoListView(
    onCollapsedChanged: (ids) {
      unawaited(
        session.setTodoCollapsedSections(ids).onError<Object>((error, _) {
          _log.warning('todo folded sections not saved: $error');
        }),
      );
    },
  );
  unawaited(
    session.todoCollapsedSections.then(view.restoreCollapsed).onError<Object>((
      error,
      _,
    ) {
      _log.warning('todo folded sections not read: $error');
    }),
  );
  return view;
}
