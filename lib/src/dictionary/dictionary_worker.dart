import 'dart:async';
import 'dart:isolate';

import 'package:niman/src/dictionary/dictionary_entry.dart';
import 'package:niman/src/dictionary/dictionary_exception.dart';
import 'package:niman/src/dictionary/dictionary_worker_pack.dart';

/// The isolate that holds the open packs and answers look-ups, for the life
/// of the app (docs/records/dictionary.md, "The engine").
///
/// The UI isolate never touches a pack's files: it sends a message and
/// waits for the answer. The worker opens each pack once (its `.ifo`, its
/// data file, the sidecar index's fences), so a look-up is a few reads, not
/// a start. Same shape as the OCR's worker (`ocr/ocr_worker.dart`), but for
/// many small requests: the replies are matched to their requests by number.
final class DictionaryWorker {
  new _(this._port, this._exit) {
    _port.listen(_receive);
    _exit.listen((_) => _stopped('the dictionary worker stopped'));
  }

  /// Starts the worker and waits until it is ready for requests.
  static Future<DictionaryWorker> start() async {
    final worker = DictionaryWorker._(ReceivePort(), ReceivePort());
    worker._isolate = await Isolate.spawn(
      _run,
      worker._port.sendPort,
      onExit: worker._exit.sendPort,
      debugName: 'dictionary-worker',
    );
    await worker._ready.future;
    return worker;
  }

  late final Isolate _isolate;
  late final SendPort _requests;
  final ReceivePort _port;
  final ReceivePort _exit;

  /// Completes when the isolate has sent the port it takes requests on.
  final Completer<void> _ready = Completer<void>();
  final Map<int, Completer<Object?>> _pending = {};
  int _next = 0;
  bool _closed = false;

  /// Whether the worker has been stopped, or died.
  bool get isClosed => _closed;

  /// Opens the pack [id] in [directory] in the worker. True when it is
  /// open; false when its sidecar index is absent or stale and has to be
  /// built first. Throws [DictionaryException] for a pack that cannot be
  /// read.
  Future<bool> open(String directory, String id) async =>
      (await _ask('open', (directory, id)))! as bool;

  /// The look-up of [candidates] in the open pack [id] (see
  /// `DictionaryWorkerPack.lookUp`).
  Future<PackAnswer> lookUp(
    String id,
    List<String> candidates,
    List<String> prefixBases,
    String language,
  ) async {
    // A list that crossed isolates is not promised its element type.
    final reply = await _ask('lookup', (id, candidates, prefixBases, language));
    final answer =
        reply!
            as ({String? matched, List<dynamic> entries, List<dynamic> hints});
    return (
      matched: answer.matched,
      entries: answer.entries.cast<DictionaryEntry>().toList(),
      suggestions: answer.hints.cast<String>().toList(),
    );
  }

  /// Closes the pack [id], when it is open: its files are released.
  Future<void> closePack(String id) => _ask('close', id);

  /// Closes every open pack and ends the worker, and completes when its
  /// files are released.
  Future<void> shutdown() async {
    if (_closed) return;
    try {
      await _ask('shutdown', null);
    } on DictionaryException {
      // Already gone: nothing is open.
    }
    close();
  }

  /// Stops the worker at once; a look-up in flight fails. Its files are
  /// released when the isolate is collected: [shutdown] releases them first.
  void close() {
    if (_closed) return;
    _stopped('the dictionary worker was closed');
    _isolate.kill(priority: Isolate.immediate);
  }

  Future<Object?> _ask(String command, Object? argument) {
    if (_closed) {
      return Future.error(const DictionaryException('the worker is closed'));
    }
    final id = _next++;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _requests.send((id, command, argument));
    return completer.future;
  }

  void _receive(Object? message) {
    if (message is SendPort) {
      _requests = message;
      _ready.complete();
    } else if (message case (
      final int id,
      final bool ok,
      final Object? value,
    )) {
      final completer = _pending.remove(id);
      if (completer == null) return;
      if (ok) {
        completer.complete(value);
      } else {
        completer.completeError(DictionaryException('$value'));
      }
    }
  }

  void _stopped(String reason) {
    if (_closed) return;
    _closed = true;
    if (!_ready.isCompleted) _ready.completeError(DictionaryException(reason));
    for (final completer in _pending.values) {
      completer.completeError(DictionaryException(reason));
    }
    _pending.clear();
    _port.close();
    _exit.close();
  }
}

/// The worker's isolate: serves requests one at a time, so a pack's files
/// are never read by two look-ups at once.
Future<void> _run(SendPort replies) async {
  final requests = ReceivePort();
  replies.send(requests.sendPort);
  final packs = <String, DictionaryWorkerPack>{};
  await for (final message in requests) {
    final (int id, String command, Object? argument) =
        message as (int, String, Object?);
    try {
      if (command == 'shutdown') {
        for (final pack in packs.values) {
          await pack.close();
        }
        packs.clear();
        replies.send((id, true, null));
        requests.close();
        continue;
      }
      final value = await _handle(packs, command, argument);
      replies.send((id, true, value));
    } on DictionaryException catch (error) {
      replies.send((id, false, error.reason));
    } on Object catch (error) {
      replies.send((id, false, '$error'));
    }
  }
}

Future<Object?> _handle(
  Map<String, DictionaryWorkerPack> packs,
  String command,
  Object? argument,
) async {
  switch (command) {
    case 'open':
      final (String directory, String id) = argument! as (String, String);
      await packs.remove(id)?.close();
      final pack = await DictionaryWorkerPack.open(directory, id);
      if (pack == null) return false;
      packs[id] = pack;
      return true;
    case 'lookup':
      final (
        String id,
        List<dynamic> candidates,
        List<dynamic> bases,
        String lang,
      ) = argument! as (String, List<dynamic>, List<dynamic>, String);
      final pack = packs[id];
      if (pack == null) throw DictionaryException('$id is not open');
      final answer = await pack.lookUp(
        candidates.cast<String>(),
        bases.cast<String>(),
        lang,
      );
      return (
        matched: answer.matched,
        entries: answer.entries,
        hints: answer.suggestions,
      );
    case 'close':
      await packs.remove(argument! as String)?.close();
      return null;
  }
  throw DictionaryException('unknown command $command');
}
