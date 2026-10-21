/// The content read that a [ReadCancel] can stop: its isolate reads the
/// bytes of the batch first, and only then may be killed.
///
/// An isolate killed while a file is open leaves it open — it runs no
/// `finally` — until a garbage collection closes it, and on Windows an open
/// file can be neither deleted nor replaced: the save that cancels the read
/// of a note is the one that then fails to swap the note in. So the read has
/// two phases:
///
///  * **reading**: the isolate reads every file of the batch and holds the
///    bytes. It is never killed here. A cancel sends it a stop, which it
///    sees between two files (the event loop turns at every read), closes
///    nothing it has not closed already, and exits empty.
///  * **parsing**: it has told the spawner it holds no file. Here a cancel
///    kills it at once — the parse of a 1.5 MB note is the 894 ms the save
///    must not wait for, and the kill cuts it — since there is nothing left
///    to leak.
library;

import 'dart:async';
import 'dart:isolate';

import 'package:niman/src/db/index_note_content.dart';
import 'package:niman/src/db/read_cancel.dart';

/// What the reader says when its files are read and closed.
enum _Reader { parsing }

/// What [_readEntry] is spawned with.
typedef _ReadRequest = ({
  SendPort answers,
  String root,
  List<String> batch,
  SendPort? progress,
  Map<String, KnownContent> known,
});

/// Reads and parses [batch] on an isolate of its own, which [cancel] stops
/// (see the library comment); answers empty when it is stopped.
Future<List<NoteContent>> readNoteContentsKillable(
  String root,
  List<String> batch,
  SendPort? progress,
  Map<String, KnownContent> known,
  ReadCancel cancel,
) async {
  if (cancel.isCancelled) return const [];
  final release = cancel.holdFiles();
  final answers = ReceivePort();
  final done = Completer<List<NoteContent>>();
  Isolate? isolate;
  SendPort? control;
  var parsing = false;

  // Acts on a cancel: kills the reader if it holds no file, otherwise asks
  // it to stop between two files (as soon as its control port is known).
  void stop() {
    if (done.isCompleted) return;
    if (parsing) {
      final reader = isolate;
      if (reader == null) return; // killed as soon as it is spawned, below
      reader.kill(priority: Isolate.immediate);
      done.complete(const []);
    } else {
      control?.send(null);
    }
  }

  answers.listen((message) {
    if (message is SendPort) {
      control = message;
      if (cancel.isCancelled) stop();
      return;
    }
    if (message == _Reader.parsing) {
      parsing = true;
      release();
      cancel.onParsing?.call();
      if (cancel.isCancelled) stop();
      return;
    }
    // Anything else ends the reader: no file is open past this point.
    release();
    if (done.isCompleted) return;
    if (message is List<NoteContent>) {
      done.complete(message);
    } else if (message is List && message.length == 2) {
      // What `onError` sends: the error and its stack, as text.
      done.completeError(RemoteError('${message[0]}', '${message[1]}'));
    } else {
      // `onExit` with no answer before it: the isolate went away.
      done.completeError(StateError('the note reader exited unanswered'));
    }
  });
  try {
    isolate = await Isolate.spawn(
      _readEntry,
      (
        answers: answers.sendPort,
        root: root,
        batch: batch,
        progress: progress,
        known: known,
      ),
      onError: answers.sendPort,
      onExit: answers.sendPort,
    );
    if (parsing && cancel.isCancelled) stop();
    unawaited(cancel.whenCancelled.then((_) => stop()));
    return await done.future;
  } finally {
    release();
    answers.close();
  }
}

/// The reader's isolate: reads the batch, says it holds no file, parses it
/// and exits with the contents, so they pass to the spawner without a copy.
///
/// Stopped while it reads (its control port hears the spawner's cancel) it
/// exits empty before the next file.
Future<void> _readEntry(_ReadRequest request) async {
  final control = ReceivePort();
  var stopped = false;
  control.listen((_) => stopped = true);
  request.answers.send(control.sendPort);

  final raws = <RawNote?>[];
  for (final rel in request.batch) {
    if (stopped) break;
    // Posted before the read, so what the screen names is the note being
    // worked on rather than the one just finished.
    request.progress?.send(rel);
    raws.add(await readRawNote(request.root, rel, request.known[rel]));
  }
  // A stop that arrived with the last read, before its turn of the loop.
  await Future<void>.delayed(Duration.zero);
  if (stopped) Isolate.exit(request.answers, const <NoteContent>[]);

  control.close();
  request.answers.send(_Reader.parsing);
  final out = <NoteContent>[];
  for (var i = 0; i < raws.length; i++) {
    final raw = raws[i];
    // Let go of the bytes as the text takes their place.
    raws[i] = null;
    if (raw != null) out.add(parseRawNote(raw));
  }
  Isolate.exit(request.answers, out);
}
