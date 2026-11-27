/// Saves a note whose text is never held whole: the editor encodes its
/// buffer in slices and hands them over as they are made, and the isolate
/// that owns the file writes them down as they arrive.
///
/// **Why.** The save used to join the note into one string, copy that
/// string to the writing isolate — strings are copied between isolates,
/// never shared — encode it and write it in one go. On the 246 MB note of
/// the 0.0.9 stress test that is 300–530 ms of the UI isolate's own work
/// per save (see `docs/records/huge-notes.md`), a stall the debounce only
/// moves to a pause. Here the join and the encode happen a slice at a
/// time, each slice short enough that the frames keep coming, and the
/// bytes leave for the writer as they are made, so no full copy of the
/// note exists at any point of the save.
///
/// **Backpressure.** The writer answers each slice once the file has taken
/// it, and the producer sends no more than [kSlicesInFlight] ahead of those
/// answers, so a slow disk never turns the whole note into queued bytes.
///
/// **What it does not do.** It does not read the note back, index it or
/// version it: [saveNoteStream] takes the same history step and leaves the
/// same bytes in place as [writeNoteFile] does, and the caller's reindex
/// follows as before.
///
/// **The port rule.** Every message this file sends between isolates
/// carries at most one port. A spawn message with two of them starts an
/// isolate whose ports then deliver nothing at all — the writer announces
/// itself and hears no reply, with no error anywhere (measured on the VM
/// this app runs on, 2026-09-22). So the writer is handed one port, where
/// it announces the port it made for itself; the main isolate answers on
/// that one, and sends the port its result goes to as the first message of
/// the conversation that follows.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:niman/src/library/note_writer_blocking.dart';
import 'package:path/path.dart' as p;

/// One slice of a note, encoded and ready for the file.
///
/// A slice, not the note: the producer makes one, hands it over and forgets
/// it, so the memory a save needs is the size of its largest slice rather
/// than the size of the note.
typedef NoteBytes = Uint8List;

/// Makes the note's bytes, one slice at a time.
///
/// Called with `0`, `1`, … until it answers null, which says the note is
/// complete. What it answers with is bytes and nothing else, so a caller
/// building them from strings has already done the encoding. Slices are
/// written in the order they are made.
typedef NoteContentProducer = Future<NoteBytes?> Function(int index);

/// How many slices a streaming save sends before the writer has written the
/// first of them. A slice is at most 16 384 lines, so this bounds what waits
/// in the writer's queue to a few megabytes of a note of ordinary lines.
const int kSlicesInFlight = 4;

/// Answers `true` when a save has to stop where it is: the note's buffer
/// moved under the producer, so what it would write next no longer follows
/// what it wrote before.
typedef NoteSaveAbort = bool Function();

/// What a save tells the writing isolate before its slices: which note,
/// where, and whether the text it replaces is kept as a version.
///
/// Every field is a plain value: no port rides here (see the port rule at
/// the top of this file).
typedef NoteStreamStart = ({
  String abs,
  String rel,
  String root,
  SnapshotRequest? snapshot,
  Duration writeDelay,
});

/// What the writing isolate is told first: the port it announces itself on,
/// and the note it is about to be sent.
typedef NoteStreamSpawn = ({SendPort ready, NoteStreamStart start});

/// The first message of a save's conversation: where its result goes.
///
/// The note itself travels with the spawn ([NoteStreamStart]); this
/// is the one thing the writer cannot know before the main isolate picks
/// up its port, and it is a message of its own because two ports in one
/// message would not deliver (see the port rule above).
typedef NoteStreamTalk = ({SendPort answers});

