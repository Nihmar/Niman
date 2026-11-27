import 'dart:async';
import 'dart:isolate';

import 'package:niman/src/dictionary/dictionary_exception.dart';
import 'package:niman/src/dictionary/dictionary_index_builder.dart';

/// Builds the sidecar index of the pack [id] in [directory] on an isolate
/// of its own and completes when the file is published.
///
/// The build reads the pack's files and sorts every key in memory: seconds
/// of work for an English pack, none of it on the UI isolate. [onProgress]
/// gets 0..1 as it goes. Throws [DictionaryException] when the pack cannot
/// be indexed.
Future<void> buildDictionaryIndexOnIsolate({
  required String directory,
  required String id,
  void Function(double fraction)? onProgress,
}) async {
  final messages = ReceivePort();
  final exits = ReceivePort();
  final done = Completer<void>();
  final subscription = messages.listen((message) {
    switch (message) {
      case final double fraction:
        onProgress?.call(fraction);
      case final String reason:
        if (!done.isCompleted) done.completeError(DictionaryException(reason));
      case null:
        if (!done.isCompleted) done.complete();
    }
  });
  final exitSubscription = exits.listen((_) {
    if (!done.isCompleted) {
      done.completeError(const DictionaryException('the index build stopped'));
    }
  });
  try {
    await Isolate.spawn(
      _run,
      (messages.sendPort, directory, id),
      onExit: exits.sendPort,
      debugName: 'dictionary-index',
    );
    await done.future;
  } finally {
    await subscription.cancel();
    await exitSubscription.cancel();
    messages.close();
    exits.close();
  }
}

Future<void> _run((SendPort, String, String) start) async {
  final (messages, directory, id) = start;
  var lastSent = -1.0;
  try {
    await DictionaryIndexBuilder.build(
      directory: directory,
      id: id,
      // A message per percent, not per block read.
      onProgress: (fraction) {
        if (fraction - lastSent >= 0.01) {
          lastSent = fraction;
          messages.send(fraction);
        }
      },
    );
    messages.send(null);
  } on DictionaryException catch (error) {
    messages.send(error.reason);
  } on Object catch (error) {
    messages.send('$error');
  }
}
