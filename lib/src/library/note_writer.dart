import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/index_note_content.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:niman/src/history/note_history.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:niman/src/library/note_tidy.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/markdown/note_references.dart';
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
  new({
    required this.root,
    required this.indexer,
    this.history,
    this.quietBeforeReindex = defaultQuietBeforeReindex,
  });

  /// How long a saved note of so many bytes is left quiet before it is read
  /// into the index again: at once for an ordinary note, and for a large one
  /// only once the writer has stopped saving it.
  ///
  /// A reindex reads the whole note back — digest, tags and links, the
  /// full-text row — and on the 247 MB stress note that is 15 to 34 s of work
  /// for every save; written while the writer types, one reindex ran after
  /// another for as long as they did (device log, 2026-09-23). The index
  /// catches up with the note a little later, and the work is done once. The
  /// thresholds are the save's own debounce (`cee783e`).
  final Duration Function(int bytes) quietBeforeReindex;

  /// [quietBeforeReindex]'s default.
  static Duration defaultQuietBeforeReindex(int bytes) {
    if (bytes > 16 << 20) return const Duration(seconds: 30);
    if (bytes > 2 << 20) return const Duration(seconds: 5);
    return Duration.zero;
  }

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

  /// The notes whose reindex is running, and those saved again meanwhile.
  ///
  /// A reindex reads the note from disk when it runs, so a save that lands
  /// while one is running needs one more, after it, and never one per save:
  /// saving a 100 MB note four times queued four reindexes of 6 to 20 s each,
  /// every one of them for text the next had already replaced (0.0.9 stress
  /// test).
  final Set<String> _reindexing = <String>{};
  final Set<String> _reindexAgain = <String>{};

  /// The reindexes waiting for their note to be quiet, by path.
  final Map<String, Timer> _quiet = <String, Timer>{};

  /// What the last write of each note left, by path: handed to its reindex,
  /// which takes it while the file is still that one ([KnownContent]).
  final Map<String, KnownContent> _written = <String, KnownContent>{};

  /// Writes [content] to the note at library-relative [path], creating
  /// the file when it is not there.
  ///
  /// [editSession] identifies the editor session the save comes from (a
  /// note opened once, however many autosaves follow): its first save
  /// keeps the note's previous text as a version. [forced] keeps one
  /// whatever the interval (a restore, a sync download).
  ///
  /// [content] is the note's text, already joined — or a
  /// [NoteContentProducer], which makes its bytes a slice at a time so a
  /// note too long to join on the UI isolate is never joined at all (see
  /// [saveNoteStream]); [contentLength] is then its length in characters,
  /// for the sizes the log reports.
  ///
  /// [references] are the note's tags and links as of [content], when the
  /// editor keeps them: handed to the note's reindex with the digest the
  /// write makes ([KnownContent]).
  Future<void> save(
    String path,
    NoteText content, {
    int? editSession,
    HistoryReason? forced,
    int? contentLength,
    NoteReferences? references,
  }) {
    final queuedAt = Stopwatch()..start();
    return _inTurn(
      path,
      () => _write(
        path,
        content,
        editSession,
        forced,
        queuedAt,
        contentLength,
        references: references,
      ),
    );
  }

  /// Runs [job] on [path]'s save chain: after every write of the note asked
  /// for before it, and before every one asked for after. A failed job does
  /// not stop the ones behind it.
  Future<T> _inTurn<T>(String path, Future<T> Function() job) {
    final previous = _tails[path] ?? Future<void>.value();
    final run = previous
        .then<void>((_) {}, onError: (Object _) {})
        .then((_) => job());
    final tail = run.then<void>((_) {}, onError: (Object _) {});
    _tails[path] = tail;
    unawaited(
      tail.whenComplete(() {
        if (identical(_tails[path], tail)) _tails.remove(path)?.ignore();
      }),
    );
    return run;
  }

  /// Tidies the note at [path] (`formatMarkdown`), in its turn among its
  /// saves; answers whether the note changed.
  ///
  /// In turn, so the text tidied is the note as its last save left it and
  /// nothing written after the tidying began is written over: a save asked
  /// for meanwhile waits for it, then writes its own text. A note past
  /// [tidyLimit] bytes is left as it is — tidying reads and rewrites the
  /// whole note, which on the 247 MB stress note is a note-sized job for a
  /// tidy nobody asked of it by name.
  Future<bool> tidy(String path) => _inTurn(path, () async {
    final tidied = await _tidiedOffIsolate(p.join(root, path));
    if (tidied == null) return false;
    _log.info('tidy: "$path"');
    await _write(path, tidied, null, null, Stopwatch()..start(), null);
    return true;
  });

  /// The largest note [tidy] tidies.
  static const int tidyLimit = 4 << 20;

  /// The tidied text of the note at [abs], or null when it is tidy already,
  /// past [tidyLimit], or gone. Static so the closure holds the path alone.
  static Future<String?> _tidiedOffIsolate(String abs) => IsolateGauge.run(
    () => tidiedNoteText(abs, limit: tidyLimit),
    'tidy "${p.basename(abs)}"',
  );

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
  }) => _inTurn(path, () => _replace(path, tempAbs, forced));

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
      // No snapshot to take means no synchronous work to move anywhere:
      // what is left is a stat, a mkdir and a rename, all async I/O that
      // leaves the event loop free. The isolate bought nothing on that
      // path and was the whole of issue #103 — a rename inside
      // `Isolate.run` stopped returning on Windows, and stayed stuck even
      // after the file it was renaming had been moved away underneath it.
      result = request == null
          ? (
              created: await swapFileIn(abs, tempAbs),
              snapshot: null,
              snapshotError: null,
            )
          : await _replaceOffIsolate(root, path, tempAbs, request);
    } catch (e) {
      _log.error('replace failed: "$path": $e');
      rethrow;
    }
    history?.report(path, result.snapshot, result.snapshotError);
    // The bytes came from elsewhere, unhashed: the reindex reads them.
    _written.remove(path);
    _log.info(
      'replaced from download: "$path" (${result.created ? 'new file, ' : ''}'
      '${clock.elapsedMilliseconds} ms)',
    );
    _reindex(path, abs, created: result.created);
  }

  /// Completes when every re-index started by a save so far has finished.
  ///
  /// One still waiting for its note to be quiet runs now: whoever asks wants
  /// the index as the disk has it.
  Future<void> get indexed async {
    final waiting = _quiet.keys.toList();
    for (final path in waiting) {
      _quiet.remove(path)?.cancel();
      _reindex(path, p.join(root, path), created: false);
    }
    while (_indexing.isNotEmpty) {
      await Future.wait(_indexing.toList());
    }
  }

  Future<void> _write(
    String path,
    NoteText content,
    int? editSession,
    HistoryReason? forced,
    Stopwatch queuedAt,
    int? contentLength, {
    NoteReferences? references,
  }) async {
    final waitMs = queuedAt.elapsedMilliseconds;
    final abs = p.join(root, path);
    final session = editSession == null ? '' : ', session $editSession';
    final force = forced == null ? '' : ', forced ${forced.name}';
    final length = content is String ? content.length : contentLength ?? 0;
    _log.debug(
      'save start: "$path" ($length chars$session$force, '
      'waited $waitMs ms)',
    );
    final request = await history?.requestFor(
      path,
      editSession: editSession,
      forced: forced,
    );
    final NoteWriteResult? result;
    try {
      result = content is String
          ? await _writeOffIsolate(root, path, content, request)
          : await saveNoteStream(
              root: root,
              rel: path,
              produce: content as NoteContentProducer,
              snapshot: request,
            );
    } catch (e) {
      _log.error('save failed: "$path": $e');
      rethrow;
    }
    // A save the producer abandoned: the disk was not touched, so there is
    // nothing to report, log or reindex — the caller's next save writes the
    // note as it then stands.
    if (result == null) return;
    history?.report(path, result.snapshot, result.snapshotError);
    _written[path] = (
      sha256: result.sha256,
      size: result.bytes,
      modified: result.modified,
      references: references,
    );
    _log.info(
      'saved: "$path" (${result.bytes} bytes, '
      '${result.created ? 'new file, ' : ''}'
      'encode ${result.encodeMs} ms, write ${result.writeMs} ms, '
      'total ${queuedAt.elapsedMilliseconds} ms)',
    );
    _reindexWhenQuiet(path, abs, created: result.created, bytes: result.bytes);
  }

  /// Whether the note at library-relative [path] waits for a reindex this
  /// writer will run once it is left alone: the scans that are not the
  /// writer's leave it be meanwhile (`Indexer.awaitedByWriter`).
  bool awaits(String path) => _quiet.containsKey(path);

  /// Reads the note at library-relative [path], of [bytes] bytes, back into
  /// the index as a save of it does: once it has been left alone for
  /// [quietBeforeReindex], and once however many changes come before that.
  ///
  /// For a change made outside the writer whose index rows are owed —
  /// a pin, which records the frontmatter at once and leaves the rest of
  /// the note to this.
  void reindexWhenQuiet(String path, {required int bytes}) =>
      _reindexWhenQuiet(path, p.join(root, path), created: false, bytes: bytes);

  /// Reindexes [path] once it has been left alone for
  /// [quietBeforeReindex] — each save of it starting the wait again. A new
  /// note has no row yet and is indexed at once.
  void _reindexWhenQuiet(
    String path,
    String abs, {
    required bool created,
    required int bytes,
  }) {
    _quiet.remove(path)?.cancel();
    final wait = created ? Duration.zero : quietBeforeReindex(bytes);
    if (wait == Duration.zero) {
      _reindex(path, abs, created: created);
      return;
    }
    _log.debug('reindex of "$path" in ${wait.inSeconds} s, if left alone');
    _quiet[path] = Timer(wait, () {
      _quiet.remove(path);
      _reindex(path, abs, created: false);
    });
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
  ) => IsolateGauge.run(
    () => writeNoteFile(
      p.join(root, rel),
      content,
      root: root,
      rel: rel,
      snapshot: request,
    ),
    'write "$rel"',
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
  ) => IsolateGauge.run(
    () => replaceFileFrom(
      p.join(root, rel),
      tempAbs,
      root: root,
      rel: rel,
      snapshot: request,
    ),
    'replace "$rel"',
  );

  /// Re-reads the saved note into the index, after the save completed.
  ///
  /// An existing note is rescanned, not passed through the (size, mtime)
  /// shortcut of `applyEvents`: an edit that keeps the size inside the
  /// same second (one letter swapped for another) would otherwise read as
  /// "nothing happened". A new file has no row to rescan, so it goes
  /// through `applyEvents`, which creates it.
  void _reindex(String path, String abs, {required bool created}) {
    if (_reindexing.contains(path)) {
      _reindexAgain.add(path);
      return;
    }
    _reindexing.add(path);
    final clock = Stopwatch()..start();
    late final Future<void> job;
    final wrote = _written[path];
    job =
        (created
                ? indexer.applyEvents(root, [abs])
                : indexer.rescanFiles(root, [abs], known: {path: ?wrote}))
            .then(
              (_) => _log.debug(
                'reindexed: "$path" (${clock.elapsedMilliseconds} ms)',
              ),
              onError: (Object e) =>
                  _log.warning('reindex failed: "$path": $e'),
            )
            .whenComplete(() {
              _indexing.remove(job);
              _reindexing.remove(path);
              // Saved again while this one ran: once more, for what the
              // disk holds now.
              if (_reindexAgain.remove(path)) {
                _reindex(path, abs, created: false);
              }
            });
    _indexing.add(job);
  }
}