/// Saves the note at [root]-relative [rel] with the bytes [produce] makes,
/// and reports what the write cost — the streaming twin of
/// [writeNoteOffIsolate]. Answers null when [abort] stopped the save.
///
/// [snapshot] is the history decision for this save, already made by the
/// caller's writer ([NoteWriter] asks the history once per save); the text
/// it replaces is read and kept inside the writing isolate, from the disk,
/// exactly as the joined path does.
///
/// The writer acknowledges every slice it has written, and the producer keeps
/// at most [maxInFlight] slices sent and not yet acknowledged: on a slow disk
/// (an SD card, a network share) the slices would otherwise all queue as
/// bytes in the writer's port — the full copy of the note this save exists
/// to avoid (#1369).
///
/// Throws when the isolate cannot be started, the write fails, or the
/// producer does; the temp file is gone either way, and the note still
/// holds what it held.
///
/// [spawnWriter] starts the writer in place of a new isolate, and answers the
/// isolate it made, if any: a test runs [runNoteStreamWriter] on its own
/// isolate, under the I/O overrides of its own zone, which a spawned isolate
/// never inherits.
Future<NoteWriteResult?> saveNoteStream({
  required String root,
  required String rel,
  required NoteContentProducer produce,
  SnapshotRequest? snapshot,
  NoteSaveAbort? abort,
  int maxInFlight = kSlicesInFlight,
  @visibleForTesting
  Future<Isolate?> Function(NoteStreamSpawn spawn)? spawnWriter,
  @visibleForTesting Duration writeDelay = Duration.zero,
}) async {
  final abs = p.join(root, rel);
  final start = (
    abs: abs,
    rel: rel,
    root: root,
    snapshot: snapshot,
    writeDelay: writeDelay,
  );
  // The producer stays on this isolate: it reads the editor's own buffer — a
  // closure over state no isolate can take — and awaiting it here is also
  // what hands the frames their gap between one slice and the next.
  final ready = ReceivePort();
  final writer = Completer<SendPort>();
  final answers = ReceivePort();
  final answer = Completer<NoteWriteResult?>();
  ready.listen((message) {
    // One message only: the port the writer talks on. The save's result
    // comes back on [answers] — a port that answers itself answers nobody.
    if (message is SendPort && !writer.isCompleted) writer.complete(message);
  });
  // What the writer has written, as a count of slices: the producer's room.
  var written = 0;
  Completer<void>? room;
  answers.listen((message) {
    if (message is int) {
      written = message;
      room?.complete();
      room = null;
      return;
    }
    _settle(answer, message);
  });
  // A failure the writer reports ends the wait for room as well.
  final ended = answer.future.then<void>((_) {}, onError: (Object _) {});
  final job = IsolateGauge.begin('stream "$rel"');
  final spawn = (ready: ready.sendPort, start: start);
  final isolate =
      await (spawnWriter?.call(spawn) ?? Isolate.spawn(_streamWriter, spawn));
  SendPort? talk;
  try {
    // The first message of the conversation: where the save's result goes.
    talk = (await writer.future)..send((answers: answers.sendPort));
    var index = 0;
    var sent = 0;
    while (true) {
      // Not another slice while the writer is behind by [maxInFlight]: one
      // made now would only wait in its queue, as bytes.
      while (sent - written >= maxInFlight && !answer.isCompleted) {
        await Future.any([(room ??= Completer<void>()).future, ended]);
      }
      // The writer failed, or ended the conversation: its answer is the
      // save's, and the producer has nothing more to hand over.
      if (answer.isCompleted) return await answer.future;
      final slice = await produce(index++);
      if (slice == null) break;
      if (abort?.call() ?? false) {
        // The producer never yields, so this is the only place an edit can
        // have landed. The note's end is not sent: the writer takes the
        // conversation as abandoned, drops the temp file and answers null,
        // so the note keeps what it held and the caller's next save writes
        // the note as it then stands.
        return await _endTalk(talk, answer);
      }
      if (slice.isNotEmpty) {
        talk.send(slice);
        sent++;
      }
    }
    // The end of the note, then the end of the conversation: the writer
    // answers the first with the save's result and the second by closing,
    // so a slice still in the port's queue is never missed.
    talk
      ..send(null)
      ..send(const _Finished());
    return await answer.future;
  } on Object {
    // The producer or the port failed, and that error is the caller's: it
    // is rethrown once the writer has been dealt with. If it ever got the
    // note it may hold a temp file, so it is told the conversation is over
    // and waited out before the isolate goes — killing it first leaves that
    // file behind. Nothing was started when there is no port yet.
    await _abandon(talk: talk, answer: answer);
    rethrow;
  } finally {
    isolate?.kill(priority: Isolate.immediate);
    IsolateGauge.finishJob(job);
    ready.close();
    answers.close();
  }
}

