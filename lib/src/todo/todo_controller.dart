/// Session-bound todo state: migration-on-open + revision-driven refresh
/// (T-TD-03).
///
/// The shell owns one controller and opens it when it mounts, not when
/// the Todo tab does: reminders must reconcile at every library open, and
/// the wide layout has no Todo tab at all. Opening subscribes to the
/// session's revision stream, loads both files and archives stray
/// completed lines (the store migration, so an external tool writing `x`
/// lines back into `todo.txt` self-heals on the next open).
/// Later revision events schedule a debounced reload that first probes
/// both files' `(size, mtime)` and skips the content read when neither
/// moved — a session event fires for every index change (any note edit
/// anywhere), and the todo files rarely move. The tab's own ops apply
/// through the controller and publish the returned snapshot directly, so
/// they never wait for the revision round trip.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/todo/reminder_cancellation.dart';
import 'package:niman/src/todo/reminder_feature_follower.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/todo/task_line_edit.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/todo/todo_store.dart';

/// Owns the Todo tab's data: the current [snapshot] over the open
/// library's `todo.txt` / `done.txt`, refreshed on session events.
final class TodoController extends ChangeNotifier {
  /// Creates a controller over [session].
  ///
  /// [clock] stamps check operations (defaults to [DateTime.now];
  /// tests inject a fixed time). [refreshDebounce] delays revision-
  /// driven reloads so a burst of index events causes one reload.
  /// [sourceFactory] builds the file source per library root (defaults
  /// to the real store; widget tests inject an in-memory fake).
  /// [reminders] syncs OS notifications after every publish (null on
  /// desktop and in tests that do not cover reminders).
  new({
    required this.session,
    DateTime Function()? clock,
    this.refreshDebounce = const Duration(milliseconds: 300),
    TodoSource Function(String root)? sourceFactory,
    this.reminders,
  }) : _clock = clock ?? DateTime.now,
       _sourceFactory = sourceFactory ?? _defaultSource;

  /// The library session: root path and revision events.
  final LibrarySession session;

  /// The OS reminder service, or null while disabled.
  final ReminderService? reminders;

  final DateTime Function() _clock;
  final TodoSource Function(String root) _sourceFactory;

  /// Cancels and restores the alarms as the library's Todo and Calendar
  /// switches flip (#1109), whoever flipped them.
  late final ReminderFeatureFollower _follower = ReminderFeatureFollower(
    features: session.features,
    scheduledFor: _scheduledFor,
    resync: _syncReminders,
    isOpen: () => session.root != null,
  );

  static const AppLogger _log = AppLogger(name: 'todo');

  /// How long revision-driven reloads wait for the event burst to settle.
  final Duration refreshDebounce;

  TodoSource? _store;
  TodoSnapshot? _snapshot;
  CalendarSnapshot? _calendar;

  /// Whether reminder text keeps the +project/@context/#tag markers.
  ///
  /// Cached from the session so reconciliation stays synchronous with the
  /// snapshot; refreshed on every load and resume, which is every point a
  /// settings change can reach.
  bool _reminderShowTokens = false;
  ({TodoFileProbe todo, TodoFileProbe done})? _probes;
  String? _error;
  StreamSubscription<int>? _events;
  Timer? _refreshTimer;
  int _generation = 0;
  bool _disposed = false;

  /// The current parsed contents, or null while no library is open.
  TodoSnapshot? get snapshot => _snapshot;

  /// The last load/op failure message, or null.
  String? get error => _error;

  /// Subscribes to session events, loads both files and archives stray
  /// completed lines. Safe to call again (re-subscribes nothing,
  /// reloads).
  Future<void> open() async {
    _log.info('todo open: root=${session.root}');
    _events ??= session.events.listen((_) => _scheduleRefresh());
    _follower.start();
    await _refreshReminderSettings();
    await _reload();
  }

  /// Re-reads the reminder display setting (cheap, one settings row).
  Future<void> _refreshReminderSettings() async {
    try {
      final showTokens = await session.reminderShowTokens;
      if (!_disposed) {
        _reminderShowTokens = showTokens;
      }
    } on Object catch (error) {
      // A settings read must never stop a reload: the previous value (or
      // the default) still produces a usable reminder.
      _log.warning('todo reminder settings unavailable: $error');
    }
  }