/// What a save writes: the note's text, joined, or the producer that makes
/// its bytes a slice at a time ([saveNoteStream]).
typedef NoteText = Object;

/// What [writeNoteFile] did: the bytes written, whether the file is new,
/// where the time went, and the history snapshot taken before the write
/// (or why it failed — a failed snapshot never stops the save).
///
/// `sha256` is the digest of the bytes written, made as they were, and
/// `modified` the file's time once in place: what the reindex behind the
/// save takes instead of hashing the note again ([KnownContent]).
typedef NoteWriteResult = ({
  int bytes,
  bool created,
  int encodeMs,
  int writeMs,
  SnapshotOutcome? snapshot,
  String? snapshotError,
  String sha256,
  DateTime modified,
});

/// Runs [writeNoteFile] on a short-lived isolate, without history.
///
/// Top-level, so the closure's context holds the two strings and never a
/// caller's state (a future chain cannot cross an isolate boundary).
Future<NoteWriteResult> writeNoteOffIsolate(String abs, String content) =>
    Isolate.run(() => writeNoteFile(abs, content));

/// Renames the finished file [tempAbs] over [abs], creating missing
/// folders. Returns whether [abs] is a new file. The temp file is gone
/// afterwards, also when the rename fails.
///
/// The attachment half of [replaceFileFrom], on the calling isolate: an
/// attachment keeps no history version, so nothing here is synchronous
/// work that has to be moved off the event loop — a stat, a mkdir and a
/// rename, each of them async I/O the loop does not wait on.
///
/// It ran on a short-lived isolate until issue #103, where the rename
/// inside `Isolate.run` stopped returning on Windows every third
/// attachment of a sync, leaking the isolate with it. The giveaway was
/// that it stayed stuck for as long as the app lived, including after
/// another isolate had renamed the temp away — a rename whose source no
/// longer exists cannot block on the filesystem, so the isolate was
/// never waiting on the file.
Future<bool> swapFileIn(String abs, String tempAbs) async {
  final before = await FileStat.stat(abs);
  final created = before.type == FileSystemEntityType.notFound;
  try {
    if (created) await Directory(p.dirname(abs)).create(recursive: true);
    await _renameOrCopy(abs, tempAbs);
  } on Object {
    try {
      await File(tempAbs).delete();
    } on FileSystemException {
      // Already gone — the rename may have got half-way. Nothing to tidy.
    }
    rethrow;
  }
  return created;
}