/// Ends a save the caller abandoned mid-note (the `abort` it may pass), and
/// answers what the writer reported — null, because nothing was written.
Future<NoteWriteResult?> _endTalk(
  SendPort talk,
  Completer<NoteWriteResult?> answer,
) {
  talk.send(const _Finished());
  return answer.future;
}

/// Tells the writer the conversation is over and waits for it to tidy up.
///
/// Either side's failure is swallowed: the caller has one of its own to
/// report, and this only has to wait for the temp file to be gone. Nothing
/// is sent when [talk] is null — the writer never heard the note, so it has
/// no temp file to drop and no save to wait for.
Future<void> _abandon({
  required SendPort? talk,
  required Completer<NoteWriteResult?> answer,
}) async {
  if (talk == null) return;
  talk.send(const _Finished());
  try {
    await answer.future;
  } on Object {
    // The writer's own failure is not what the caller needs to hear: it has
    // the producer's.
  }
}

/// Completes [answer] with what the writer reported: the save's result, the
/// abandoned save it was told to make, or the failure it hit.
void _settle(Completer<NoteWriteResult?> answer, Object? message) {
  if (answer.isCompleted) return;
  if (message is NoteWriteResult) {
    answer.complete(message);
    return;
  }
  if (message == null) {
    // The save was abandoned: nothing was left on disk.
    answer.complete(null);
    return;
  }
  if (message is (Object, StackTrace)) {
    answer.completeError(message.$1, message.$2);
  }
}

/// Receives the one digest a chunked hash makes, when it is closed.
final class _DigestSink implements Sink<Digest> {
  new(this._take);

  final void Function(Digest digest) _take;

  @override
  void add(Digest data) => _take(data);

  @override
  void close() {}
}

/// Told to the writer when the conversation is over: with the note already
/// ended, the save is renamed into place; without it, the save is abandoned
/// and its temp file goes.
final class _Finished {
  const new();
}

/// The writing isolate: announces the port it answers on, then opens the
/// temp file, writes every slice down as it arrives, and renames the
/// finished file over the note when it is told the note is done.
///
/// One subscription on one port carries the conversation — the port the
/// result goes to, the slices, the end. A port is a single-subscription
/// stream, so all three have to be taken by the same listener.
///
/// Everything in here is off the UI isolate, which is the point: the temp
/// file's name, the target's stat and the rename are work a frame must not
/// wait for.
void _streamWriter(NoteStreamSpawn spawn) {
  final talk = ReceivePort();
  final conversation = _Conversation(spawn.start);
  talk.listen(
    conversation.take,
    onError: conversation.fail,
    onDone: conversation.end,
  );
  // The one port: announced after the listener is on it, so nothing sent
  // back is missed.
  spawn.ready.send(talk.sendPort);
  unawaited(conversation.over);
}

/// [_streamWriter] on the calling isolate, for a test (see `spawnWriter`).
@visibleForTesting
void runNoteStreamWriter(NoteStreamSpawn spawn) => _streamWriter(spawn);

/// One save's conversation with the main isolate: where the result goes,
/// the slices, and the end of the note.
final class _Conversation {
  /// Is about [_start], and has nowhere to answer yet.
  new(this._start);

  /// What the save is about.
  final NoteStreamStart _start;

  /// Where the result goes, sent by the main isolate as the first message;
  /// null until then. Answering has to wait for it: the port this isolate
  /// reads from is its own, and a result sent there comes back to the
  /// writer rather than to the caller.
  SendPort? _answers;

