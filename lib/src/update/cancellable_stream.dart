/// Ending a stream from outside (#911).
library;

import 'dart:async';

/// [source]'s events, until [cancel] completes.
///
/// Once [cancel] completes the subscription to [source] is cancelled at
/// once — a stream that has gone quiet is ended too, not only one that
/// delivers another event — and the result ends with [onCancel]'s error.
/// Pausing and resuming the result does the same to [source], so a slow
/// consumer still holds the producer back.
Stream<T> untilCancelled<T>(
  Stream<T> source,
  Future<void> cancel, {
  required Object Function() onCancel,
}) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  var over = false;
  controller = StreamController<T>(
    onListen: () {
      subscription = source.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          over = true;
          unawaited(controller.close());
        },
      );
      unawaited(
        cancel.then((_) async {
          if (over) return;
          over = true;
          await subscription?.cancel();
          controller.addError(onCancel());
          unawaited(controller.close());
        }),
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () {
      over = true;
      return subscription?.cancel();
    },
  );
  return controller.stream;
}
