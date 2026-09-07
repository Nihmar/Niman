/// Session-bound todo state: migration-on-open + revision-driven refresh
/// (plan/todo-tab.md T-TD-03).
///
/// The Todo tab owns one controller: opening it subscribes to the
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

import 'package:copist/src/library/session.dart';
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
  TodoController({
    required this.session,
    DateTime Function()? clock,
    this.refreshDebounce = const Duration(milliseconds: 300),
  }) : _clock = clock ?? DateTime.now;

  /// The library session: root path and revision events.
  final LibrarySession session;

  final DateTime Function() _clock;

  /// How long revision-driven reloads wait for the event burst to settle.
  final Duration refreshDebounce;

  TodoStore? _store;
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
    _events ??= session.events.listen((_) => _scheduleRefresh());
    await _reload();
  }

  /// Appends [line] to `todo.txt`.
  Future<void> add(String line) {
    return _apply((store) => store.add(line));
  }

  /// Checks an open task on the controller's clock.
  Future<void> check(TodoEntry entry) {
    return _apply((store) => store.checkAt(entry.lineIndex, _clock()));
  }

  /// Reopens a completed task back into `todo.txt`.
  Future<void> uncheck(TodoEntry entry) {
    return _apply((store) => store.uncheckAt(entry.lineIndex));
  }

  /// Replaces an open task's line (edit).
  Future<void> updateTodo(TodoEntry entry, String line) {
    return _apply((store) => store.updateTodoAt(entry.lineIndex, line));
  }

  /// Replaces a completed task's line (edit from the done view).
  Future<void> updateDone(TodoEntry entry, String line) {
    return _apply((store) => store.updateDoneAt(entry.lineIndex, line));
  }

  /// Removes an open task's line outright.
  Future<void> deleteTodo(TodoEntry entry) {
    return _apply((store) => store.deleteTodoAt(entry.lineIndex));
  }

  /// Removes a completed task's line outright.
  Future<void> deleteDone(TodoEntry entry) {
    return _apply((store) => store.deleteDoneAt(entry.lineIndex));
  }

  /// Runs [op] on the current store and publishes the returned snapshot
  /// (no-op while no library is open; failures surface on [error]).
  Future<void> _apply(
    Future<TodoSnapshot> Function(TodoStore store) op,
  ) async {
    final store = _store;
    if (store == null || _disposed) {
      return;
    }
    try {
      _snapshot = await op(store);
      _probes = await store.probe();
      _error = null;
    } on Object catch (error) {
      _error = '$error';
    }
    if (!_disposed) {
      notifyListeners();
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
      final store = TodoStore(root: root);
      if (_probes != null) {
        final probes = await store.probe();
        if (generation != _generation || _disposed) {
          return;
        }
        if (probes == _probes) {
          return;
        }
      }
      final snapshot = await store.migrateCompleted();
      if (generation != _generation || _disposed) {
        return;
      }
      _store = store;
      _snapshot = snapshot;
      _probes = await store.probe();
      _error = null;
      notifyListeners();
    } on Object catch (error) {
      if (generation != _generation || _disposed) {
        return;
      }
      _error = '$error';
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
}
