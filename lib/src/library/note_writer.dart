import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/creation_time.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/index_note_content.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/db/read_cancel.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:niman/src/history/note_history.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:niman/src/library/note_save_result.dart';
import 'package:niman/src/library/note_tidy.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/library/note_writer_blocking.dart';
import 'package:niman/src/library/reindex_scheduler.dart';
import 'package:niman/src/lint/lint_rule.dart';
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
  ///
  /// [readIntoIndex] replaces the read of a note into the index, which is
  /// the indexer's: a seam for a test that holds a read in its read phase.
  new({
    required this.root,
    required this.indexer,
    this.history,
    Duration Function(int bytes) quietBeforeReindex =
        ReindexScheduler.defaultQuietBeforeReindex,
    Future<bool> Function(
      String path, {
      required bool created,
      required ReadCancel cancel,
    })?
    readIntoIndex,
  }) {
    _reindexer = ReindexScheduler(
      chainOf: (path) => _tails[path],
      read: readIntoIndex ?? _readIntoIndex,
      quietBeforeReindex: quietBeforeReindex,
    );
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

  /// When each saved note is read back into the index.
  late final ReindexScheduler _reindexer;

  /// What the last write of each note left, by path: handed to its reindex,
  /// which takes it while the file is still that one ([KnownContent]).
  final Map<String, KnownContent> _written = <String, KnownContent>{};

  /// A writer's record of what a note's last write left, as the stamp a
  /// save's external check compares against (`SnapshotRequest.lastWritten`);
  /// null when this writer has not written the note.
  static DiskStamp? _stampOf(KnownContent? wrote) => wrote == null
      ? null
      : DiskStamp(size: wrote.size, modified: wrote.modified);

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
  /// [saveNoteStream]). Its length is the editor's to log: the writer only
  /// sees bytes, after the write.
  ///
  /// [references] are the note's tags and links as of [content], when the
  /// editor keeps them: handed to the note's reindex with the digest the
  /// write makes ([KnownContent]).
  ///
  /// [expected] is the file as the saving editor last saw it (#1055): when the
  /// file on disk is another, somebody else wrote it since, and their version
  /// is kept in the history before this save replaces it
  /// ([HistoryReason.external]; [NoteSaveResult.keptExternal]).
  ///
  /// Answers what the write left on the disk ([NoteSaveResult]), or null when
  /// the producer abandoned the save and the disk was not touched.
  Future<NoteSaveResult?> save(
    String path,
    NoteText content, {
    int? editSession,
    HistoryReason? forced,
    NoteReferences? references,
    DiskStamp? expected,
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
        references: references,
        expected: expected,
      ),
    );
  }

  /// Runs [job] on [path]'s save chain: after every write of the note asked
  /// for before it, and before every one asked for after. A failed job does
  /// not stop the ones behind it.
  ///
  /// A reindex of the note still reading it is cancelled
  /// ([ReindexScheduler.cancelRead]): the job writes the note, so what the
  /// read finds is already old. The job starts once that read has let go of
  /// the file, not before.
  Future<T> _inTurn<T>(String path, Future<T> Function() job) {
    final released = _reindexer.cancelRead(path);
    final previous = _tails[path] ?? Future<void>.value();
    final run = previous
        .then<void>((_) {}, onError: (Object _) {})
        .then((_) => released)
        .then((_) => job());
    final tail = run.then<void>((_) {}, onError: (Object _) {});
    _tails[path] = tail;
    unawaited(
      tail.whenComplete(() {
        if (!identical(_tails[path], tail)) return;
        _tails.remove(path)?.ignore();
        _reindexer.settled(path);
      }),
    );
    return run;
  }

  /// Tidies the note at [path] (`formatMarkdown`), in its turn among its
  /// saves; answers whether the note changed. [rules] are the #72 rules to
  /// apply; null applies them all.
  ///
  /// In turn, so the text tidied is the note as its last save left it and
  /// nothing written after the tidying began is written over: a save asked
  /// for meanwhile waits for it, then writes its own text. A note past
  /// [tidyLimit] bytes is left as it is — tidying reads and rewrites the
  /// whole note, which on the 247 MB stress note is a note-sized job for a
  /// tidy nobody asked of it by name.
  Future<bool> tidy(String path, {Set<LintRule>? rules}) =>
      _inTurn(path, () async {
        final tidied = await _tidiedOffIsolate(p.join(root, path), rules);
        if (tidied == null) return false;
        _log.info('tidy: "$path"');
        await _write(path, tidied, null, null, Stopwatch()..start());
        return true;
      });

  /// The largest note [tidy] tidies.
  static const int tidyLimit = 4 << 20;

  /// The tidied text of the note at [abs], or null when it is tidy already,
  /// past [tidyLimit], or gone. Static so the closure holds the path, the
  /// rules and the limit alone.
  static Future<String?> _tidiedOffIsolate(String abs, Set<LintRule>? rules) =>
      IsolateGauge.run(
        () => tidiedNoteText(abs, limit: tidyLimit, rules: rules),
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
    _reindexer.reindex(path, created: result.created);
  }

  /// Runs [write], which puts the new file at library-relative [path] on the
  /// disk by itself — a sync download written straight to its final name —
  /// in the same per-path order as [save], then does for the file what
  /// [replaceFromFile] does for a new one: forgets what this writer last
  /// left at [path] and reads the file into the index.
  ///
  /// The file is complete and closed when [write] answers. When it throws,
  /// nothing is recorded or indexed: [write] leaves nothing behind.
  Future<T> createdBy<T>(String path, Future<T> Function() write) =>
      _inTurn(path, () async {
        final clock = Stopwatch()..start();
        final T result;
        try {
          result = await write();
        } catch (e) {
          _log.error('create failed: "$path": $e');
          rethrow;
        }
        _written.remove(path);
        _log.info(
          'created from download: "$path" (new file, '
          '${clock.elapsedMilliseconds} ms)',
        );
        _reindexer.reindex(path, created: true);
        return result;
      });

  /// Completes when every re-index started by a save so far has finished.
  ///
  /// One still waiting for its note to be quiet runs now, and one owed to a
  /// note whose saves are still running runs once they end: whoever asks
  /// wants the index as the disk has it.
  Future<void> get indexed => _reindexer.indexed;

  Future<NoteSaveResult?> _write(
    String path,
    NoteText content,
    int? editSession,
    HistoryReason? forced,
    Stopwatch queuedAt, {
    NoteReferences? references,
    DiskStamp? expected,
  }) async {
    final waitMs = queuedAt.elapsedMilliseconds;
    final session = editSession == null ? '' : ', session $editSession';
    final force = forced == null ? '' : ', forced ${forced.name}';
    final length = content is String ? '${content.length} chars' : 'streamed';
    _log.debug(
      'save start: "$path" ($length$session$force, '
      'waited $waitMs ms)',
    );
    final request = await history?.requestFor(
      path,
      editSession: editSession,
      forced: forced,
      expected: expected,
      // The file this writer last left is the app's own write, not
      // somebody else's, whatever the editor's stamp says (#1055).
      lastWritten: _stampOf(_written[path]),
      lastWrittenSha256: _written[path]?.sha256,
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
    if (result == null) return null;
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
    _reindexer.whenQuiet(path, created: result.created, bytes: result.bytes);
    final kept = result.snapshot?.version?.reason == HistoryReason.external;
    if (kept) {
      _log.info('kept the version of "$path" that was written outside');
    }
    return NoteSaveResult(
      stamp: DiskStamp(size: result.bytes, modified: result.modified),
      keptExternal: kept,
    );
  }

  /// Whether the note at library-relative [path] waits for a reindex this
  /// writer will run once it is left alone, or once its saves end: the scans
  /// that are not the writer's leave it be meanwhile
  /// (`Indexer.awaitedByWriter`).
  bool awaits(String path) => _reindexer.awaits(path);

  /// Reads the note at library-relative [path], of [bytes] bytes, back into
  /// the index as a save of it does: once it has been left alone for
  /// [ReindexScheduler.quietBeforeReindex], and once however many changes
  /// come before that.
  ///
  /// For a change made outside the writer whose index rows are owed —
  /// a pin, which records the frontmatter at once and leaves the rest of
  /// the note to this.
  void reindexWhenQuiet(String path, {required int bytes}) =>
      _reindexer.whenQuiet(path, created: false, bytes: bytes);

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

  /// Reads the note at library-relative [path] into the index, for the
  /// reindex scheduler: an existing note is rescanned under [cancel], a
  /// [created] one goes through `applyEvents`, which adds it. Answers false
  /// when the read was dropped.
  Future<bool> _readIntoIndex(
    String path, {
    required bool created,
    required ReadCancel cancel,
  }) {
    final abs = p.join(root, path);
    if (created) return indexer.applyEvents(root, [abs]).then((_) => true);
    return indexer.rescanFiles(
      root,
      [abs],
      known: {path: ?_written[path]},
      cancel: cancel,
    );
  }
}

