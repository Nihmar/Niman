/// An imported page's pictures kept [parallelPictureDownloads] at a time
/// (#1293), as a capture downloads its own.
///
/// A stop is looked for before each picture starts and, so that a cancel
/// does not wait for the slowest download, every [_poll] while they run:
/// the pool then gives up at once and closes the store, whose pictures
/// still on their way are dropped when they arrive.
library;

import 'dart:async';

import 'package:niman/src/capture/capture_pictures.dart'
    show parallelPictureDownloads;
import 'package:niman/src/import/html/html_convert_failures.dart';
import 'package:niman/src/import/html/html_picture_source.dart';
import 'package:niman/src/import/html/html_picture_store.dart';

const Duration _poll = Duration(milliseconds: 25);

/// Keeps [sources] in [store]; answers where each one that came went, by
/// its address.
///
/// [step] is awaited before each picture starts and throws to stop (the
/// job's own: it yields and asks the stop flag). [stopped] is the flag,
/// asked while pictures are on their way. [progress] hears a picture
/// started (`done` unchanged, its name) and finished (`done` one more).
/// Throws [HtmlConvertStopped] when stopped.
Future<Map<String, String>> keepPictures(
  HtmlPictureStore store,
  List<PictureSource> sources, {
  required Future<void> Function() step,
  bool Function()? stopped,
  void Function(int done, String what)? progress,
  int parallel = parallelPictureDownloads,
}) async {
  final kept = <String, String>{};
  var next = 0;
  var done = 0;
  Exception? failure;
  final aborted = Completer<void>();
  void abort(Exception error) {
    failure ??= error;
    if (!aborted.isCompleted) aborted.complete();
  }

  Future<void> worker() async {
    while (failure == null && next < sources.length) {
      try {
        await step();
      } on Exception catch (error) {
        abort(error);
        return;
      }
      // The step yielded: another worker may have taken the last one.
      if (failure != null || next >= sources.length) return;
      final source = sources[next++];
      progress?.call(done, source.label);
      final path = await store.keep(source);
      if (failure != null) return;
      if (path != null) kept[source.address] = path;
      progress?.call(++done, source.label);
    }
  }

  final timer = Timer.periodic(_poll, (_) {
    if (stopped?.call() ?? false) abort(const HtmlConvertStopped());
  });
  try {
    await Future.any([
      Future.wait([for (var i = 0; i < parallel; i++) worker()]),
      aborted.future,
    ]);
  } finally {
    timer.cancel();
  }
  final error = failure;
  if (error != null) {
    store.close();
    throw error;
  }
  return kept;
}
