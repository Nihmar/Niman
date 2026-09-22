// Undo and redo for the note the surface is editing (#245, phase 3).
//
// A history of *edits*, not of texts: each entry is a range, what was there,
// and
// what replaced it, which is exactly what an undo needs and what a redo needs
// turned around. Storing whole notes instead would be O(n) per keystroke and
// would
// make the 1M-note rule a lie in the one place a writer notices it.
//
// Two rules the writer feels rather than reads:
//
// * **typing coalesces.** A keystroke per undo entry makes Ctrl+Z useless — no
// one
// wants to un-type a sentence one letter at a time. Consecutive insertions that
// are not separated by a caret move, a deletion or a newline merge into the
// entry
//   they continue.
// * **the stack is bounded.** A note is a file, and a session is long: the
// oldest
//   entries go before the memory does. What is dropped is the *oldest*, so undo
//   reaches far enough back to matter and then stops, as every editor's does.
import 'package:niman/src/markdown/source_buffer.dart';

/// One edit, as an undo needs to see it.
final class EditRecord {
  /// Creates a record of replacing `[start, start + removed.length)` with
  /// [inserted].
  const new({
    required this.start,
    required this.removed,
    required this.inserted,
  });

  /// Where the edit began.
  final int start;

  /// What was there before.
  final String removed;

  /// What is there now.
  final String inserted;

  /// Where the edit ends in the text as it stands.
  int get end => start + inserted.length;

  /// Whether this edit and [next] can be one undo step.
  ///
  /// True when [next] simply continues the typing this record began: it is an
  /// insertion with nothing removed, it starts where this one ended, and
  /// neither
  /// side is a line break (a newline is a decision, and undoing it separately
  /// is
  /// what a writer expects).
  bool continuesWith(EditRecord next) {
    if (removed.isNotEmpty || next.removed.isNotEmpty) return false;
    if (next.start != end) return false;
    if (inserted.contains('\n') || next.inserted.contains('\n')) return false;
    return true;
  }

  /// The record that undoes this one, given the text it produced.
  EditRecord get inverse =>
      EditRecord(start: start, removed: inserted, inserted: removed);

  @override
  String toString() =>
      'EditRecord($start, -${removed.length}, +${inserted.length})';
}

/// The edits that made the note what it is, and the way back.
final class EditHistory {
  /// Creates a history that keeps at most [limit] undo steps.
  new({this.limit = 200});

  /// How many undo steps are kept before the oldest is dropped.
  final int limit;

  final List<EditRecord> _done = <EditRecord>[];
  final List<EditRecord> _undone = <EditRecord>[];

  /// Whether there is anything to undo.
  bool get canUndo => _done.isNotEmpty;

  /// Whether there is anything to redo.
  bool get canRedo => _undone.isNotEmpty;

  /// How many undo steps are held.
  int get length => _done.length;

  /// Whether the next edit starts a step of its own whatever it continues.
  bool _sealed = false;

  /// Ends the current step: the next edit is undone on its own even when it
  /// continues the last one (the caret moved away and came back — typing
  /// there again is a new thought).
  void seal() => _sealed = true;

  /// Records an edit that has already been applied to the buffer.
  ///
  /// [EditRecord.inserted] must be what the buffer *stored*, which is not
  /// always what was typed: a line break is stored as the note's own line
  /// ending. An undo removes `inserted.length` code units, so a record of the
  /// typed text instead deleted one character too many per line break.
  void record(EditRecord record) {
    if (record.removed.isEmpty && record.inserted.isEmpty) return;
    // A new edit is a new branch: whatever was undone is no longer reachable.
    _undone.clear();
    final sealed = _sealed;
    _sealed = false;
    if (!sealed && _done.isNotEmpty && _done.last.continuesWith(record)) {
      final last = _done.removeLast();
      _done.add(
        EditRecord(
          start: last.start,
          removed: last.removed,
          inserted: '${last.inserted}${record.inserted}',
        ),
      );
    } else {
      _done.add(record);
      while (_done.length > limit) {
        _done.removeAt(0);
      }
    }
  }

  /// Undoes the last edit on [buffer], returning what it did, or null when
  /// there
  /// is nothing to undo.
  EditRecord? undo(SourceBuffer buffer) {
    if (_done.isEmpty) return null;
    final last = _done.removeLast();
    buffer.replaceRange(last.start, last.end, last.removed, verbatim: true);
    _undone.add(last);
    _sealed = true;
    return last;
  }

  /// Redoes the last undone edit on [buffer], or null when there is nothing.
  EditRecord? redo(SourceBuffer buffer) {
    if (_undone.isEmpty) return null;
    final next = _undone.removeLast();
    buffer.replaceRange(
      next.start,
      next.start + next.removed.length,
      next.inserted,
      verbatim: true,
    );
    _done.add(next);
    _sealed = true;
    return next;
  }

  /// Forgets everything (a note was reloaded from disk, and its history with
  /// it).
  void clear() {
    _done.clear();
    _undone.clear();
    _sealed = false;
  }
}
