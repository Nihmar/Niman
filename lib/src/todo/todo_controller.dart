/// Session-bound todo state: migration-on-open + revision-driven refresh
/// (plan/todo-tab.md T-TD-03).
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

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/todo/reminders.dart';
import 'package:copist/src/todo/todo_source.dart';
import 'package:copist/src/todo/todo_store.dart';
import 'package:flutter/foundation.dart';

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
  TodoController({
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

  static const AppLogger _log = AppLogger(name: 'todo');

  /// How long revision-driven reloads wait for the event burst to settle.
  final Duration refreshDebounce;

  TodoSource? _store;
  TodoSnapshot? _snapshot;
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
    await _reload();
  }

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

  /// Runs [op] on the current store and publishes the returned snapshot
  /// (no-op while no library is open; failures surface on [error]).
  /// [label] names the op in the debug log.
  Future<void> _apply(
    String label,
    Future<TodoSnapshot> Function(TodoSource store) op,
  ) async {
    final store = _store;
    if (store == null || _disposed) {
      _log.debug('todo $label dropped (no store)');
      return;
    }
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
    }
    if (!_disposed) {
      notifyListeners();
      unawaited(_syncReminders());
    }
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
      await service.reconcile(wantedReminders(snapshot, _clock()));
    } on Object catch (error) {
      _log.warning('todo reminders sync failed: $error');
    }
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
    _refreshTimer?.cancel();
    unawaited(_events?.cancel());
    super.dispose();
  }

  /// Builds the real file store for [root] (the default source factory).
  static TodoSource _defaultSource(String root) => TodoStore(root: root);
}