/// What a save writes: the note's text, joined, or the producer that makes
/// its bytes a slice at a time ([saveNoteStream]).
typedef NoteText = Object;

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
/// [_renameGrace] and, if it has not returned, the bytes are copied to a
/// sibling of the target and renamed onto it, and the temp dropped. The
/// copy is verified by size before that rename, because a copy — unlike
/// a rename — is not atomic, and half a file recorded as whole would be
/// worse than a slow sync.
///
/// The abandoned rename is left running. It has never been seen to
/// finish; if it ever did, it would put the same bytes at the same path.
Future<void> _renameOrCopy(String abs, String tempAbs) async {
  const log = AppLogger(name: 'swap');
  final temp = File(tempAbs);
  keepCreationTime(target: abs, replacement: tempAbs);
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
/// The copy goes to a sibling of the target in [abs]'s own directory,
/// renamed onto it once the bytes are all there — the shape
/// [atomicTempPath] and [writeFileAtomically] already use (issue #369).
/// Copying straight onto [abs] made the copy itself the live file, so a
/// kill mid-copy left a truncated note, or an attachment the next sync
/// would upload over the good remote, under its real name, with no temp
/// left to recover from.
///
/// The staged copy is checked by size before it is renamed: a copy is not
/// atomic, unlike the rename it stands in for, and half a file recorded
/// as a whole one would outlive the sync that wrote it. A short copy is
/// dropped there, leaving [abs] as it was.
///
/// The staged rename gets the same [_renameGrace] as the guarded one, and
/// past it the bytes go straight onto [abs]: the rename this function
/// stands in for hangs on Windows (issue #103), and the staged one is a
/// rename too (#492). [renameStaged] and [grace] are seams for a test that
/// hangs the staged rename without waiting the real grace out. Every delete
/// of the staged file gets that grace too — the abandoned rename may hold
/// it, and a delete that waits on it would stall the run the same way;
/// [deleteStaged] is the seam for a delete that hangs. The temp [tempAbs]
/// is no file of that rename's: its delete keeps the real [_renameGrace]
/// whatever [grace] a test passes (#992), and [deleteTemp] is its seam.
///
/// A temp that will not delete is left where it is. The abandoned rename
/// may still hold it; it is hidden, the indexer skips it, and the bytes
/// are already in place, so failing a finished download over it would
/// help nobody.
Future<void> copyFileOver(
  String abs,
  String tempAbs, {
  Duration grace = _renameGrace,
  Future<void> Function(File staged, String abs)? renameStaged,
  Future<void> Function(File staged)? deleteStaged,
  Future<void> Function(File temp)? deleteTemp,
}) async {
  const log = AppLogger(name: 'swap');
  final name = p.basename(abs);
  final expected = (await FileStat.stat(tempAbs)).size;
  final rename =
      renameStaged ?? (File staged, String target) => staged.rename(target);
  final delete = deleteStaged ?? (File staged) => staged.delete();
  final dropTemp = deleteTemp ?? (File temp) => temp.delete();
  final staged = atomicTempPath(
    File(abs),
    DateTime.now().microsecondsSinceEpoch,
  );
  try {
    await File(tempAbs).copy(staged.path);
    final copied = (await FileStat.stat(staged.path)).size;
    if (copied != expected) {
      throw FileSystemException('copied $copied of $expected bytes', abs);
    }
    keepCreationTime(target: abs, replacement: staged.path);
    try {
      await rename(staged, abs).timeout(grace);
    } on TimeoutException {
      log.warning(
        '"$name": the staged rename has not returned in '
        '${grace.inSeconds}s (issue #103) — copying directly',
      );
      await File(staged.path).copy(abs);
      try {
        await delete(staged).timeout(grace);
      } on Object {
        // The abandoned rename may still hold it: a delete that fails, or
        // does not return, leaves a hidden temp the indexer skips.
      }
    }
  } on Object {
    // The staged copy never becomes the live file: a failure here leaves
    // [abs] holding exactly the bytes it held before (issue #369).
    if (await staged.exists()) {
      try {
        await delete(staged).timeout(grace);
      } on Object {
        // Already gone, or held by the abandoned rename. Nothing to tidy.
      }
    }
    rethrow;
  }
  log.warning('"$name": copied $expected bytes in place');
  try {
    await dropTemp(File(tempAbs)).timeout(_renameGrace);
  } on Object catch (error) {
    log.warning('"$name": the temp could not be removed: $error');
  }
}
