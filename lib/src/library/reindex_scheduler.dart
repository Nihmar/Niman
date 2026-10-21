import 'dart:async';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/read_cancel.dart';

/// Decides when a note the writer saved is read back into the index, and
/// runs the read: the state machine of `NoteWriter`'s reindexes.
///
/// A save completes when the disk holds the text; the index catches up
/// afterwards, and never beside a write of the same note. Per note path it
/// keeps at most one read running, at most one more owed after it, and, for a
/// large note, a wait for the writer to stop saving it.
final class ReindexScheduler {
  /// Creates the scheduler of one writer.
  ///
  /// [chainOf] answers the tail of a note's save chain, or null when the
  /// chain is idle: a note whose chain is busy is never read. [read] reads
  /// the note at library-relative path into the index — an existing note
  /// rescanned under [ReadCancel], a created one added — and answers false
  /// when the read was dropped for the cancel.
  new({
    required this.chainOf,
    required this.read,
    this.quietBeforeReindex = defaultQuietBeforeReindex,
    this.now = DateTime.now,
  });

  /// The clock the reads are timed with: a seam for a test in fake time.
  final DateTime Function() now;

  /// The tail of the save chain of the note at a library-relative path, or
  /// null when it has none running.
  final Future<void>? Function(String path) chainOf;

  /// Reads the note into the index ([ReindexScheduler] constructor).
  final Future<bool> Function(
    String path, {
    required bool created,
    required ReadCancel cancel,
  })
  read;

  /// How long a saved note of so many bytes is left quiet before it is read
  /// into the index again: at once for an ordinary note, and for a large one
  /// only once the writer has stopped saving it.
  ///
  /// A reindex reads the whole note back — digest, tags and links, the
  /// full-text row — and on the 247 MB stress note that is 15 to 34 s of work
  /// for every save; written while the writer types, one reindex ran after
  /// another for as long as they did (device log, 2026-09-23). The index
  /// catches up with the note a little later, and the work is done once. The
  /// thresholds are the save's own debounce (`cee783e`), with a tier for
  /// notes just over a megabyte: a 1.5 MB save took 123 ms, its reindex
  /// 894 ms, and the next save fell inside that reindex and wrote in 480 ms
  /// (device log, 2026-10-20). A write now cancels a read of its note
  /// ([cancelRead]); two seconds after the last save keeps the saves of one
  /// burst of typing from starting, and dropping, a read each, while an
  /// ordinary note still reindexes at once.
  ///
  /// This is the floor of the wait, by size. A note whose reads are slow
  /// waits longer, by what they measured ([quietFor]).
  final Duration Function(int bytes) quietBeforeReindex;

  /// The reads shorter than this are not measured: the editor saves no more
  /// often than every half second (`NoteSavePipeline`'s save delay), and a read
  /// that ends in a quarter of that is over before the next save of a burst
  /// comes to cancel it.
  static const Duration slowRead = Duration(milliseconds: 250);

  /// The longest wait a measured read asks for: the largest of the sizes'
  /// own ([defaultQuietBeforeReindex]).
  static const Duration longestMeasuredWait = Duration(seconds: 30);

  /// [quietBeforeReindex]'s default.
  static Duration defaultQuietBeforeReindex(int bytes) {
    if (bytes > 16 << 20) return const Duration(seconds: 30);
    if (bytes > 2 << 20) return const Duration(seconds: 5);
    if (bytes > 1 << 20) return const Duration(seconds: 2);
    return Duration.zero;
  }

  static const _log = AppLogger(name: 'save');

  /// How long the last read of each note that reads slowly took, by path:
  /// a read the next save cancelled counts for as long as it ran, which is
  /// the least it needed. A note read in less than [slowRead] has no entry,
  /// so the map holds the slow notes alone.
  final Map<String, Duration> _slowReads = <String, Duration>{};

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

  /// The reindexes due while their note's save chain was busy, by path:
  /// whether the note is new to the index. Each runs once the chain is idle
  /// ([settled]), so the note is never read beside a write of it.
  final Map<String, bool> _owed = <String, bool>{};

  /// The read of each reindex still reading its note, by path: a write of
  /// the note asked for meanwhile cancels it ([cancelRead]).
  final Map<String, ReadCancel> _reads = <String, ReadCancel>{};

  /// How long the note at [path], of [bytes] bytes, is left quiet before it
  /// is read into the index: the longer of what its size asks for
  /// ([quietBeforeReindex]) and twice what its last read took, up to
  /// [longestMeasuredWait].
  ///
  /// The size is a guess; a tablet read a 0.6 to 1 MB note in 400 to 600 ms
  /// against a save every 500 ms, so each save cancelled the read that the
  /// one before it started and the index stayed on the old text for as long
  /// as the typing went on (#1137 review). Twice the time the read took is
  /// what it needs to end unbroken, with the same again for a slower turn
  /// of the disk. The read is timed as the scheduler sees it, from asking
  /// the indexer to its answer, so the indexer's queue counts too: a long
  /// queue ahead of the note is a reason to read it less often as well.
  Duration quietFor(String path, int bytes) {
    final bySize = quietBeforeReindex(bytes);
    final last = _slowReads[path];
    if (last == null) return bySize;
    final measured = last * 2;
    final capped = measured > longestMeasuredWait
        ? longestMeasuredWait
        : measured;
    return capped > bySize ? capped : bySize;
  }

