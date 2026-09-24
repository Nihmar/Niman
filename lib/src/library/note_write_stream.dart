/// Saves a note whose text is never held whole: the editor encodes its
/// buffer in slices and hands them over as they are made, and the isolate
/// that owns the file writes them down as they arrive.
///
/// **Why.** The save used to join the note into one string, copy that
/// string to the writing isolate — strings are copied between isolates,
/// never shared — encode it and write it in one go. On the 246 MB note of
/// the 0.0.9 stress test that is 300–530 ms of the UI isolate's own work
/// per save (see `docs/dev/huge-notes.md`), a stall the debounce only
/// moves to a pause. Here the join and the encode happen a slice at a
/// time, each slice short enough that the frames keep coming, and the
/// bytes leave for the writer as they are made, so no full copy of the
/// note exists at any point of the save.
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
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:niman/src/library/note_writer.dart';
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
/// Throws when the isolate cannot be started, the write fails, or the
/// producer does; the temp file is gone either way, and the note still
/// holds what it held.
Future<NoteWriteResult?> saveNoteStream({
  required String root,
  required String rel,
  required NoteContentProducer produce,
  SnapshotRequest? snapshot,
  NoteSaveAbort? abort,
}) async {
  final abs = p.join(root, rel);
  final start = (abs: abs, rel: rel, root: root, snapshot: snapshot);
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
  answers.listen((message) => _settle(answer, message));
  final job = IsolateGauge.begin('stream "$rel"');
  final isolate = await Isolate.spawn(_streamWriter, (
    ready: ready.sendPort,
    start: start,
  ));
  SendPort? talk;
  try {
    // The first message of the conversation: where the save's result goes.
    talk = (await writer.future)..send((answers: answers.sendPort));
    var index = 0;
    while (true) {
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
      if (slice.isNotEmpty) talk.send(slice);
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
    isolate.kill(priority: Isolate.immediate);
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

  /// Slices that arrived before the temp file was open — the first message
  /// and the first slice can be in the port's queue together.
  final List<NoteBytes> _early = <NoteBytes>[];

  IOSink? _sink;
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
    final sink = _sink;
    if (sink == null) {
      _early.add(message);
      return;
    }
    sink.add(message);
    _digest.add(message);
    _bytes += message.length;
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
      final temp = atomicTempPath(file, DateTime.now().microsecondsSinceEpoch);
      final sink = temp.openWrite();
      _temp = temp;
      _sink = sink;
      for (final slice in _early) {
        sink.add(slice);
        _digest.add(slice);
        _bytes += slice.length;
      }
      _early.clear();
      await _over.future;
      final failure = _failure;
      if (failure != null) {
        Error.throwWithStackTrace(failure, _stack ?? StackTrace.current);
      }
      await sink.close();
      _sink = null;
      if (!_endedWithNull) {
        // The caller stopped sending: the save is abandoned, and an
        // abandoned save must not become the note. The temp goes.
        _temp = null;
        if (temp.existsSync()) await temp.delete();
        _answers?.send(null);
        return;
      }
      await temp.rename(start.abs);
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
        modified: File(start.abs).statSync().modified,
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
}
