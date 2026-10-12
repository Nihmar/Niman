/// Session-bound calendar state (#730): the parsed `calendar.txt`,
/// refreshed on the session's revision events.
///
/// The shell owns one controller and opens it when it mounts, not when the
/// journal does: the dock pane, the phone's day card and the Home tile all
/// read its snapshot, and none of them owns the file. A revision event
/// fires for every index change (any note edit anywhere), so a reload
/// first probes the file's `(size, mtime)` and skips the content read when
/// it did not move — this file rarely does.
///
/// Phase 1 is read-only. The write ops (add, edit, delete an event) land
/// here in phase 3, with the same shape the todo controller's have.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/calendar/calendar_source.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/session.dart';

/// Owns the calendar's data: the current [snapshot] over the open
/// library's `calendar.txt`.
final class CalendarController extends ChangeNotifier {
  /// Creates a controller over [session].
  ///
  /// [refreshDebounce] delays revision-driven reloads so a burst of index
  /// events causes one reload. [sourceFactory] builds the file source per
  /// library root (defaults to the real store; widget tests inject an
  /// in-memory fake).
  new({
    required this.session,
    this.refreshDebounce = const Duration(milliseconds: 300),
    CalendarSource Function(String root)? sourceFactory,
  }) : _sourceFactory = sourceFactory ?? _defaultSource;

  /// The library session: root path and revision events.
  final LibrarySession session;

  final CalendarSource Function(String root) _sourceFactory;

  static const AppLogger _log = AppLogger(name: 'calendar');

  /// How long revision-driven reloads wait for the event burst to settle.
  final Duration refreshDebounce;

  CalendarSnapshot? _snapshot;
  CalendarFileProbe? _probe;
  String? _error;
  StreamSubscription<int>? _events;
  Timer? _refreshTimer;
  int _generation = 0;
  bool _disposed = false;

  /// The current parsed file, or null while no library is open.
  CalendarSnapshot? get snapshot => _snapshot;

  /// The last load failure message, or null.
  String? get error => _error;

  /// Subscribes to session events and loads the file. Safe to call again
  /// (re-subscribes nothing, reloads).
  Future<void> open() async {
    _log.info('calendar open: root=${session.root}');
    _events ??= session.events.listen((_) => _scheduleRefresh());
    await reload();
  }

  /// Schedules a debounced [reload] for a session revision event.
  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(refreshDebounce, () => unawaited(reload()));
  }

  /// Reloads the file unless its probe shows it did not move. Superseded
  /// reloads never publish: only the latest generation assigns state.
  Future<void> reload() async {
    final root = session.root;
    if (_disposed) return;
    if (root == null) {
      if (_snapshot != null || _error != null) {
        _log.info('calendar reload: library closed, clearing snapshot');
        _snapshot = null;
        _probe = null;
        _error = null;
        notifyListeners();
      }
      return;
    }
    final generation = ++_generation;
    try {
      final store = _sourceFactory(root);
      if (_probe != null) {
        final probe = await store.probe();
        if (generation != _generation || _disposed) {
          _log.debug('calendar reload superseded (probe)');
          return;
        }
        if (probe == _probe) {
          _log.debug('calendar reload skipped (file unchanged)');
          return;
        }
      }
      final snapshot = await store.load();
      if (generation != _generation || _disposed) {
        _log.debug('calendar reload superseded (load)');
        return;
      }
      _snapshot = snapshot;
      _probe = await store.probe();
      _error = null;
      _log.info('calendar reload: ${snapshot.entries.length} lines');
      notifyListeners();
    } on Object catch (error) {
      if (generation != _generation || _disposed) return;
      _error = '$error';
      _log.warning('calendar reload failed: $error');
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
  static CalendarSource _defaultSource(String root) =>
      CalendarStore(root: root);
}
