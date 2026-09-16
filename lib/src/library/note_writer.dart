import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:niman/src/history/note_history.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:path/path.dart' as p;

/// Saves note text to disk: the one write path the editor goes through.
///
/// Saves of the same note run one after another; saves of different notes
/// never wait on each other, nor on the structural ops `NoteOps` chains
/// (a large empty-trash must not hold up typing). Before each write the
/// [history] decides whether the text about to be replaced becomes a
/// version; the snapshot and the write run together off the UI isolate.
/// The index catches up after each write without the caller waiting on
/// it: a save completes when the disk holds the text.
final class NoteWriter {
  /// Creates the writer for the library at [root], re-indexing each saved
  /// note through [indexer]; without [history] no versions are kept.
  new({required this.root, required this.indexer, this.history});

  /// Absolute path of the library root.
  final String root;

  /// The shared indexer the saved notes are re-read into.
  final Indexer indexer;

  /// The library's note history, or null to keep none.
  final NoteHistory? history;

  static const _log = AppLogger(name: 'save');

  /// The tail of each note's save chain, by library-relative path.
  final Map<String, Future<void>> _tails = {};

  /// Re-index jobs not finished yet.
  final Set<Future<void>> _indexing = {};

  /// Writes [content] to the note at library-relative [path], creating
  /// the file when it is not there.
  ///
  /// [editSession] identifies the editor session the save comes from (a
  /// note opened once, however many autosaves follow): its first save
  /// keeps the note's previous text as a version. [forced] keeps one
  /// whatever the interval (a restore, a sync download).
  Future<void> save(
    String path,
    String content, {
    int? editSession,
    HistoryReason? forced,
  }) {
    final queuedAt = Stopwatch()..start();
    final previous = _tails[path] ?? Future<void>.value();
    final run = previous
        .then<void>((_) {}, onError: (Object _) {})
        .then((_) => _write(path, content, editSession, forced, queuedAt));
    final tail = run.then<void>((_) {}, onError: (Object _) {});
    _tails[path] = tail;
    unawaited(
      tail.whenComplete(() {
        if (identical(_tails[path], tail)) _tails.remove(path)?.ignore();
      }),
    );
    return run;
  }

  /// Replaces the file at library-relative [path] with the finished file
  /// at [tempAbs] (a verified sync download next to it), in the same
  /// per-path order as [save] — so a download never interleaves with an
  /// editor save of the same note.
  ///
  /// With [forced], the text being replaced is first kept as a history
  /// version (a note); without, the file is swapped in as is (an
  /// attachment). The temp file is gone afterwards, also on failure.
  Future<void> replaceFromFile(
    String path,
    String tempAbs, {
    HistoryReason? forced,
  }) {
    final previous = _tails[path] ?? Future<void>.value();
    final run = previous
        .then<void>((_) {}, onError: (Object _) {})
        .then((_) => _replace(path, tempAbs, forced));
    final tail = run.then<void>((_) {}, onError: (Object _) {});
    _tails[path] = tail;
    unawaited(
      tail.whenComplete(() {
        if (identical(_tails[path], tail)) _tails.remove(path)?.ignore();
      }),
    );
    return run;
  }

  Future<void> _replace(
    String path,
    String tempAbs,
    HistoryReason? forced,
  ) async {
    final clock = Stopwatch()..start();
    final abs = p.join(root, path);
    final request = forced == null
        ? null
        : await history?.requestFor(path, forced: forced);
    final ({bool created, SnapshotOutcome? snapshot, String? snapshotError})
    result;
    try {
      result = await _replaceOffIsolate(root, path, tempAbs, request);
    } catch (e) {
      _log.error('replace failed: "$path": $e');
      rethrow;
    }
    history?.report(path, result.snapshot, result.snapshotError);
    _log.info(
      'replaced from download: "$path" (${result.created ? 'new file, ' : ''}'
      '${clock.elapsedMilliseconds} ms)',
    );
    _reindex(path, abs, created: result.created);
  }

  /// Completes when every re-index started by a save so far has finished.
  Future<void> get indexed async {
    while (_indexing.isNotEmpty) {
      await Future.wait(_indexing.toList());
    }
  }

  Future<void> _write(
    String path,
    String content,
    int? editSession,
    HistoryReason? forced,
    Stopwatch queuedAt,
  ) async {
    final waitMs = queuedAt.elapsedMilliseconds;
    final abs = p.join(root, path);
    final session = editSession == null ? '' : ', session $editSession';
    final force = forced == null ? '' : ', forced ${forced.name}';
    _log.debug(
      'save start: "$path" (${content.length} chars$session$force, '
      'waited $waitMs ms)',
    );
    final request = await history?.requestFor(
      path,
      editSession: editSession,
      forced: forced,
    );
    final NoteWriteResult result;
    try {
      result = await _writeOffIsolate(root, path, content, request);
    } catch (e) {
      _log.error('save failed: "$path": $e');
      rethrow;
    }
    history?.report(path, result.snapshot, result.snapshotError);
    _log.info(
      'saved: "$path" (${result.bytes} bytes, '
      '${result.created ? 'new file, ' : ''}'
      'encode ${result.encodeMs} ms, write ${result.writeMs} ms, '
      'total ${queuedAt.elapsedMilliseconds} ms)',
    );
    _reindex(path, abs, created: result.created);
  }