  /// What the latest flip of the Todo or Calendar switch cancelled, once
  /// its alarms are reconciled (#1109).
  ///
  /// The Features screen awaits it right after it flips a switch, for the
  /// snackbar's count. The flip itself started the work -- this controller
  /// listens to the library's features, so a switch a sync brought follows
  /// the same path -- and reading this starts nothing.
  Future<ReminderCancellation> get featureReconcile => _follower.settled;

  /// Appends [line] to `todo.txt`.
  Future<void> add(String line) {
    return _apply('add', (store) => store.add(line));
  }

  /// Checks an open task on the controller's clock.
  Future<void> check(TodoEntry entry) {
    return _apply(
      'check@${entry.lineIndex}',
      (store) => store.checkAt(entry.lineIndex, _clock()),
    );
  }

  /// Reopens a completed task back into `todo.txt`.
  Future<void> uncheck(TodoEntry entry) {
    return _apply(
      'uncheck@${entry.lineIndex}',
      (store) => store.uncheckAt(entry.lineIndex),
    );
  }

  /// Replaces an open task's line (edit).
  Future<void> updateTodo(TodoEntry entry, String line) {
    return _apply(
      'edit-todo@${entry.lineIndex}',
      (store) => store.updateTodoAt(entry.lineIndex, line),
    );
  }

  /// Replaces a completed task's line (edit from the done view).
  Future<void> updateDone(TodoEntry entry, String line) {
    return _apply(
      'edit-done@${entry.lineIndex}',
      (store) => store.updateDoneAt(entry.lineIndex, line),
    );
  }

  /// Removes an open task's line outright.
  Future<void> deleteTodo(TodoEntry entry) {
    return _apply(
      'delete-todo@${entry.lineIndex}',
      (store) => store.deleteTodoAt(entry.lineIndex),
    );
  }

  /// Removes a completed task's line outright.
  Future<void> deleteDone(TodoEntry entry) {
    return _apply(
      'delete-done@${entry.lineIndex}',
      (store) => store.deleteDoneAt(entry.lineIndex),
    );
  }

  /// Replaces the task lines [edits] name, one write for each file (the
  /// rename rewrite of the links in the tasks, #1152). A failure is logged
  /// and shown on [error], never thrown: the move that asked is done.
  Future<void> replaceLines(List<TaskLineEdit> edits) {
    return _apply('replace-lines', (store) => store.replaceLines(edits));
  }

  /// Appends the tasks Move to tasks (#1152) takes out of a note: the [todo]
  /// lines to `todo.txt` and the [done] ones to `done.txt`, `todo.txt`
  /// first. True when both files took them: the note's lines may go only
  /// then, for a failure shown on [error] has left them where they were.
  Future<bool> addMoved({
    required List<String> todo,
    required List<String> done,
  }) {
    return _apply(
      'add-moved',
      (store) => store.addLines(todo: todo, done: done),
    );
  }

  /// Takes back what [addMoved] appended (Undo of a move): the last line
  /// equal to each of [todo] and [done]. True when the files took it.
  Future<bool> removeMoved({
    required List<String> todo,
    required List<String> done,
  }) {
    return _apply(
      'remove-moved',
      (store) => store.removeLines(todo: todo, done: done),
    );
  }

  /// The calendar file, whose own reminders (#730) join the tasks' in the
  /// wanted set. The shell keeps it current — one listener on the calendar
  /// controller. Setting it reconciles, the way a publish does.
  CalendarSnapshot? get calendar => _calendar;
  set calendar(CalendarSnapshot? snapshot) {
    _calendar = snapshot;
    unawaited(_syncReminders());
  }

  /// Runs [op] on the current store and publishes the returned snapshot
  /// (no-op while no library is open; failures surface on [error]).
  /// [label] names the op in the debug log. True when the op was done: false
  /// with no library open, or when it failed.
  Future<bool> _apply(
    String label,
    Future<TodoSnapshot> Function(TodoSource store) op,
  ) async {
    final store = _store;
    if (store == null || _disposed) {
      _log.debug('todo $label dropped (no store)');
      return false;
    }
    var done = true;
    try {
      _snapshot = await op(store);
      _probes = await store.probe();
      _error = null;
      _log.debug(
        'todo $label ok: '
        '${_snapshot!.todo.length} open, ${_snapshot!.done.length} done',
      );
    } on Object catch (error) {
      _error = '$error';
      _log.warning('todo $label failed: $error');
      done = false;
    }
    if (!_disposed) {
      notifyListeners();
      unawaited(_syncReminders());
    }
    return done;
  }