  /// Remembers how long the read of [path] ran, if it was slow.
  void _measure(String path, Duration ran, {required bool finished}) {
    if (ran < slowRead) {
      if (finished) _slowReads.remove(path);
      return;
    }
    final before = _slowReads[path];
    _slowReads[path] = finished || before == null || ran > before
        ? ran
        : before;
  }

  /// Whether the note at [path] waits for a reindex this scheduler will run
  /// once it is left alone, or once its saves end: the scans that are not
  /// the writer's leave it be meanwhile (`Indexer.awaitedByWriter`).
  bool awaits(String path) =>
      _quiet.containsKey(path) || _owed.containsKey(path);

  /// A write of the note at [path] is asked for: a reindex of it still
  /// reading it is cancelled, as what the read finds is already old, and
  /// reading beside the write is what made a 1.5 MB save take 480 ms against
  /// 123 on a tablet (device log, 2026-10-20). The note is read again once
  /// its chain is idle, or quiet.
  ///
  /// Answers when the cancelled read holds no file of the note any more: it
  /// stops at its next safe point, not at once (`ReadCancel.released`), and
  /// the write about to swap the note in must wait for that — on Windows a
  /// file another handle holds open cannot be replaced. Only the read of the
  /// file is waited for, never the parse: a read in its parse holds nothing.
  Future<void> cancelRead(String path) {
    final cancel = _reads.remove(path);
    if (cancel == null) return Future<void>.value();
    cancel.cancel();
    return cancel.released;
  }

  /// [path]'s save chain is idle: the reindex it owes runs now — unless a
  /// save left the note waiting to be quiet, whose timer runs it. A note new
  /// to the index does not wait: until it is read it has no row at all.
  void settled(String path) {
    final created = _owed.remove(path);
    if (created == null) return;
    if (!created && _quiet.containsKey(path)) return;
    _quiet.remove(path)?.cancel();
    reindex(path, created: created);
  }

  /// Completes when every re-index started so far has finished.
  ///
  /// One still waiting for its note to be quiet runs now, and one owed to a
  /// note whose saves are still running runs once they end: whoever asks
  /// wants the index as the disk has it.
  Future<void> get indexed async {
    while (true) {
      for (final path in _quiet.keys.toList()) {
        _quiet.remove(path)?.cancel();
        reindex(path, created: false);
      }
      final pending = <Future<void>>[
        ..._indexing,
        for (final path in _owed.keys) ?chainOf(path),
      ];
      if (pending.isEmpty) return;
      await Future.wait(pending);
    }
  }

  /// Reindexes [path] once it has been left alone for
  /// [quietBeforeReindex] — each save of it starting the wait again. A new
  /// note has no row yet and is indexed at once.
  void whenQuiet(String path, {required bool created, required int bytes}) {
    _quiet.remove(path)?.cancel();
    final wait = created ? Duration.zero : quietFor(path, bytes);
    if (wait == Duration.zero) {
      reindex(path, created: created);
      return;
    }
    _log.debug(
      'reindex of "$path" in ${wait.inMilliseconds} ms, if left alone',
    );
    _quiet[path] = Timer(wait, () {
      _quiet.remove(path);
      reindex(path, created: false);
    });
  }

  /// Reindexes [path] as soon as its save chain is idle, whatever wait an
  /// earlier save left it: for a change that is no part of the editor's
  /// burst of typing — a note replaced by a sync download or from outside —
  /// whose text the wait would only keep out of the index.
  void reindexNow(String path, {required bool created}) {
    _quiet.remove(path)?.cancel();
    reindex(path, created: created);
  }

  /// Re-reads the saved note into the index, after the save completed.
  ///
  /// An existing note is rescanned, not passed through the (size, mtime)
  /// shortcut of `applyEvents`: an edit that keeps the size inside the
  /// same second (one letter swapped for another) would otherwise read as
  /// "nothing happened". A new file has no row to rescan, so it goes
  /// through `applyEvents`, which creates it.
  ///
  /// Never beside a write of the note: while its save chain is busy the
  /// reindex is owed, and runs once the chain is idle ([settled]). A write
  /// asked for while it reads cancels it ([cancelRead]); it is owed again
  /// then.
  void reindex(String path, {required bool created}) {
    if (chainOf(path) != null) {
      _owed[path] = (_owed[path] ?? false) || created;
      return;
    }
    if (_reindexing.contains(path)) {
      _reindexAgain.add(path);
      return;
    }
    _reindexing.add(path);
    final started = now();
    late final Future<void> job;
    final cancel = ReadCancel();
    if (!created) _reads[path] = cancel;
    var dropped = false;
    job = read(path, created: created, cancel: cancel)
        .then((done) {
          dropped = !done;
          final ran = now().difference(started);
          if (!created) _measure(path, ran, finished: done);
          _log.debug(
            '${done ? 'reindexed' : 'reindex dropped, saved again'}: '
            '"$path" (${ran.inMilliseconds} ms)',
          );
        }, onError: (Object e) => _log.warning('reindex failed: "$path": $e'))
        .whenComplete(() {
          _indexing.remove(job);
          _reindexing.remove(path);
          if (identical(_reads[path], cancel)) _reads.remove(path);
          // Saved again while this one ran, or dropped for a save: once
          // more, for what the disk holds now — unless a save left the
          // note waiting to be quiet, whose timer runs it. A save that
          // failed or was abandoned leaves no timer, and the note is
          // still owed the read this one did not finish.
          final again = _reindexAgain.remove(path) || dropped;
          if (again && !_quiet.containsKey(path)) {
            reindex(path, created: false);
          }
        });
    _indexing.add(job);
  }
}