  /// Runs [writeNoteFile] with its snapshot on a short-lived isolate.
  ///
  /// Static, so the closure's context holds plain values and never the
  /// writer (whose future chains cannot cross an isolate boundary).
  static Future<NoteWriteResult> _writeOffIsolate(
    String root,
    String rel,
    String content,
    SnapshotRequest? request,
  ) => Isolate.run(
    () => writeNoteFile(
      p.join(root, rel),
      content,
      root: root,
      rel: rel,
      snapshot: request,
    ),
  );

  /// Runs [replaceFileFrom] on a short-lived isolate; static for the same
  /// reason as [_writeOffIsolate].
  static Future<
    ({bool created, SnapshotOutcome? snapshot, String? snapshotError})
  >
  _replaceOffIsolate(
    String root,
    String rel,
    String tempAbs,
    SnapshotRequest? request,
  ) => Isolate.run(
    () => replaceFileFrom(
      p.join(root, rel),
      tempAbs,
      root: root,
      rel: rel,
      snapshot: request,
    ),
  );

  /// Re-reads the saved note into the index, after the save completed.
  ///
  /// An existing note is rescanned, not passed through the (size, mtime)
  /// shortcut of `applyEvents`: an edit that keeps the size inside the
  /// same second (one letter swapped for another) would otherwise read as
  /// "nothing happened". A new file has no row to rescan, so it goes
  /// through `applyEvents`, which creates it.
  void _reindex(String path, String abs, {required bool created}) {
    final clock = Stopwatch()..start();
    late final Future<void> job;
    job =
        (created
                ? indexer.applyEvents(root, [abs])
                : indexer.rescanFiles(root, [abs]))
            .then(
              (_) => _log.debug(
                'reindexed: "$path" (${clock.elapsedMilliseconds} ms)',
              ),
              onError: (Object e) =>
                  _log.warning('reindex failed: "$path": $e'),
            )
            .whenComplete(() => _indexing.remove(job));
    _indexing.add(job);
  }
}

/// What [writeNoteFile] did: the bytes written, whether the file is new,
/// where the time went, and the history snapshot taken before the write
/// (or why it failed — a failed snapshot never stops the save).
typedef NoteWriteResult = ({
  int bytes,
  bool created,
  int encodeMs,
  int writeMs,
  SnapshotOutcome? snapshot,
  String? snapshotError,
});

/// Runs [writeNoteFile] on a short-lived isolate, without history.
///
/// Top-level, so the closure's context holds the two strings and never a
/// caller's state (a future chain cannot cross an isolate boundary).
Future<NoteWriteResult> writeNoteOffIsolate(String abs, String content) =>
    Isolate.run(() => writeNoteFile(abs, content));

/// Renames the finished file [tempAbs] over [abs] (creating missing
/// folders), after keeping the replaced content as a history version when
/// [snapshot] says so. The temp file is deleted when the rename fails.
///
/// Top-level so [Isolate.run] can take it.
Future<({bool created, SnapshotOutcome? snapshot, String? snapshotError})>
replaceFileFrom(
  String abs,
  String tempAbs, {
  String? root,
  String? rel,
  SnapshotRequest? snapshot,
}) async {
  SnapshotOutcome? outcome;
  String? snapshotError;
  if (snapshot != null && root != null && rel != null) {
    try {
      outcome = snapshotBeforeWrite(root, rel, snapshot);
    } on Object catch (e) {
      snapshotError = '$e';
    }
  }
  final file = File(abs);
  final created = !file.existsSync();
  try {
    if (created) await file.parent.create(recursive: true);
    await File(tempAbs).rename(abs);
  } on Object {
    final temp = File(tempAbs);
    if (temp.existsSync()) await temp.delete();
    rethrow;
  }
  return (created: created, snapshot: outcome, snapshotError: snapshotError);
}

/// Encodes [content] and writes it atomically to [abs], creating missing
/// folders. With [snapshot] (and the note's [root] and library-relative
/// [rel]) the text being replaced is first kept as a history version when
/// the request says so.
///
/// Top-level so [Isolate.run] can take it: the message carries plain
/// values only.
Future<NoteWriteResult> writeNoteFile(
  String abs,
  String content, {
  String? root,
  String? rel,
  SnapshotRequest? snapshot,
}) async {
  SnapshotOutcome? outcome;
  String? snapshotError;
  if (snapshot != null && root != null && rel != null) {
    try {
      outcome = snapshotBeforeWrite(root, rel, snapshot);
    } on Object catch (e) {
      snapshotError = '$e';
    }
  }
  final encodeClock = Stopwatch()..start();
  final encoded = utf8.encode(content);
  final encodeMs = encodeClock.elapsedMilliseconds;
  final writeClock = Stopwatch()..start();
  final file = File(abs);
  final created = !file.existsSync();
  if (created) await file.parent.create(recursive: true);
  await writeFileAtomically(file, encoded);
  return (
    bytes: encoded.length,
    created: created,
    encodeMs: encodeMs,
    writeMs: writeClock.elapsedMilliseconds,
    snapshot: outcome,
    snapshotError: snapshotError,
  );
}
