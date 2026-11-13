import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/calendar/calendar_controller.dart';
import 'package:niman/src/calendar/calendar_source.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/export/printed_todo_block.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/links/library_links.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/search/task_events.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/todo/task_links.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_list_view.dart';
import 'package:niman/src/todo/todo_list_view_session.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/device_shape.dart';
import 'package:niman/src/ui/export_todo_blocks.dart';
import 'package:niman/src/ui/note_link_targets.dart';
import 'package:niman/src/ui/note_tasks_host.dart';
import 'package:niman/src/ui/search_task_events.dart';
import 'package:niman/src/ui/shell_editor_settings.dart';
import 'package:niman/src/ui/shell_note_io.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/ui/todo_edit_dialog.dart';
import 'package:niman/src/ui/todo_link_host.dart';
import 'package:path/path.dart' as p;

/// The library's tasks and calendar as the shell holds them (#1256): the
/// two controllers, the links of the tasks, what the Todo list shows and
/// what a note's task list reads — made together, opened together and
/// disposed together, so the Todo tab, the Home, the journal, Search and
/// the notes share one of each.
final class ShellTasks {
  /// The tasks and the calendar of [session].
  new({
    required this.session,
    required ReminderService reminders,
    required TodoSource Function(String root) todoSourceFactory,
    required CalendarSource Function(String root) calendarSourceFactory,
    required this.linkSource,
    required this.suggester,
    required this.editor,
    required this.openNote,
    required this.workspace,
    required this.guard,
    required this.context,
  }) : _reminders = reminders,
       todo = TodoController(
         session: session,
         reminders: reminders,
         sourceFactory: todoSourceFactory,
       ),
       calendar = CalendarController(
         session: session,
         sourceFactory: calendarSourceFactory,
       ),
       view = todoListViewFor(session) {
    // The calendar's own reminders ride with the tasks' (#730): the file
    // is pushed to the task controller, whose wanted set covers both.
    calendar.addListener(_pushCalendarReminders);
    links = TaskLinkMap(
      tasks: todo,
      snapshot: () => todo.snapshot,
      links: () => session.linkSource,
      enabled: () =>
          session.root != null &&
          session.features.value.isOn(LibraryFeature.todo),
      enabledChanges: session.features,
    );
  }

  /// The open library.
  final LibrarySession session;

  final ReminderService _reminders;

  /// The link-resolution source, once the session has resolved it.
  final LibraryLinks? Function() linkSource;

  /// The library the link suggester reads, once resolved.
  final WikilinkSuggester? Function() suggester;

  /// The editor's settings: whether a link's preview shows on hover
  /// (#846), where a note made from a task's dead link lands (#78).
  final ShellEditorSettings Function() editor;

  /// Opens a note by library-relative path, at a heading when there is one.
  final void Function(String path, String? anchor) openNote;

  /// The panes and their tabs, which a note a task's link names opens in
  /// (#1268).
  final ShellWorkspace workspace;

  /// The shell's reentrancy guard around a write.
  final Future<void> Function(Future<void> Function() action) guard;

  /// Where the task dialog opens.
  final BuildContext Function() context;

  /// The todo state (T-TD-04): the tab body and the tab's app-bar add
  /// action share it.
  final TodoController todo;

  /// The calendar file (#730): the journal's events, the Home tile and the
  /// editor's colours all read it.
  final CalendarController calendar;

  /// What the Todo list shows (#1003): its filter, its sort and the folded
  /// sections, which the phone's app bar and the tab body both set.
  final TodoListView view;

  /// The links of the tasks, resolved (#1152): the Todo tab, a note's task
  /// list and the rename rewrite share one map. Inert while the Todo
  /// feature is off.
  late final TaskLinkMap links;

  /// How the Todo tab follows a link in a task (#1152): the map, and the
  /// targets of a tap on a chip.
  late final TodoLinkHost todoLinks = TodoLinkHost(
    map: links,
    targets: linkTargets,
    source: linkSource,
    previewEnabled: () => editor().linkPreview,
    suggester: suggester,
  );

  /// What a note's task list (#1152) reads and does: the map, a tick, the
  /// task dialog, Add task. Shared by the three places the list lives in.
  late final NoteTasksHost notes = NoteTasksHost(
    links: todoLinks,
    controller: todo,
    reminders: _reminders,
    addTask: (text) => add(text: text),
  );