/// How long the rename gets before the copy takes over. The ones that
/// work land in single-digit milliseconds.
const Duration _renameGrace = Duration(seconds: 3);

/// Moves [tempAbs] onto [abs], by copy when the rename will not return.
///
/// **A workaround, not a fix** (issue #103). On Windows the third
/// attachment of a sync run goes into `File.rename` and never comes out:
/// not the first, not the second, the third, every run, whichever file
/// happens to be third. The event loop keeps beating, every other call on
/// the same folder — stat, directory walk, read — answers in under a
/// millisecond throughout, and the same code on Linux never pauses.
/// Moving the call off its isolate did not change it, and neither did
/// owning and closing the download's sink first.
///
/// What is left is to stop waiting on it. The rename is given
/// [_renameGrace] and, if it has not returned, the bytes are copied to
/// the target instead and the temp dropped. The copy is verified by size
/// before the temp goes, because a copy — unlike a rename — is not
/// atomic, and half a file recorded as whole would be worse than a slow
/// sync.
///
/// The abandoned rename is left running. It has never been seen to
/// finish; if it ever did, it would put the same bytes at the same path.
Future<void> _renameOrCopy(String abs, String tempAbs) async {
  const log = AppLogger(name: 'swap');
  final temp = File(tempAbs);
  try {
    await temp.rename(abs).timeout(_renameGrace);
    return;
  } on TimeoutException {
    log.warning(
      '"${p.basename(abs)}": the rename has not returned in '
      '${_renameGrace.inSeconds}s (issue #103) — copying instead',
    );
  }
  await copyFileOver(abs, tempAbs);
}

