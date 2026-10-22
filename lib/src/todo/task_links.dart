/// The links of the tasks in `todo.txt` and `done.txt`, resolved in memory
/// and kept current (#1152).
///
/// A task links a note with a wikilink or a Markdown link in its text. The
/// index holds notes only, and nothing about a link is stored: this map is
/// built from the tasks' two files whenever they are wanted, by the notes'
/// own resolver, in one batched call (`QueryResolver.resolveQueries`). It
/// answers three questions, cheaply once built:
///
/// - the links of a task (`linksOf`), for the chips the Todo
///   tab draws;
/// - the tasks that link a note (`tasksFor`), open and done, for
///   a note's *Tasks* list;
/// - the tasks whose links resolved to files about to move
///   (`movedBy`), for the rename rewrite.
///
/// A widget listens to the map and reads `index` (or the three
/// methods, which are its) in `build`.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/links/library_links.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/task_link.dart';
import 'package:niman/src/todo/task_link_hits.dart';
import 'package:niman/src/todo/task_link_index.dart';
import 'package:niman/src/todo/task_link_reads.dart';
import 'package:niman/src/todo/todo_store.dart';

/// The resolved links of the open library's tasks, as a [Listenable].
///
/// Rebuilt when the tasks change (`tasks` notifies) and, with the links read
/// already, when the library's index reports changes — a note made, renamed
/// or deleted can make a task's link live or dead. Index bursts are
/// coalesced by [indexDebounce].
///
/// Builds never overlap, and never publish a stale result: one runs at a
/// time, and when the snapshot it started from is no longer the current one
/// its answer is dropped, the newer snapshot having asked for its own. It is
/// inert — the index [TaskLinkIndex.empty], no lookups — while `enabled` is
/// false (the Todo feature is off, or no library is open) and while the
/// library has no index to ask.
final class TaskLinkMap extends ChangeNotifier {
  /// Follows `tasks`, whose current contents `snapshot` reads, and resolves
  /// their links through the `links` of the open library.
  ///
  /// `enabled` tells whether to build at all, and `enabledChanges` says it
  /// may have changed (the library's features).
  new({
    required this._tasks,
    required this._snapshot,
    required this._links,
    this._enabled = _always,
    this._enabledChanges,
    this.indexDebounce = const Duration(milliseconds: 300),
  }) {
    _tasks.addListener(_request);
    _enabledChanges?.addListener(_request);
    _request();
  }

  static bool _always() => true;

  static const AppLogger _log = AppLogger(name: 'todo');

  /// How long an index change waits for the burst it is in to settle.
  final Duration indexDebounce;

  final Listenable _tasks;
  final TodoSnapshot? Function() _snapshot;
  final Future<LibraryLinks?> Function() _links;
  final bool Function() _enabled;
  final Listenable? _enabledChanges;

  TaskLinkIndex _index = TaskLinkIndex.empty;
  TaskLinkReads? _reads;
  LibraryLinks? _watched;
  StreamSubscription<void>? _changes;
  Timer? _timer;
  Completer<void>? _idle;
  bool _running = false;
  bool _again = false;
  bool _disposed = false;

  /// The links as of the last build; [TaskLinkIndex.empty] while inert.
  TaskLinkIndex get index => _index;

  /// The links of [task] in order (see `TaskLinkIndex.linksOf`).
  List<TaskLink> linksOf(TodoTask task) => _index.linksOf(task);

  /// The tasks that link the note at [notePath] (see
  /// `TaskLinkIndex.tasksFor`).
  NoteTasks tasksFor(String notePath) => _index.tasksFor(notePath);

  /// The tasks with a link to one of [oldPaths] (see
  /// `TaskLinkIndex.movedBy`).
  List<MovedTaskLinks> movedBy(Iterable<String> oldPaths) =>
      _index.movedBy(oldPaths);

  /// Completes once no build is running or waiting: what a test, or a flow
  /// that wants the map current, awaits after a change.
  ///
  /// An index change still waiting out [indexDebounce] is built now rather
  /// than left behind: a note made and renamed inside that window would
  /// otherwise be missing from the answer the rename asks for.
  Future<void> get settled {
    if (_timer?.isActive ?? false) {
      _timer!.cancel();
      _request();
    }
    return _idle?.future ?? Future<void>.value();
  }

  void _request() {
    if (_disposed) return;
    _again = true;
    if (_running) return;
    _running = true;
    _idle = Completer<void>();
    unawaited(_drain());
  }

  Future<void> _drain() async {
    try {
      while (_again && !_disposed) {
        _again = false;
        await _build();
      }
    } finally {
      _running = false;
      final idle = _idle;
      _idle = null;
      if (idle != null && !idle.isCompleted) idle.complete();
    }
  }

  TodoSnapshot? _current() => _enabled() ? _snapshot() : null;

  Future<void> _build() async {
    final snapshot = _current();
    if (snapshot == null) {
      _reads = null;
      _publish(TaskLinkIndex.empty);
      return;
    }
    final kept = _reads;
    final reads = kept != null && identical(kept.snapshot, snapshot)
        ? kept
        : _reads = TaskLinkReads(snapshot, previous: kept);
    if (reads.isEmpty) {
      _publish(TaskLinkIndex.empty);
      return;
    }
    try {
      final source = await _links();
      if (_disposed) return;
      if (source == null) {
        _publish(TaskLinkIndex.empty);
        return;
      }
      _watch(source);
      final resolved = await source.resolveQueries(reads.queries);
      // The tasks moved on while the index was asked: that answer is for
      // links that are gone, and the move has asked for a build of its own.
      if (_disposed || !identical(snapshot, _current())) return;
      _publish(TaskLinkIndex.of(reads, resolved));
    } on Object catch (error) {
      // The links drawn stay as they were: a failed read is not a reason to
      // take the chips off.
      _log.warning('task links: resolving failed: $error');
    }
  }

  void _publish(TaskLinkIndex next) {
    final quiet = next.isEmpty && _index.isEmpty;
    _index = next;
    if (!quiet) notifyListeners();
  }

  /// Listens to the library's index changes, once for each library there is.
  void _watch(LibraryLinks source) {
    if (identical(source, _watched)) return;
    unawaited(_changes?.cancel());
    _watched = source;
    _changes = source.changes.listen((_) => _later());
  }

  void _later() {
    _timer?.cancel();
    _timer = Timer(indexDebounce, _request);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_changes?.cancel());
    _tasks.removeListener(_request);
    _enabledChanges?.removeListener(_request);
    super.dispose();
  }
}