  /// Converges OS reminders with what is on disk: the shell calls this on
  /// app resume, so a grant made in system settings (notifications, exact
  /// alarms) takes effect when the user returns instead of waiting for the
  /// next file change.
  ///
  /// Nothing loaded yet (the shell's own [open] still in flight) loads
  /// instead, which reconciles when it publishes. Otherwise both files are
  /// re-probed -- two stats off the UI isolate, content read skipped when
  /// neither moved -- and reminders reconcile even when nothing changed,
  /// because the grant might have.
  Future<void> resyncReminders() async {
    if (_disposed) {
      return;
    }
    if (_snapshot == null) {
      await open();
      return;
    }
    await _refreshReminderSettings();
    await _reload();
    await _syncReminders();
  }

  /// Reconciles OS reminders with the current snapshot (fire-and-forget:
  /// scheduling never blocks the op, and a denied permission or a dead
  /// plugin only logs).
  ///
  /// A null snapshot means "nothing loaded", never "nothing wanted":
  /// scheduling is a full replace, so handing the service an empty set
  /// cancels every pending alarm. Reminders outlive a library close and
  /// converge again on the next open.
  Future<void> _syncReminders() async {
    final service = reminders;
    final snapshot = _snapshot;
    if (service == null || snapshot == null || _disposed) {
      return;
    }
    try {
      // One wanted set over both files: an event's `rem:HH:MM` and a
      // task's stamp are the same reminder to the OS, with ids salted
      // apart and payloads that say which file a tap opens (#730).
      // A feature that is off wants none: the file keeps its `rem:`s and
      // the alarms come back with the switch (#1109).
      final features = session.features.value;
      await service.reconcile({
        if (features.isOn(LibraryFeature.todo))
          ...wantedReminders(
            snapshot,
            _clock(),
            showTokens: _reminderShowTokens,
          ),
        if (features.isOn(LibraryFeature.calendar))
          ...calendarWantedReminders(
            _calendar,
            _clock(),
            showTokens: _reminderShowTokens,
          ),
      });
    } on Object catch (error) {
      _log.warning('todo reminders sync failed: $error');
    }
  }

  /// How many reminders the files have for [feature] right now, whatever
  /// its switch says: what turning it off cancels.
  int _scheduledFor(LibraryFeature feature) {
    final snapshot = _snapshot;
    if (snapshot == null) return 0;
    return switch (feature) {
      LibraryFeature.todo => wantedReminders(
        snapshot,
        _clock(),
        showTokens: _reminderShowTokens,
      ).length,
      LibraryFeature.calendar => calendarWantedReminders(
        _calendar,
        _clock(),
        showTokens: _reminderShowTokens,
      ).length,
      _ => 0,
    };
  }

  /// Schedules a debounced [_reload] for a session revision event.
  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(refreshDebounce, () => unawaited(_reload()));
  }

  /// Reloads both files (archiving stray completed lines) unless the
  /// probes show neither file moved since the last cycle. Superseded
  /// reloads never publish: only the latest generation assigns state.
  Future<void> _reload() async {
    final root = session.root;
    if (_disposed) {
      return;
    }
    if (root == null) {
      if (_snapshot != null || _error != null) {
        _log.info('todo reload: library closed, clearing snapshot');
        _snapshot = null;
        _store = null;
        _probes = null;
        _error = null;
        notifyListeners();
      }
      return;
    }
    final generation = ++_generation;
    try {
      final store = _sourceFactory(root);
      if (_probes != null) {
        final probes = await store.probe();
        if (generation != _generation || _disposed) {
          _log.debug('todo reload superseded (probe)');
          return;
        }
        if (probes == _probes) {
          _log.debug('todo reload skipped (files unchanged)');
          return;
        }
      }
      final snapshot = await store.migrateCompleted();
      if (generation != _generation || _disposed) {
        _log.debug('todo reload superseded (load)');
        return;
      }
      _store = store;
      _snapshot = snapshot;
      _probes = await store.probe();
      _error = null;
      _log.info(
        'todo reload: ${snapshot.todo.length} open, '
        '${snapshot.done.length} done',
      );
      notifyListeners();
      unawaited(_syncReminders());
    } on Object catch (error) {
      if (generation != _generation || _disposed) {
        return;
      }
      _error = '$error';
      _log.warning('todo reload failed: $error');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _follower.dispose();
    _refreshTimer?.cancel();
    unawaited(_events?.cancel());
    super.dispose();
  }

  /// Builds the real file store for [root] (the default source factory).
  static TodoSource _defaultSource(String root) => TodoStore(root: root);
}