/// Copies [tempAbs] onto [abs] and drops the temp — the slow half of the
/// swap, kept apart so it can be tested without a rename that hangs
/// (issue #103).
///
/// The copy is checked by size before the temp goes: a copy is not
/// atomic, unlike the rename it stands in for, and half a file recorded
/// as a whole one would outlive the sync that wrote it.
///
/// A temp that will not delete is left where it is. The abandoned rename
/// may still hold it; it is hidden, the indexer skips it, and the bytes
/// are already in place, so failing a finished download over it would
/// help nobody.
Future<void> copyFileOver(String abs, String tempAbs) async {
  const log = AppLogger(name: 'swap');
  final name = p.basename(abs);
  final expected = (await FileStat.stat(tempAbs)).size;
  await File(tempAbs).copy(abs);
  final copied = (await FileStat.stat(abs)).size;
  if (copied != expected) {
    throw FileSystemException('copied $copied of $expected bytes', abs);
  }
  log.warning('"$name": copied $copied bytes in place');
  try {
    await File(tempAbs).delete().timeout(_renameGrace);
  } on Object catch (error) {
    log.warning('"$name": the temp could not be removed: $error');
  }
}

/// Renames the finished file [tempAbs] over [abs] (creating missing
/// folders), after keeping the replaced content as a history version when
/// [snapshot] says so. The temp file is deleted when the rename fails.
///
/// Top-level so [Isolate.run] can take it. The isolate is here for
/// [snapshotBeforeWrite], which reads and copies the note being replaced;
/// an attachment has no snapshot and takes [swapFileIn] instead.
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
    sha256: sha256.convert(encoded).toString(),
    modified: file.statSync().modified,
  );
}
