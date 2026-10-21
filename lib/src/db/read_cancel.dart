import 'dart:async';

/// Tells a content read that nobody wants its result any more: a note saved
/// again while its reindex reads it (`NoteWriter`).
///
/// The read stops where it is — the isolate reading the note is killed — and
/// writes nothing to the index; whoever cancelled it owes the note a reindex
/// of its own.
final class ReadCancel {
  final Completer<void> _cancelled = Completer<void>();

  /// Whether [cancel] was called.
  bool get isCancelled => _cancelled.isCompleted;

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled => _cancelled.future;

  /// Stops the read; a second call does nothing.
  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }
}