  /// The note is over, or the failure that stopped it early.
  final Completer<void> _over = Completer<void>();

  /// When the save is over, however it ended.
  Future<void> get over => _over.future;

  /// Slices received and not yet written. The first message and the first
  /// slice can be in the port's queue together, before the temp file is open.
  final Queue<NoteBytes> _queue = Queue<NoteBytes>();
  bool _pumping = false;
  Completer<void>? _idle;

  IOSink? _sink;
  int _written = 0;
  File? _temp;
  bool _created = false;
  int _bytes = 0;
  Object? _failure;
  StackTrace? _stack;

  /// Whether the end of the note was the caller's own: a null on the port.
  /// A conversation that just ends leaves the save abandoned, and the note
  /// keeps the text it had.
  bool _endedWithNull = false;

  /// Whether the note's first message has arrived.
  bool started = false;

  /// One message of the conversation: where to answer, a slice, or the end.
  void take(Object? message) {
    if (message is _Finished) {
      if (!_over.isCompleted) _over.complete();
      return;
    }
    if (!started) {
      started = true;
      if (message is! NoteStreamTalk) {
        fail(
          StateError('the writer was started with "$message"'),
          StackTrace.current,
        );
        return;
      }
      _answers = message.answers;
      unawaited(_write());
      return;
    }
    if (message == null) {
      _endedWithNull = true;
      if (!_over.isCompleted) _over.complete();
      return;
    }
    if (message is! NoteBytes) {
      fail(
        StateError('a save slice was a ${message.runtimeType}'),
        StackTrace.current,
      );
      return;
    }
    _queue.add(message);
    if (_sink != null) unawaited(_pump());
  }

