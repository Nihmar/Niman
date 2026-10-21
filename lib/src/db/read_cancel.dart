import 'dart:async';

/// Tells a content read that nobody wants its result any more: a note saved
/// again while its reindex reads it (`NoteWriter`).
///
/// The read stops where it is and writes nothing to the index; whoever
/// cancelled it owes the note a reindex of its own.
///
/// A read never stops with a file open — a killed isolate runs no `finally`,
/// and an open file on Windows can be neither deleted nor replaced, which
/// is what the save that cancelled the read is about to do to the note. It
/// stops between two files, or when it holds none (it is parsing); [released]
/// says when that is true, for a caller that is about to touch the file.
final class ReadCancel {
  final Completer<void> _cancelled = Completer<void>();
  int _holding = 0;
  Completer<void>? _drained;

  /// Whether [cancel] was called.
  bool get isCancelled => _cancelled.isCompleted;

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled => _cancelled.future;

  /// Stops the read; a second call does nothing.
  ///
  /// The read stops at its next safe point, not at once: wait for
  /// [released] before replacing or deleting the file it reads.
  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }

  /// Completes when no read tied to this cancel holds a file open: at once
  /// when none does, otherwise when the last of them has closed it — after
  /// [cancel], at its next safe point (the end of the file it is reading).
  Future<void> get released {
    if (_holding == 0) return Future<void>.value();
    return (_drained ??= Completer<void>()).future;
  }

  /// A read that may hold a file open registers here; the callback it
  /// returns says it holds none any more (a second call does nothing).
  void Function() holdFiles() {
    _holding++;
    var done = false;
    return () {
      if (done) return;
      done = true;
      if (--_holding == 0) {
        _drained?.complete();
        _drained = null;
      }
    };
  }

  /// A seam for tests: called as a read reaches its parse, when it holds no
  /// file any more and a cancel kills it. A cancel made here lands in that
  /// phase every time, which no timing can promise.
  void Function()? onParsing;
}
