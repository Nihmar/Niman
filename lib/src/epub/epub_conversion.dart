/// A book's conversion to notes (#1138), from the main isolate's side: the
/// isolate that writes it (`epub_convert_job.dart`), its progress, and a
/// cancel that leaves the library as it was.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/epub/epub_archive.dart';
import 'package:niman/src/epub/epub_convert_job.dart';
import 'package:niman/src/epub/epub_convert_plan.dart';
import 'package:path/path.dart' as p;

/// A conversion that was stopped before it moved anything in: the library
/// holds nothing of it.
final class EpubConvertCancelled implements Exception {
  /// Stopped.
  const new();
}

/// A conversion that failed for a reason other than the book's own.
final class EpubConvertFailed implements Exception {
  /// Failed with [message], for the log.
  const new(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => 'EpubConvertFailed: $message';
}

/// One conversion running.
final class EpubConversion {
  new _(this._isolate, this._staging, this._events, this._exits);

  /// Starts converting the book [source] into the folder [parent]
  /// (library-relative) of [libraryRoot].
  static Future<EpubConversion> start({
    required String source,
    required String libraryRoot,
    required String parent,
    required bool oneNote,
    required String attachments,
    required EpubConvertWords words,
  }) async {
    final parentAbs = p.joinAll([libraryRoot, ...parent.split('/')]);
    final staging = p.join(
      parentAbs,
      '.epub.niman-tmp-${DateTime.now().microsecondsSinceEpoch}',
    );
    final events = ReceivePort();
    final exits = ReceivePort();
    final request = (
      source: source,
      libraryRoot: libraryRoot,
      parent: parent,
      staging: staging,
      oneNote: oneNote,
      attachments: attachments,
      words: words,
    );
    final isolate = await Isolate.spawn(convertEpubEntry, (
      request,
      events.sendPort,
    ), onExit: exits.sendPort);
    return EpubConversion._(isolate, staging, events, exits).._listen(source);
  }

  final Isolate _isolate;
  final String _staging;
  final ReceivePort _events;
  final ReceivePort _exits;
  final Completer<EpubConverted> _done = Completer<EpubConverted>();
  bool _finishing = false;
  bool _cancelling = false;

  /// How far it has got; null before the first step.
  final ValueNotifier<EpubConvertProgress?> progress = ValueNotifier(null);

  /// Answers what was written, or throws [EpubRefused],
  /// [EpubConvertCancelled] or [EpubConvertFailed].
  Future<EpubConverted> get done => _done.future;

  /// Whether a cancel can still stop it: not once it moves its notes in.
  bool get cancellable => !_finishing && !_cancelling && !_done.isCompleted;

  void _listen(String source) {
    final gauge = IsolateGauge.begin('convert "${p.basename(source)}"');
    _events.listen((message) {
      switch (message) {
        case ('progress', final int done, final int total, final String what):
          progress.value = (done: done, total: total, what: what);
        case ('finishing', final SendPort reply):
          // Answered in turn with a cancel: whichever comes first wins, and
          // there is no moment when both could.
          if (_cancelling) {
            reply.send(false);
          } else {
            _finishing = true;
            reply.send(true);
          }
        case (
          'done',
          final String made,
          final String open,
          final int notes,
          final int pictures,
        ):
          _settle(
            gauge,
            value: (made: made, open: open, notes: notes, pictures: pictures),
          );
        case ('refused', final String reason, final String detail):
          _settle(
            gauge,
            error: EpubRefused(EpubRefusal.values.byName(reason), detail),
          );
        case ('failed', final String error):
          _settle(gauge, error: EpubConvertFailed(error));
      }
    });
    // An isolate gone without its last word died: nothing it wrote stays.
    _exits.listen((_) {
      // A cancel kills it: its exit is the cancel's to answer.
      if (!_done.isCompleted && !_cancelling) {
        unawaited(_discard());
        _settle(gauge, error: const EpubConvertFailed('the isolate died'));
      }
    });
  }

  void _settle(int gauge, {EpubConverted? value, Object? error}) {
    if (_done.isCompleted) return;
    IsolateGauge.finishJob(gauge, error: error);
    _events.close();
    _exits.close();
    if (error != null) {
      _done.completeError(error);
    } else {
      _done.complete(value);
    }
  }

  /// Stops it, when it still can: the isolate killed and what it wrote
  /// deleted. Answers whether it stopped.
  Future<bool> cancel() async {
    if (!cancellable) return false;
    _cancelling = true;
    _isolate.kill(priority: Isolate.immediate);
    await _discard();
    _done.completeError(const EpubConvertCancelled());
    _events.close();
    _exits.close();
    return true;
  }

  Future<void> _discard() async {
    try {
      await Directory(_staging).delete(recursive: true);
    } on FileSystemException {
      // Not made yet, or already gone; the sweep takes what a crash left.
    }
  }
}

/// What the book at [source] would make, read on an isolate.
Future<EpubConvertPreview> previewEpubOnIsolate(
  String source,
  EpubConvertWords words,
) => IsolateGauge.run(
  () => previewEpub(source, words),
  'preview "${p.basename(source)}"',
);
