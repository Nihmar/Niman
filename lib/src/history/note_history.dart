import 'dart:convert';
import 'dart:isolate';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:niman/src/history/snapshot_policy.dart';

/// The library's note history, from the main isolate's side.
///
/// Holds what only the running app knows — which editing session last
/// saved each note — reads the library's settings, logs every decision
/// under `history`, and hands the disk work to `history_store.dart` on a
/// short-lived isolate.
final class NoteHistory {
  /// The history of the library at [root], configured by [config].
  /// [now] is a test seam for the clock.
  new({required this.root, required this.config, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Absolute path of the library root.
  final String root;

  /// The library's settings (`historyVersions`, `historyIntervalMinutes`).
  final LibraryConfigRepo config;

  final DateTime Function() _now;

  static const _log = AppLogger(name: 'history');

  /// The editing session that last saved each note, by library-relative
  /// path.
  final Map<String, int> _sessions = {};

  /// What a save of [path] asks of history: from the library settings,
  /// the clock, and whether [editSession] is new for this note.
  ///
  /// [forced] takes a version whatever the interval (a restore, a sync
  /// download, a replace). Saves without a session (not from the editor)
  /// follow the interval alone.
  Future<SnapshotRequest> requestFor(
    String path, {
    int? editSession,
    HistoryReason? forced,
  }) async {
    final settings = await config.config;
    final sessionStart = editSession != null && _sessions[path] != editSession;
    if (editSession != null) _sessions[path] = editSession;
    return SnapshotRequest(
      limit: settings.historyVersions,
      interval: Duration(minutes: settings.historyIntervalMinutes),
      now: _now(),
      sessionStart: sessionStart,
      forced: forced,
    );
  }

  /// Logs what a snapshot did for [path].
  void report(String path, SnapshotOutcome? outcome, Object? error) {
    if (error != null) {
      _log.error('snapshot "$path" failed, note saved anyway: $error');
      return;
    }
    if (outcome == null) return;
    if (outcome.decision.take) {
      _log.info(outcome.describe(path));
    } else {
      _log.debug(outcome.describe(path));
    }
  }

  /// The versions kept for [path] (oldest first) and its pins.
  Future<HistoryManifest> manifestOf(String path) async {
    final clock = Stopwatch()..start();
    final manifest = await _readManifest(root, path);
    _log.debug(
      'list "$path": ${manifest.versions.length} version(s), '
      'pins ${manifest.pins} (${clock.elapsedMilliseconds} ms)',
    );
    return manifest;
  }

  /// The text of version [number] of [path]; throws [StateError] when it
  /// is gone.
  Future<String> readVersion(String path, int number) async {
    final clock = Stopwatch()..start();
    final bytes = await _readVersion(root, path, number);
    if (bytes == null) {
      _log.warning('read "$path" v$number: gone');
      throw StateError('"$path" has no version $number');
    }
    final text = utf8.decode(bytes, allowMalformed: true);
    _log.debug(
      'read "$path" v$number: ${bytes.length} b '
      '(${clock.elapsedMilliseconds} ms)',
    );
    return text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF
        ? text.substring(1)
        : text;
  }

  /// Pins version [number] of [path] under [pin] (null unpins).
  Future<void> pin(String path, String pin, int? number) async {
    final settings = await config.config;
    final rotated = await _pin(
      root,
      path,
      pin,
      number,
      settings.historyVersions,
    );
    _log.info(
      'pin "$path" $pin -> ${number == null ? 'none' : 'v$number'}'
      '${rotated.isEmpty ? '' : ', rotated out ${rotated.map((n) => 'v$n')}'}',
    );
  }

  /// Pins as [path]'s sync base the version holding the content that
  /// hashes to [sha], keeping the note's current text as a `sync` version
  /// first when no version holds it (docs/dev/sync.md). Returns the pinned
  /// version, or null when the content is gone from both the note and its
  /// history.
  Future<int?> pinSyncBase(String path, String sha) async {
    final clock = Stopwatch()..start();
    final settings = await config.config;
    final now = _now();
    final result = await _pinSyncBase(
      root,
      path,
      sha,
      settings.historyVersions,
      now,
    );
    final pinned = result.pinned;
    final shortSha = sha.length > 8 ? sha.substring(0, 8) : sha;
    final rotated = result.rotated.map((n) => 'v$n').join(', ');
    if (pinned == null) {
      _log.warning(
        'sync base "$path": no version holds $shortSha any more, '
        'no base pinned (${clock.elapsedMilliseconds} ms)',
      );
    } else {
      _log.info(
        'sync base "$path" -> v$pinned ($shortSha'
        '${result.wrote ? ', kept as a new sync version' : ''}'
        '${rotated.isEmpty ? '' : ', rotated out $rotated'}'
        ', ${clock.elapsedMilliseconds} ms)',
      );
    }
    return pinned;
  }

  /// Carries the history of [from] to [to] after a rename or a move;
  /// [isDir] for a folder (every note under it follows).
  Future<void> moved(String from, String to, {required bool isDir}) async {
    if (from == to) return;
    final clock = Stopwatch()..start();
    try {
      final count = await _move(root, from, to, isDir);
      final unit = isDir ? 'note histories' : 'versions';
      _log.info(
        'move "$from" -> "$to": $count $unit '
        '(${clock.elapsedMilliseconds} ms)',
      );
    } on Object catch (e) {
      _log.error('move "$from" -> "$to" failed: $e');
    }
    // A session keyed on the old path means nothing at the new one.
    _sessions.remove(from);
  }

  /// Removes the history of [path] (a note gone for good); [isDir] for a
  /// folder.
  Future<void> deleted(String path, {required bool isDir}) async {
    final clock = Stopwatch()..start();
    try {
      final count = await _delete(root, path, isDir);
      final unit = isDir ? 'note histories' : 'versions';
      _log.info(
        'delete "$path": $count $unit removed '
        '(${clock.elapsedMilliseconds} ms)',
      );
    } on Object catch (e) {
      _log.error('delete "$path" failed: $e');
    }
    _sessions.remove(path);
  }

  // Isolate entries: static, so each closure carries only plain values.

  static Future<HistoryManifest> _readManifest(String root, String path) =>
      Isolate.run(() => readHistoryManifest(root, path));

  static Future<List<int>?> _readVersion(
    String root,
    String path,
    int number,
  ) => Isolate.run(() => readHistoryVersion(root, path, number));

  static Future<List<int>> _pin(
    String root,
    String path,
    String pin,
    int? number,
    int limit,
  ) => Isolate.run(
    () => pinHistoryVersion(root, path, pin, number, limit: limit),
  );

  static Future<({int? pinned, bool wrote, List<int> rotated})> _pinSyncBase(
    String root,
    String path,
    String sha,
    int limit,
    DateTime now,
  ) => Isolate.run(
    () => pinSyncBaseVersion(root, path, sha, limit: limit, now: now),
  );

  static Future<int> _move(String root, String from, String to, bool isDir) =>
      Isolate.run(
        () => isDir
            ? moveFolderHistory(root, from, to)
            : moveNoteHistory(root, from, to),
      );

  static Future<int> _delete(String root, String path, bool isDir) =>
      Isolate.run(
        () => isDir
            ? deleteFolderHistory(root, path)
            : deleteNoteHistory(root, path),
      );
}
