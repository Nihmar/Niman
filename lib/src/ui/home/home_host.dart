/// What the Home (#535) asks of the shell around it: the open library, the
/// task list and the journal it reads, and the ways out of it.
///
/// One explicit list, like `ShellLayoutProps`: a Home that could reach
/// into the shell would go on reaching.
library;

import 'package:flutter/foundation.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/ui/journal/journal_flow.dart';

/// The shell's side of the Home.
@immutable
final class HomeHost {
  /// Creates the host.
  const new({
    required this.controller,
    required this.todo,
    required this.journal,
    required this.openNote,
    required this.openSearch,
    required this.openTag,
    required this.openTodo,
    required this.runAction,
  });

  /// The open library.
  final LibrarySession controller;

  /// The todo list, as the Todo tab holds it.
  final TodoController todo;

  /// Opens and makes journal entries.
  final JournalFlow journal;

  /// Opens a note by library-relative path.
  final void Function(String path) openNote;

  /// Shows Search with a query typed in.
  final void Function(String query) openSearch;

  /// Shows the notes of a tag.
  final void Function(String tag) openTag;

  /// Shows the todo list.
  final void Function() openTodo;

  /// Runs a Home action.
  final void Function(HomeAction action) runAction;
}