  /// The tasks and events in memory, as Search's lone-token group reads
  /// them (#730): the two controllers' own snapshots, walked in memory and
  /// never indexed. The group re-reads them on every change to either.
  late final TaskEvents events = TaskEvents(
    hits: (token) => taskEventHits(
      token,
      tasks: todo.snapshot?.todo ?? const <TodoEntry>[],
      calendar: calendar.snapshot?.entries ?? const <CalendarEntry>[],
    ),
    changes: Listenable.merge([todo, calendar]),
  );

  /// Loads both files. Here, not in the Todo tab: T-TD-07 reconciles
  /// reminders at every library open, and the Todo tab is only reachable in
  /// the narrow layout — a >= 600 px device would otherwise never
  /// reconcile. The tab's own open then takes the probe-skip path instead
  /// of a second full read.
  void open() {
    unawaited(todo.open());
    unawaited(calendar.open());
  }

  /// Hands the calendar file to the task controller, whose reminder set
  /// covers both files (#730).
  void _pushCalendarReminders() => todo.calendar = calendar.snapshot;

  /// What following a link written in a task asks (#1152): `todo.txt` sits
  /// at the library root, a link in it is resolved from there, and it opens
  /// a note, or offers to create one, as a link in a note does. [anchor] is
  /// where the pointer went down, when a pointer did; [behind] opens the
  /// note in a tab behind the one showing (see [_openFromTask]).
  NoteLinkTargets linkTargets(Rect? anchor, {bool behind = false}) {
    final root = session.root ?? '';
    return NoteLinkTargets(
      source: linkSource(),
      notePath: p.join(root, todoFileName),
      libraryRoot: session.root,
      newItemLocation: editor().newItemLocation,
      // A task has no headings of its own: an anchor lands in the note the
      // link opens.
      outline: const [],
      jumpToHeading: (_) {},
      onOpenNote: (path, at) => _openFromTask(path, at, behind: behind),
      createMissingNote: missingNoteCreatorFor(session),
      anchor: anchor,
    );
  }

  /// Opens the note a task's link names (#1268). On a wide window it opens
  /// in a tab of its own, not in place of the note on show: the list is
  /// not that note, and a link followed from it took the tab away. With
  /// [behind] (Ctrl, Cmd or a middle click on the chip) the tab opens
  /// behind the one showing and the list stays on screen; the note lands
  /// on [anchor] when its tab first shows. A note already open shows in
  /// its tab. A phone has one note on screen, and shows it.
  void _openFromTask(String path, String? anchor, {required bool behind}) {
    if (!isWideShell(context())) return openNote(path, anchor);
    if (behind) return workspace.openBehind(path, anchor: anchor);
    workspace.show(path, newTab: true);
    openNote(path, anchor);
  }

  /// Adds a task from the Todo tab's add FAB (T-TD-04), or from a Home
  /// action with [text] written in.
  Future<void> add({String text = '', DateTime? due}) async {
    const AppLogger(name: 'todo').debug('todo add pressed');
    final snapshot = todo.snapshot;
    final where = context();
    final line = await showTodoTaskDialog(
      where,
      today: DateTime.now(),
      text: text,
      due: due,
      knownTokens: snapshot == null
          ? const <String>{}
          : snapshotTokens(snapshot),
      linkSuggester: todoLinks.suggester,
      health: _reminders.health.value,
      onOpenReminderSettings: _reminders.openHealthSettings,
    );
    if (line == null || !where.mounted) return;
    await guard(() => todo.add(line));
  }

  /// The lists the `todo` fences of a note are at this moment, for an export
  /// to print in their place (#1152); none while the Todo feature is off,
  /// where the fence is the code it is.
  Future<PrintedTodoBlocks> exportBlocks(String path, String text) =>
      session.features.value.isOn(LibraryFeature.todo)
      ? ExportTodoBlocks(notes).of(text: text, notePath: path)
      : Future<PrintedTodoBlocks>.value(const <String, PrintedTodoBlock>{});

  /// The `+`/`@`/`#` tokens the two files already use (#730): the Add
  /// event form suggests from them, both files at once, since `grep
  /// +thesis` reads the two together.
  Set<String> get knownTokens => {
    if (todo.snapshot case final todos?) ...snapshotTokens(todos),
    if (calendar.snapshot case final file?) ...calendarSnapshotTokens(file),
  };

  /// The caret offset of [line] in `calendar.txt`, once it is read.
  int? calendarOffsetOf(int line) => calendar.snapshot?.offsetOfLine(line);

  /// Lets go of both controllers and what reads them.
  void dispose() {
    calendar.removeListener(_pushCalendarReminders);
    todoLinks.dispose();
    links.dispose();
    todo.dispose();
    view.dispose();
    calendar.dispose();
  }
}