  /// Writes the queued slices to the temp file, one at a time, and says after
  /// each that the file has taken it: the producer waits for these answers
  /// before it sends more (#1369). A flush answers once the sink has written
  /// what it was given, and a sink cannot take more while one is pending, so
  /// the slices wait here, in order, instead.
  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (_queue.isNotEmpty && _failure == null) {
        final slice = _queue.removeFirst();
        if (_start.writeDelay > Duration.zero) sleep(_start.writeDelay);
        _sink!.add(slice);
        _digest.add(slice);
        _bytes += slice.length;
        await _sink!.flush();
        _answers?.send(++_written);
      }
    } on Object catch (error, stack) {
      fail(error, stack);
    } finally {
      _pumping = false;
      final idle = _idle;
      _idle = null;
      idle?.complete();
    }
  }

  /// Completes once the queued slices are on the file.
  Future<void> _drained() {
    if (!_pumping && _queue.isEmpty) return Future<void>.value();
    if (!_pumping) {
      unawaited(_pump());
    }
    return (_idle ??= Completer<void>()).future;
  }

  /// The digest of the slices written, made as they are: the reindex behind
  /// the save takes it rather than reading the note back to hash it.
  late final ByteConversionSink _digest = sha256.startChunkedConversion(
    _DigestSink((digest) => _digested = digest),
  );

  /// What [_digest] made, once it is closed.
  late final Digest _digested;

  /// The port closed: whoever was sending the slices has finished with it,
  /// and nothing more follows.
  void end() {
    if (!_over.isCompleted) _over.complete();
  }

  /// Something went wrong; the save reports it rather than writing half a
  /// note.
  void fail(Object error, StackTrace stack) {
    if (_failure != null) return;
    _failure = error;
    _stack = stack;
    if (!_over.isCompleted) _over.complete();
  }

  /// Writes the note: the snapshot, the slices, the rename.
  ///
  /// The file work is synchronous on purpose: this is the writing isolate,
  /// where blocking the event loop costs a frame nothing, and a long-lived
  /// spawned isolate that awaits its file work does not finish it under
  /// `flutter test` — the same awaits complete in a plain `dart run`
  /// isolate, and this one sits on the first of them until the test times
  /// out (measured 2026-09-22).
  Future<void> _write() async {
    final start = _start;
    SnapshotOutcome? outcome;
    String? snapshotError;
    final snapshot = start.snapshot;
    if (snapshot != null) {
      try {
        outcome = snapshotBeforeWrite(start.root, start.rel, snapshot);
      } on Object catch (error) {
        snapshotError = '$error';
      }
    }
    final clock = Stopwatch()..start();
    try {
      final file = File(start.abs);
      _created = !file.existsSync();
      if (_created) file.parent.createSync(recursive: true);
      // The file as it is when the slices start: the rename at the end is
      // the moment to ask whether somebody else wrote it since (#1333).
      final before = DiskStamp.of(start.abs);
      final temp = atomicTempPath(file, DateTime.now().microsecondsSinceEpoch);
      _sink = temp.openWrite();
      _temp = temp;
      unawaited(_pump());
      await _over.future;
      await _drained();
      final failure = _failure;
      if (failure != null) {
        Error.throwWithStackTrace(failure, _stack ?? StackTrace.current);
      }
      await _sink?.close();
      _sink = null;
      if (!_endedWithNull) {
        // The caller stopped sending: the save is abandoned, and an
        // abandoned save must not become the note. The temp goes.
        _temp = null;
        if (temp.existsSync()) await temp.delete();
        _answers?.send(null);
        return;
      }
      // A note this save takes seconds to write — minutes, over a slow disk —
      // can be rewritten by another program meanwhile, and the check made at
      // the start did not see it: the file about to be replaced is looked at
      // again, and kept as the outside version when it is not the one the
      // slices began against (#1333).
      outcome = _keepOutsideWrite(before, outcome) ?? outcome;
      // Flushed to storage, then renamed over the note: the same last step
      // as every other atomic write (#1058).
      final stamp = await publishTempFile(temp, start.abs);
      _temp = null;
      _digest.close();
      _answers!.send((
        bytes: _bytes,
        created: _created,
        encodeMs: 0,
        writeMs: clock.elapsedMilliseconds,
        snapshot: outcome,
        snapshotError: snapshotError,
        sha256: _digested.toString(),
        // The temp file's stamp, not the renamed-over path's — see
        // [publishTempFile]: on Android the path's stat can still answer the
        // replaced file's attributes, and a save that stored them reported
        // its own next write as another program's (#1055).
        modified: stamp?.modified ?? File(start.abs).statSync().modified,
      ));
    } on Object catch (error, stack) {
      try {
        await _sink?.close();
      } on Object {
        // The sink is being abandoned anyway.
      }
      try {
        final temp = _temp;
        if (temp != null && temp.existsSync()) await temp.delete();
      } on Object {
        // A temp that will not delete is hidden, and indexed by nobody.
      }
      _answers?.send((error, stack));
    } finally {
      _sink = null;
      _temp = null;
    }
  }

  /// Keeps the version of the note another program wrote while the slices
  /// were being written, when there is one: the file now is not the file
  /// the save began against ([before]).
  ///
  /// Answers the snapshot's outcome when it took a version, so the save
  /// reports an outside change as one made before the slices would have.
  /// Null when nothing changed, when the file is gone (nothing to keep), when
  /// the save keeps no history, or when the snapshot failed — that one is
  /// logged by the caller's report and must not stop the save.
  SnapshotOutcome? _keepOutsideWrite(
    DiskStamp? before,
    SnapshotOutcome? outcome,
  ) {
    final asked = _start.snapshot;
    if (asked == null) return null;
    final now = DiskStamp.of(_start.abs);
    if (now == null || (before?.sameAs(now) ?? false)) return null;
    try {
      final kept = snapshotBeforeWrite(
        _start.root,
        _start.rel,
        SnapshotRequest(
          limit: asked.limit < 1 ? 1 : asked.limit,
          interval: asked.interval,
          now: asked.now,
          forced: HistoryReason.external,
        ),
      );
      return kept.version == null ? null : kept;
    } on Object {
      return null;
    }
  }
}
