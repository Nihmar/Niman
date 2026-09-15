import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:path/path.dart' as p;

/// Saves note text to disk: the one write path the editor goes through.
///
/// Saves of the same note run one after another; saves of different notes
/// never wait on each other, nor on the structural ops `NoteOps` chains
/// (a large empty-trash must not hold up typing). The write itself runs
/// off the UI isolate. The index catches up after each write without the
/// caller waiting on it: a save completes when the disk holds the text.
final class NoteWriter {
  /// Creates the writer for the library at [root], re-indexing each saved
  /// note through [indexer].
  new({required this.root, required this.indexer});

  /// Absolute path of the library root.
  final String root;

  /// The shared indexer the saved notes are re-read into.
  final Indexer indexer;

  static const _log = AppLogger(name: 'save');

  /// The tail of each note's save chain, by library-relative path.
  final Map<String, Future<void>> _tails = {};

  /// Re-index jobs not finished yet.
  final Set<Future<void>> _indexing = {};

  /// Writes [content] to the note at library-relative [path], creating
  /// the file when it is not there.
  ///
  /// [editSession] identifies the editor session the save comes from (a
  /// note opened once, however many autosaves follow); it is logged, and
  /// the history snapshot rule keys on it.
  Future<void> save(String path, String content, {int? editSession}) {
    final queuedAt = Stopwatch()..start();
    final previous = _tails[path] ?? Future<void>.value();
    final run = previous
        .then<void>((_) {}, onError: (Object _) {})
        .then((_) => _write(path, content, editSession, queuedAt));
    final tail = run.then<void>((_) {}, onError: (Object _) {});
    _tails[path] = tail;
    unawaited(
      tail.whenComplete(() {
        if (identical(_tails[path], tail)) _tails.remove(path)?.ignore();
      }),
    );
    return run;
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
    Stopwatch queuedAt,
  ) async {
    final waitMs = queuedAt.elapsedMilliseconds;
    final abs = p.join(root, path);
    final session = editSession == null ? '' : ', session $editSession';
    _log.debug(
      'save start: "$path" (${content.length} chars$session, '
      'waited $waitMs ms)',
    );
    final NoteWriteResult result;
    try {
      result = await writeNoteOffIsolate(abs, content);
    } catch (e) {
      _log.error('save failed: "$path": $e');
      rethrow;
    }
    _log.info(
      'saved: "$path" (${result.bytes} bytes, '
      '${result.created ? 'new file, ' : ''}'
      'encode ${result.encodeMs} ms, write ${result.writeMs} ms, '
      'total ${queuedAt.elapsedMilliseconds} ms)',
    );
    _reindex(path, abs, created: result.created);
  }

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
/// and where the time went.
typedef NoteWriteResult = ({
  int bytes,
  bool created,
  int encodeMs,
  int writeMs,
});

/// Runs [writeNoteFile] on a short-lived isolate.
///
/// Top-level, so the closure's context holds the two strings and never a
/// caller's state (a future chain cannot cross an isolate boundary).
Future<NoteWriteResult> writeNoteOffIsolate(String abs, String content) =>
    Isolate.run(() => writeNoteFile(abs, content));

/// Encodes [content] and writes it atomically to [abs], creating missing
/// folders.
///
/// Top-level so [Isolate.run] can take it: the message carries two
/// strings and nothing else.
Future<NoteWriteResult> writeNoteFile(String abs, String content) async {
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
  );
}
